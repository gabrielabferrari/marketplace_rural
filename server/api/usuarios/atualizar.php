<?php
/**
 * PUT usuarios/atualizar.php
 * Corpo: { "nome": "...", "telefone": "(19) 99999-9999" }
 * E-mail e tipo de conta não podem ser alterados por aqui.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('PUT', 'POST');
$usuario = usuario_autenticado();
$dados = corpo_json();

$nome     = texto($dados, 'nome', 120);
$telefone = texto($dados, 'telefone', 20);

if (mb_strlen($nome) < 3) {
    responder_erro(422, 'Informe o nome completo.');
}
if (!preg_match('/^\(\d{2}\) \d{4,5}-\d{4}$/', $telefone)) {
    responder_erro(422, 'Digite um telefone válido.');
}

db()->prepare('UPDATE usuarios SET nome = ?, telefone = ? WHERE id = ?')
    ->execute([$nome, $telefone, $usuario['id']]);

$usuario['nome'] = $nome;
$usuario['telefone'] = $telefone;
responder(['usuario' => usuario_publico($usuario)]);
