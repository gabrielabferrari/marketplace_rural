<?php
/**
 * PUT produtos/editar.php   (somente o produtor dono do anúncio)
 * Corpo: produto com "id". Campos ausentes são mantidos.
 * Se "imagens" for enviado, substitui todas as fotos do anúncio.
 * Retorno: { "produto": produto }
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('PUT', 'POST');
$usuario = usuario_autenticado();
exigir_tipo($usuario, 'produtor');
$dados = corpo_json();

$id = inteiro_obrigatorio($dados['id'] ?? null, 'id', 1);
$atual = anuncio_ou_404($id);
if ((int)$atual['vendedor_id'] !== (int)$usuario['id']) {
    responder_erro(403, 'Você só pode editar os seus produtos.');
}

$titulo = array_key_exists('nome', $dados) ? texto($dados, 'nome', 200) : $atual['titulo'];
if (mb_strlen($titulo) < 2) {
    responder_erro(422, 'Informe o nome do produto.');
}
$descricao   = array_key_exists('descricao', $dados) ? texto($dados, 'descricao', 5000) : (string)$atual['descricao'];
$categoria   = array_key_exists('categoria', $dados) ? categoria_chave((string)$dados['categoria']) : $atual['categoria'];
$preco       = array_key_exists('preco', $dados) ? decimal_obrigatorio($dados['preco'], 'preço') : (float)$atual['preco'];
$quantidade  = array_key_exists('quantidade', $dados) ? inteiro_obrigatorio($dados['quantidade'], 'quantidade', 0) : (int)$atual['quantidade_estoque'];
$localizacao = array_key_exists('localizacao', $dados) ? texto($dados, 'localizacao', 255) : (string)$atual['localizacao'];
$status      = array_key_exists('disponivel', $dados)
    ? status_anuncio((bool)$dados['disponivel'])
    : $atual['status'];

$caminhos = null;
if (array_key_exists('imagens', $dados)) {
    if (!is_array($dados['imagens']) || count($dados['imagens']) > 5) {
        responder_erro(422, 'Envie no máximo 5 imagens.');
    }
    $caminhos = [];
    foreach ($dados['imagens'] as $url) {
        $caminho = caminho_imagem((string)$url);
        if ($caminho === null) {
            responder_erro(422, 'Imagem inválida. Envie a foto novamente.');
        }
        $caminhos[] = $caminho;
    }
}

$pdo = db();
$pdo->beginTransaction();
try {
    $pdo->prepare(
        'UPDATE anuncios SET titulo = ?, descricao = ?, categoria = ?, preco = ?,
                quantidade_estoque = ?, localizacao = ?, status = ? WHERE id = ?'
    )->execute([
        $titulo, $descricao, $categoria, $preco, $quantidade,
        $localizacao !== '' ? $localizacao : null, $status, $id,
    ]);

    if ($caminhos !== null) {
        $pdo->prepare('DELETE FROM anuncios_fotos WHERE anuncio_id = ?')->execute([$id]);
        $foto = $pdo->prepare('INSERT INTO anuncios_fotos (anuncio_id, url_imagem, ordem) VALUES (?, ?, ?)');
        foreach ($caminhos as $indice => $caminho) {
            $foto->execute([$id, $caminho, $indice + 1]);
        }
    }
    $pdo->commit();
} catch (Throwable $erro) {
    $pdo->rollBack();
    throw $erro;
}

$anuncio = anuncio_ou_404($id);
$fotos = fotos_por_anuncio([$id]);
responder(['produto' => produto_publico($anuncio, $fotos[$id] ?? [])]);
