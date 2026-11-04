<?php
/**
 * Token de acesso assinado com HMAC-SHA256 (formato semelhante ao JWT).
 *
 * Não exige tabela no banco. O token carrega uma "versão de senha" (pv),
 * derivada do hash atual: ao alterar a senha, todos os tokens antigos
 * deixam de ser aceitos automaticamente.
 */
declare(strict_types=1);

function b64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function b64url_decode(string $data): string|false
{
    return base64_decode(strtr($data, '-_', '+/'), true);
}

function versao_senha(string $senhaHash): string
{
    return substr(hash_hmac('sha256', $senhaHash, config()['token_secret']), 0, 16);
}

function emitir_token(array $usuario): string
{
    $agora = time();
    $header = b64url_encode(json_encode(['alg' => 'HS256', 'typ' => 'JWT']));
    $payload = b64url_encode(json_encode([
        'sub' => (int)$usuario['id'],
        'pv'  => versao_senha($usuario['senha']),
        'iat' => $agora,
        'exp' => $agora + (int)config()['token_ttl'],
    ]));
    $assinatura = b64url_encode(hash_hmac('sha256', "$header.$payload", config()['token_secret'], true));
    return "$header.$payload.$assinatura";
}

function token_da_requisicao(): ?string
{
    $header = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? (function_exists('apache_request_headers') ? (apache_request_headers()['Authorization'] ?? '') : '');
    if (preg_match('/^Bearer\s+(\S+)$/i', (string)$header, $m)) {
        return $m[1];
    }
    return null;
}

/**
 * Valida o token e devolve o usuário do banco. Encerra com 401 se inválido.
 * O tipo de conta vem SEMPRE do banco, nunca do token ou do cliente.
 *
 * @return array<string, mixed>
 */
function usuario_autenticado(): array
{
    $token = token_da_requisicao();
    $partes = $token ? explode('.', $token) : [];
    if (count($partes) !== 3) {
        responder_erro(401, 'Sessão inválida. Entre novamente.');
    }
    [$header, $payload, $assinatura] = $partes;
    $esperada = b64url_encode(hash_hmac('sha256', "$header.$payload", config()['token_secret'], true));
    if (!hash_equals($esperada, $assinatura)) {
        responder_erro(401, 'Sessão inválida. Entre novamente.');
    }
    $dados = json_decode((string)b64url_decode($payload), true);
    if (!is_array($dados) || ($dados['exp'] ?? 0) < time()) {
        responder_erro(401, 'Sua sessão expirou. Entre novamente.');
    }

    $stmt = db()->prepare('SELECT id, nome, email, telefone, senha_hash AS senha, tipo_acesso AS tipo FROM usuarios WHERE id = ? LIMIT 1');
    $stmt->execute([(int)($dados['sub'] ?? 0)]);
    $usuario = $stmt->fetch();
    if (!$usuario || !hash_equals(versao_senha($usuario['senha']), (string)($dados['pv'] ?? ''))) {
        responder_erro(401, 'Sessão inválida. Entre novamente.');
    }
    return $usuario;
}

/** Exige um tipo de conta específico (controle de acesso no servidor). */
function exigir_tipo(array $usuario, string $tipo): void
{
    if ($usuario['tipo'] !== $tipo) {
        responder_erro(403, 'Sua conta não tem permissão para esta ação.');
    }
}
