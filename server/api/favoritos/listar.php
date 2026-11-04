<?php
/**
 * GET favoritos/listar.php
 * Retorna os produtos (anúncios) favoritados pelo usuário do token. Usa a tabela `favoritos`.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('GET');
$usuario = usuario_autenticado();

$stmt = db()->prepare(
    'SELECT a.*, u.nome AS produtor_nome FROM favoritos f
     JOIN anuncios a ON a.id = f.anuncio_id
     JOIN usuarios u ON u.id = a.vendedor_id
     WHERE f.usuario_id = ? AND a.status = ?
     ORDER BY f.data_adicionado DESC'
);
$stmt->execute([(int)$usuario['id'], STATUS_ANUNCIO_VISIVEL]);
$linhas = $stmt->fetchAll();

$fotos = fotos_por_anuncio(array_map(static fn($l) => (int)$l['id'], $linhas));
responder(array_map(
    static fn($l) => produto_publico($l, $fotos[(int)$l['id']] ?? []),
    $linhas
));
