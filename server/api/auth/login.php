<?php
/**
 * POST auth/login.php
 * Corpo:   { "email": "...", "senha": "..." }
 * Retorno: { "sucesso": true, "dados": { "token": "...", "usuario": {...} } }
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST');
$dados = corpo_json();

$email = strtolower(texto($dados, 'email', 150));
$senha = (string)($dados['senha'] ?? '');

if (!filter_var($email, FILTER_VALIDATE_EMAIL) || $senha === '') {
    responder_erro(422, 'Informe e-mail e senha válidos.');
}

$stmt = db()->prepare('SELECT id, nome, email, telefone, senha_hash AS senha, tipo_acesso AS tipo FROM usuarios WHERE email = ? LIMIT 1');
$stmt->execute([$email]);
$usuario = $stmt->fetch();

// Mesma mensagem para e-mail inexistente e senha errada (não revela cadastros).
if (!$usuario || !password_verify($senha, $usuario['senha'])) {
    usleep(300000); // atenua tentativas automatizadas
    responder_erro(401, 'E-mail ou senha incorretos.');
}

if (password_needs_rehash($usuario['senha'], PASSWORD_DEFAULT)) {
    $novo = password_hash($senha, PASSWORD_DEFAULT);
    db()->prepare('UPDATE usuarios SET senha_hash = ? WHERE id = ?')->execute([$novo, $usuario['id']]);
    $usuario['senha'] = $novo;
}

responder([
    'token'   => emitir_token($usuario),
    'usuario' => usuario_publico($usuario),
]);
