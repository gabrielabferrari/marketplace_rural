<?php
/**
 * Leitura de pedidos (`pedidos` + `pedido_itens`) no contrato JSON do app.
 * Incluído pelos endpoints de pedidos/*.php.
 */
declare(strict_types=1);

/**
 * Carrega pedidos com nomes das partes e itens.
 * @param array<int, mixed> $params
 * @return list<array<string, mixed>>
 */
function pedidos_carregar(string $where, array $params): array
{
    $stmt = db()->prepare(
        "SELECT p.*, c.nome AS comprador_nome, v.nome AS produtor_nome
         FROM pedidos p
         JOIN usuarios c ON c.id = p.comprador_id
         JOIN usuarios v ON v.id = p.vendedor_id
         WHERE $where
         ORDER BY p.data_criacao DESC, p.id DESC"
    );
    $stmt->execute($params);
    $pedidos = $stmt->fetchAll();
    if ($pedidos === []) {
        return [];
    }

    $ids = array_map(static fn($p) => (int)$p['id'], $pedidos);
    $marcas = implode(',', array_fill(0, count($ids), '?'));
    $itensStmt = db()->prepare(
        "SELECT * FROM pedido_itens WHERE pedido_id IN ($marcas) ORDER BY pedido_id, id"
    );
    $itensStmt->execute($ids);

    $anuncioIds = [];
    $itensPorPedido = [];
    foreach ($itensStmt->fetchAll() as $item) {
        $itensPorPedido[(int)$item['pedido_id']][] = $item;
        $anuncioIds[] = (int)$item['anuncio_id'];
    }
    $fotos = fotos_por_anuncio(array_values(array_unique($anuncioIds)));

    $resultado = [];
    foreach ($pedidos as $pedido) {
        $id = (int)$pedido['id'];
        $itens = [];
        foreach ($itensPorPedido[$id] ?? [] as $item) {
            $anuncioId = (int)$item['anuncio_id'];
            $itens[] = [
                'produto_id'      => $anuncioId,
                'nome'            => $item['nome_produto'],
                'quantidade'      => (int)$item['quantidade'],
                'preco_unitario'  => (float)$item['preco_unitario'],
                'unidade'         => UNIDADE_PADRAO,
                'imagem'          => $fotos[$anuncioId][0] ?? null,
            ];
        }
        $resultado[] = pedido_publico($pedido, $itens);
    }
    return $resultado;
}

/** @param list<array<string, mixed>> $itens */
function pedido_publico(array $pedido, array $itens): array
{
    $status = (string)$pedido['status'];
    return [
        'id'              => (int)$pedido['id'],
        'status'          => STATUS_PEDIDO_BANCO_PARA_APP[$status] ?? 'recebido',
        'comprador_id'    => (int)$pedido['comprador_id'],
        'comprador_nome'  => $pedido['comprador_nome'],
        'produtor_id'     => (int)$pedido['vendedor_id'],
        'produtor_nome'   => $pedido['produtor_nome'],
        'itens'           => $itens,
        'total'           => (float)$pedido['total'],
        'taxa_entrega'    => null,
        'endereco_entrega' => null,
        'criado_em'       => $pedido['data_criacao'],
        // O banco não guarda histórico de etapas; o app usa criado_em para "Recebido".
        'historico'       => [],
    ];
}

/** Carrega um pedido se o usuário for comprador ou produtor dele, senão 404. */
function pedido_do_usuario_ou_404(int $id, array $usuario): array
{
    $coluna = $usuario['tipo'] === 'produtor' ? 'p.vendedor_id' : 'p.comprador_id';
    $linhas = pedidos_carregar("p.id = ? AND $coluna = ?", [$id, (int)$usuario['id']]);
    if ($linhas === []) {
        responder_erro(404, 'Pedido não encontrado.');
    }
    return $linhas[0];
}
