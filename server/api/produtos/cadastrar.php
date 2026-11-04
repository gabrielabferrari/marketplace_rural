<?php
/**
 * POST produtos/cadastrar.php   (somente produtor)
 * Corpo: { nome, descricao, categoria, preco, quantidade, localizacao, disponivel, imagens: [url, ...] }
 * Grava em `anuncios` e `anuncios_fotos`. Retorno: { "produto": produto }
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST');
$usuario = usuario_autenticado();
exigir_tipo($usuario, 'produtor');
$dados = corpo_json();

$nome = texto($dados, 'nome', 200);
if (mb_strlen($nome) < 2) {
    responder_erro(422, 'Informe o nome do produto.');
}
$descricao  = texto($dados, 'descricao', 5000);
$categoria  = categoria_chave((string)($dados['categoria'] ?? ''));
$preco      = decimal_obrigatorio($dados['preco'] ?? null, 'preço');
$quantidade = inteiro_obrigatorio($dados['quantidade'] ?? 0, 'quantidade', 0);
$localizacao = texto($dados, 'localizacao', 255);
$disponivel = (bool)($dados['disponivel'] ?? true);
$imagens    = $dados['imagens'] ?? [];
if (!is_array($imagens) || count($imagens) > 5) {
    responder_erro(422, 'Envie no máximo 5 imagens.');
}
$caminhos = [];
foreach ($imagens as $url) {
    $caminho = caminho_imagem((string)$url);
    if ($caminho === null) {
        responder_erro(422, 'Imagem inválida. Envie a foto novamente.');
    }
    $caminhos[] = $caminho;
}

$pdo = db();
$pdo->beginTransaction();
try {
    $inserir = $pdo->prepare(
        'INSERT INTO anuncios (vendedor_id, titulo, descricao, categoria, preco, quantidade_estoque, localizacao, status)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $inserir->execute([
        (int)$usuario['id'], $nome, $descricao, $categoria, $preco,
        $quantidade, $localizacao !== '' ? $localizacao : null, status_anuncio($disponivel),
    ]);
    $id = (int)$pdo->lastInsertId();

    $foto = $pdo->prepare('INSERT INTO anuncios_fotos (anuncio_id, url_imagem, ordem) VALUES (?, ?, ?)');
    foreach ($caminhos as $indice => $caminho) {
        $foto->execute([$id, $caminho, $indice + 1]);
    }
    $pdo->commit();
} catch (Throwable $erro) {
    $pdo->rollBack();
    throw $erro;
}

$anuncio = anuncio_ou_404($id);
$fotos = fotos_por_anuncio([$id]);
responder(['produto' => produto_publico($anuncio, $fotos[$id] ?? [])], 201);
