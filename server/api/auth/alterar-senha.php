<?php
/**
 * POST auth/alterar-senha.php
 * Corpo: { "senhaAtual": "...", "novaSenha": "..." }
 * Após a troca, tokens emitidos anteriormente deixam de valer.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST');
$usuario = usuario_autenticado();
$dados = corpo_json();

$atual = (string)($dados['senhaAtual'] ?? '');
$nova  = (string)($dados['novaSenha'] ?? '');

if (!password_verify($atual, $usuario['senha'])) {
    responder_erro(422, 'A senha atual está incorreta.');
}
if (strlen($nova) < 6) {
    responder_erro(422, 'A nova senha precisa ter pelo menos 6 caracteres.');
}
if ($nova === $atual) {
    responder_erro(422, 'A nova senha deve ser diferente da atual.');
}

$hash = password_hash($nova, PASSWORD_DEFAULT);
db()->prepare('UPDATE usuarios SET senha_hash = ? WHERE id = ?')->execute([$hash, $usuario['id']]);

$usuario['senha'] = $hash;
// Novo token para manter o usuário conectado neste dispositivo.
responder(['token' => emitir_token($usuario)]);
