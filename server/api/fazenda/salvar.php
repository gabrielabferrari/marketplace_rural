<?php
/**
 * POST fazenda/salvar.php   (somente produtor)
 * Corpo: { nome, endereco, area_total_ha, inscricao_estadual }
 * Mapeamento: endereco → fazendas.localizacao; area_total_ha → area_total;
 * inscricao_estadual → cadastro_estadual. Cria ou atualiza a fazenda do produtor.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST', 'PUT');
$usuario = usuario_autenticado();
exigir_tipo($usuario, 'produtor');
$dados = corpo_json();

$nome = texto($dados, 'nome', 150);
if (mb_strlen($nome) < 2) {
    responder_erro(422, 'Informe o nome da propriedade.');
}
$localizacao = texto($dados, 'endereco', 255);
$area = decimal_obrigatorio($dados['area_total_ha'] ?? null, 'área total', true);
$inscricao = texto($dados, 'inscricao_estadual', 50);

$pdo = db();
$stmt = $pdo->prepare('SELECT id FROM fazendas WHERE usuario_id = ? ORDER BY id LIMIT 1');
$stmt->execute([(int)$usuario['id']]);
$existente = $stmt->fetch();

if ($existente) {
    $pdo->prepare('UPDATE fazendas SET nome = ?, localizacao = ?, area_total = ?, cadastro_estadual = ? WHERE id = ?')
        ->execute([$nome, $localizacao ?: null, $area, $inscricao ?: null, (int)$existente['id']]);
    $id = (int)$existente['id'];
} else {
    $pdo->prepare('INSERT INTO fazendas (usuario_id, nome, localizacao, area_total, cadastro_estadual) VALUES (?, ?, ?, ?, ?)')
        ->execute([(int)$usuario['id'], $nome, $localizacao ?: null, $area, $inscricao ?: null]);
    $id = (int)$pdo->lastInsertId();
}

$stmt = $pdo->prepare('SELECT * FROM fazendas WHERE id = ?');
$stmt->execute([$id]);
responder(['fazenda' => fazenda_publica($stmt->fetch())]);
