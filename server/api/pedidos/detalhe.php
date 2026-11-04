<?php
/**
 * GET pedidos/detalhe.php?id=   (somente comprador ou produtor do pedido)
 * Retorno: { "sucesso": true, "dados": pedido }
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';
require_once __DIR__ . '/../lib/pedidos.php';

exigir_metodo('GET');
$usuario = usuario_autenticado();

$id = inteiro_obrigatorio($_GET['id'] ?? null, 'id', 1);
responder(pedido_do_usuario_ou_404($id, $usuario));
