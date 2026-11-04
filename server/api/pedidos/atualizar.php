<?php
/**
 * POST pedidos/atualizar.php
 * Corpo: { "id": 1, "status": "em_preparacao" | "concluido" | "cancelado" }
 *
 * Transições (mesmas regras que o app aplica em OrderRules):
 *   produtor:  recebido → em_preparacao | cancelado;  em_preparacao → concluido | cancelado
 *   comprador: recebido → cancelado
 * Ao cancelar, o estoque dos itens é devolvido a anuncios.quantidade_estoque.
 * "a_caminho" não existe no banco e é recusado.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';
require_once __DIR__ . '/../lib/pedidos.php';

exigir_metodo('POST', 'PUT');
$usuario = usuario_autenticado();
$dados = corpo_json();

$id = inteiro_obrigatorio($dados['id'] ?? null, 'id', 1);
$statusDestino = STATUS_PEDIDO_APP_PARA_BANCO[(string)($dados['status'] ?? '')] ?? null;
if ($statusDestino === null) {
    responder_erro(422, 'Status de pedido não suportado pelo servidor.');
}

$pdo = db();
$pdo->beginTransaction();
try {
    $coluna = $usuario['tipo'] === 'produtor' ? 'vendedor_id' : 'comprador_id';
    $bloquear = $pdo->prepare("SELECT id, status FROM pedidos WHERE id = ? AND $coluna = ? FOR UPDATE");
    $bloquear->execute([$id, (int)$usuario['id']]);
    $atual = $bloquear->fetch();
    if (!$atual) {
        throw new DomainException('Pedido não encontrado.', 404);
    }

    $permitidos = TRANSICOES_PEDIDO[$usuario['tipo']][$atual['status']] ?? [];
    if (!in_array($statusDestino, $permitidos, true)) {
        throw new DomainException('Esta alteração de status não é permitida para sua conta.', 422);
    }

    if ($statusDestino === 'cancelado') {
        $itens = $pdo->prepare('SELECT anuncio_id, quantidade FROM pedido_itens WHERE pedido_id = ?');
        $itens->execute([$id]);
        $devolver = $pdo->prepare('UPDATE anuncios SET quantidade_estoque = quantidade_estoque + ? WHERE id = ?');
        foreach ($itens->fetchAll() as $item) {
            $devolver->execute([(int)$item['quantidade'], (int)$item['anuncio_id']]);
        }
    }

    $pdo->prepare('UPDATE pedidos SET status = ? WHERE id = ?')->execute([$statusDestino, $id]);
    $pdo->commit();
} catch (DomainException $erro) {
    $pdo->rollBack();
    responder_erro($erro->getCode() ?: 422, $erro->getMessage());
} catch (Throwable $erro) {
    $pdo->rollBack();
    throw $erro;
}

responder(pedido_do_usuario_ou_404($id, $usuario));
