<?php
/**
 * POST pedidos/criar.php   (somente comprador)
 * Corpo: { "itens": [ { "produto_id": 1, "quantidade": 2 } ], "negociacao_id": opcional }
 *
 * Em uma única transação: bloqueia os anúncios, valida estoque e status, grava
 * `pedidos` + `pedido_itens` e baixa `anuncios.quantidade_estoque`.
 * Como `pedidos` tem um único vendedor, itens de produtores diferentes geram
 * um pedido por produtor.
 *
 * Retorno: { "pedido": primeiro pedido criado, "pedidos": [todos os pedidos criados] }
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';
require_once __DIR__ . '/../lib/pedidos.php';

exigir_metodo('POST');
$usuario = usuario_autenticado();
exigir_tipo($usuario, 'comprador');
$dados = corpo_json();

$itens = $dados['itens'] ?? null;
if (!is_array($itens) || $itens === [] || count($itens) > 50) {
    responder_erro(422, 'Informe ao menos um item no pedido.');
}

// Agrupa quantidades por anúncio (um mesmo produto pode aparecer mais de uma vez).
$pedido = [];
foreach ($itens as $item) {
    $produtoId = inteiro_obrigatorio($item['produto_id'] ?? null, 'produto', 1);
    $quantidade = inteiro_obrigatorio($item['quantidade'] ?? null, 'quantidade', 1);
    $pedido[$produtoId] = ($pedido[$produtoId] ?? 0) + $quantidade;
}

$pdo = db();
$pdo->beginTransaction();
try {
    $porVendedor = [];
    $bloquear = $pdo->prepare(
        'SELECT a.id, a.vendedor_id, a.titulo, a.preco, a.quantidade_estoque, a.status
         FROM anuncios a WHERE a.id = ? FOR UPDATE'
    );
    foreach ($pedido as $produtoId => $quantidade) {
        $bloquear->execute([$produtoId]);
        $anuncio = $bloquear->fetch();
        if (!$anuncio || $anuncio['status'] !== STATUS_ANUNCIO_VISIVEL) {
            throw new DomainException('Um dos produtos não está mais disponível.');
        }
        if ((int)$anuncio['vendedor_id'] === (int)$usuario['id']) {
            throw new DomainException('Você não pode comprar o próprio produto.');
        }
        if ((int)$anuncio['quantidade_estoque'] < $quantidade) {
            throw new DomainException("Estoque insuficiente para \"{$anuncio['titulo']}\".");
        }
        $porVendedor[(int)$anuncio['vendedor_id']][] = [
            'anuncio' => $anuncio,
            'quantidade' => $quantidade,
        ];
    }

    $criarPedido = $pdo->prepare(
        "INSERT INTO pedidos (comprador_id, vendedor_id, status, total) VALUES (?, ?, 'recebido', ?)"
    );
    $criarItem = $pdo->prepare(
        'INSERT INTO pedido_itens (pedido_id, anuncio_id, nome_produto, quantidade, preco_unitario)
         VALUES (?, ?, ?, ?, ?)'
    );
    $baixarEstoque = $pdo->prepare(
        'UPDATE anuncios SET quantidade_estoque = quantidade_estoque - ? WHERE id = ?'
    );

    $idsCriados = [];
    foreach ($porVendedor as $vendedorId => $linhas) {
        $total = 0.0;
        foreach ($linhas as $linha) {
            $total += $linha['quantidade'] * (float)$linha['anuncio']['preco'];
        }
        $criarPedido->execute([(int)$usuario['id'], $vendedorId, round($total, 2)]);
        $pedidoId = (int)$pdo->lastInsertId();
        $idsCriados[] = $pedidoId;

        foreach ($linhas as $linha) {
            $anuncio = $linha['anuncio'];
            $criarItem->execute([
                $pedidoId, (int)$anuncio['id'], $anuncio['titulo'], $linha['quantidade'], (float)$anuncio['preco'],
            ]);
            $baixarEstoque->execute([$linha['quantidade'], (int)$anuncio['id']]);
        }
    }
    $pdo->commit();
} catch (DomainException $erro) {
    $pdo->rollBack();
    responder_erro(422, $erro->getMessage());
} catch (Throwable $erro) {
    $pdo->rollBack();
    throw $erro;
}

$criados = [];
foreach ($idsCriados as $pedidoId) {
    $criados[] = pedidos_carregar('p.id = ?', [$pedidoId])[0];
}
responder(['pedido' => $criados[0], 'pedidos' => $criados], 201);
