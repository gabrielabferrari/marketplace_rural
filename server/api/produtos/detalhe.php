<?php
/**
 * GET produtos/detalhe.php?id=
 * Retorno: { "sucesso": true, "dados": produto }
 * Anúncios que não estão ativos só aparecem para o próprio produtor.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('GET');
$usuario = usuario_autenticado();

$id = inteiro_obrigatorio($_GET['id'] ?? null, 'id', 1);
$anuncio = anuncio_ou_404($id);

$dono = (int)$anuncio['vendedor_id'] === (int)$usuario['id'];
if (!$dono && $anuncio['status'] !== STATUS_ANUNCIO_VISIVEL) {
    responder_erro(404, 'Produto não encontrado.');
}

$fotos = fotos_por_anuncio([$id]);
responder(produto_publico($anuncio, $fotos[$id] ?? []));
