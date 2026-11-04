<?php
/**
 * GET fazenda/detalhe.php   (somente produtor)
 * Lê a tabela `fazendas` do produtor. Sem cadastro → 404 com JSON (o app trata como "ainda não cadastrada").
 * Campos que o banco não tem (cidade, estado, culturas, área de produção, descrição) saem nulos/vazios.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('GET');
$usuario = usuario_autenticado();
exigir_tipo($usuario, 'produtor');

$stmt = db()->prepare('SELECT * FROM fazendas WHERE usuario_id = ? ORDER BY id LIMIT 1');
$stmt->execute([(int)$usuario['id']]);
$fazenda = $stmt->fetch();
if (!$fazenda) {
    responder_erro(404, 'Propriedade ainda não cadastrada.');
}

responder(fazenda_publica($fazenda));
