<?php
/**
 * GET pedidos/listar.php?status=
 * Comprador vê os pedidos que fez; produtor vê os que recebeu.
 * Filtro de status usa os nomes do app (recebido, em_preparacao, concluido, cancelado).
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';
require_once __DIR__ . '/../lib/pedidos.php';

exigir_metodo('GET');
$usuario = usuario_autenticado();

$coluna = $usuario['tipo'] === 'produtor' ? 'p.vendedor_id' : 'p.comprador_id';
$where = "$coluna = ?";
$params = [(int)$usuario['id']];

$statusApp = (string)($_GET['status'] ?? '');
if ($statusApp !== '') {
    if (!isset(STATUS_PEDIDO_APP_PARA_BANCO[$statusApp])) {
        // Ex.: "a_caminho" não existe no banco: nenhum pedido corresponde.
        responder([]);
    }
    $where .= ' AND p.status = ?';
    $params[] = STATUS_PEDIDO_APP_PARA_BANCO[$statusApp];
}

responder(pedidos_carregar($where, $params));
