<?php
/**
 * POST produtos/estoque.php   (somente o produtor dono)
 * Corpo: { "id": 1, "quantidade": 20, "motivo": "opcional" }
 * "quantidade" é o NOVO saldo do estoque, gravado em anuncios.quantidade_estoque.
 * O banco não tem tabela de histórico de estoque, então "motivo" não é armazenado.
 * Retorno: { "produto": produto }
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST');
$usuario = usuario_autenticado();
exigir_tipo($usuario, 'produtor');
$dados = corpo_json();

$id = inteiro_obrigatorio($dados['id'] ?? null, 'id', 1);
$quantidade = inteiro_obrigatorio($dados['quantidade'] ?? null, 'quantidade', 0);

$anuncio = anuncio_ou_404($id);
if ((int)$anuncio['vendedor_id'] !== (int)$usuario['id']) {
    responder_erro(403, 'Você só pode alterar o estoque dos seus produtos.');
}

db()->prepare('UPDATE anuncios SET quantidade_estoque = ? WHERE id = ?')->execute([$quantidade, $id]);

$anuncio = anuncio_ou_404($id);
$fotos = fotos_por_anuncio([$id]);
responder(['produto' => produto_publico($anuncio, $fotos[$id] ?? [])]);
