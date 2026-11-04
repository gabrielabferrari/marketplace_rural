<?php
/**
 * POST favoritos/remover.php
 * Corpo: { "produto_id": 1 }
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST', 'DELETE');
$usuario = usuario_autenticado();
$dados = corpo_json();

$produtoId = inteiro_obrigatorio($dados['produto_id'] ?? $_GET['produto_id'] ?? null, 'produto', 1);
db()->prepare('DELETE FROM favoritos WHERE usuario_id = ? AND anuncio_id = ?')
    ->execute([(int)$usuario['id'], $produtoId]);
responder(null);
