<?php
declare(strict_types=1);

/** Resposta de sucesso no formato { "sucesso": true, "dados": ... }. */
function responder($dados = null, int $status = 200): never
{
    http_response_code($status);
    echo json_encode(['sucesso' => true, 'dados' => $dados], JSON_UNESCAPED_UNICODE);
    exit;
}

/** Resposta de erro no formato { "sucesso": false, "mensagem": "..." }. */
function responder_erro(int $status, string $mensagem): never
{
    http_response_code($status);
    echo json_encode(['sucesso' => false, 'mensagem' => $mensagem], JSON_UNESCAPED_UNICODE);
    exit;
}
