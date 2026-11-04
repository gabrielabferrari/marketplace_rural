<?php
/**
 * DELETE produtos/excluir.php?id=   (somente o produtor dono)
 * Produtos já vendidos (com itens em pedidos) não podem ser excluídos:
 * o servidor responde 409 e o produtor deve pausar o anúncio.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('DELETE', 'POST');
$usuario = usuario_autenticado();
exigir_tipo($usuario, 'produtor');

$id = inteiro_obrigatorio($_GET['id'] ?? null, 'id', 1);
$anuncio = anuncio_ou_404($id);
if ((int)$anuncio['vendedor_id'] !== (int)$usuario['id']) {
    responder_erro(403, 'Você só pode excluir os seus produtos.');
}

try {
    db()->prepare('DELETE FROM anuncios WHERE id = ?')->execute([$id]);
} catch (PDOException $erro) {
    if ($erro->getCode() === '23000') {
        responder_erro(409, 'Este produto já está em pedidos ou negociações. Pause o anúncio em vez de excluí-lo.');
    }
    throw $erro;
}
responder(null);
