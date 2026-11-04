<?php
/**
 * POST auth/cadastro.php
 * Corpo: { nome, email, telefone, senha, confirmarSenha, tipo: "produtor"|"comprador" }
 * Usa somente as colunas confirmadas da tabela `usuarios`.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST');
$dados = corpo_json();

$nome      = texto($dados, 'nome', 120);
$email     = strtolower(texto($dados, 'email', 150));
$telefone  = texto($dados, 'telefone', 20);
$senha     = (string)($dados['senha'] ?? '');
$confirmar = (string)($dados['confirmarSenha'] ?? '');
$tipo      = strtolower(texto($dados, 'tipo', 20));

if ($nome === '' || $email === '' || $telefone === '' || $senha === '' || $tipo === '') {
    responder_erro(422, 'Preencha todos os campos.');
}
if (mb_strlen($nome) < 3) {
    responder_erro(422, 'Informe o nome completo.');
}
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    responder_erro(422, 'Digite um e-mail válido.');
}
if (!preg_match('/^\(\d{2}\) \d{4,5}-\d{4}$/', $telefone)) {
    responder_erro(422, 'Digite um telefone válido.');
}
if (strlen($senha) < 6) {
    responder_erro(422, 'A senha precisa ter pelo menos 6 caracteres.');
}
if ($senha !== $confirmar) {
    responder_erro(422, 'As senhas não são iguais.');
}
if (!in_array($tipo, ['produtor', 'comprador'], true)) {
    responder_erro(422, 'Tipo de conta inválido.');
}

$existe = db()->prepare('SELECT id FROM usuarios WHERE email = ? LIMIT 1');
$existe->execute([$email]);
if ($existe->fetch()) {
    responder_erro(409, 'Este e-mail já está cadastrado.');
}

$hash = password_hash($senha, PASSWORD_DEFAULT);
$inserir = db()->prepare('INSERT INTO usuarios (nome, email, telefone, senha_hash, tipo_acesso) VALUES (?, ?, ?, ?, ?)');
$inserir->execute([$nome, $email, $telefone, $hash, $tipo]);

$usuario = [
    'id'       => (int)db()->lastInsertId(),
    'nome'     => $nome,
    'email'    => $email,
    'telefone' => $telefone,
    'senha'    => $hash,
    'tipo'     => $tipo,
];

responder([
    'token'   => emitir_token($usuario),
    'usuario' => usuario_publico($usuario),
], 201);
