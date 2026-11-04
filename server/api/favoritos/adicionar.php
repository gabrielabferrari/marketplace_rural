<?php
/**
 * POST favoritos/adicionar.php
 * Corpo: { "produto_id": 1 }. Idempotente: favoritar de novo não duplica.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST');
$usuario = usuario_autenticado();
$dados = corpo_json();

$produtoId = inteiro_obrigatorio($dados['produto_id'] ?? null, 'produto', 1);
$anuncio = anuncio_ou_404($produtoId);
if ($anuncio['status'] !== STATUS_ANUNCIO_VISIVEL) {
    responder_erro(404, 'Produto não encontrado.');
}

db()->prepare('INSERT IGNORE INTO favoritos (usuario_id, anuncio_id) VALUES (?, ?)')
    ->execute([(int)$usuario['id'], $produtoId]);
responder(null, 201);
