<?php
/**
 * POST produtos/imagem.php   (somente produtor; multipart/form-data, campo "imagem")
 * Aceita JPG, PNG ou WEBP de até 5 MB. Grava em uploads_dir com nome aleatório.
 * Retorno: { "url": "https://.../uploads/produtos/<arquivo>" }
 * A URL deve ser enviada de volta em "imagens" ao cadastrar/editar o produto.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST');
$usuario = usuario_autenticado();
exigir_tipo($usuario, 'produtor');

$arquivo = $_FILES['imagem'] ?? null;
if (!is_array($arquivo) || ($arquivo['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    responder_erro(422, 'Não foi possível receber a imagem. Tente outra foto.');
}
if (($arquivo['size'] ?? 0) > 5 * 1024 * 1024) {
    responder_erro(422, 'A imagem deve ter no máximo 5 MB.');
}

$tipos = [
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/webp' => 'webp',
];
$mime = (new finfo(FILEINFO_MIME_TYPE))->file($arquivo['tmp_name']);
if (!isset($tipos[$mime]) || !is_uploaded_file($arquivo['tmp_name'])) {
    responder_erro(422, 'Envie uma imagem JPG, PNG ou WEBP.');
}

$pasta = rtrim((string)config()['uploads_dir'], '/\\');
if (!is_dir($pasta) && !mkdir($pasta, 0755, true) && !is_dir($pasta)) {
    error_log('[API] não foi possível criar ' . $pasta);
    responder_erro(500, 'Não foi possível salvar a imagem. Tente novamente mais tarde.');
}

$nome = bin2hex(random_bytes(16)) . '.' . $tipos[$mime];
if (!move_uploaded_file($arquivo['tmp_name'], $pasta . DIRECTORY_SEPARATOR . $nome)) {
    error_log('[API] falha ao gravar imagem em ' . $pasta);
    responder_erro(500, 'Não foi possível salvar a imagem. Tente novamente mais tarde.');
}

responder(['url' => url_publica('uploads/produtos/' . $nome)], 201);
