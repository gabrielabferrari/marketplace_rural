<?php
/**
 * GET produtos/listar.php
 * Parâmetros: busca, categoria, cidade (localização), meus=1, disponiveis=1,
 *             ordem=recentes|menorPreco|maiorPreco|nome, limite
 * Retorno:    { "sucesso": true, "dados": [ produto, ... ] }
 *
 * Compradores e visitantes veem somente anúncios "ativo" de qualquer produtor.
 * Com meus=1 (somente produtor), vê todos os próprios anúncios, de qualquer status.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('GET');
$usuario = usuario_autenticado();

$condicoes = [];
$params = [];

if (($_GET['meus'] ?? '') === '1') {
    exigir_tipo($usuario, 'produtor');
    $condicoes[] = 'a.vendedor_id = ?';
    $params[] = (int)$usuario['id'];
} else {
    $condicoes[] = 'a.status = ?';
    $params[] = STATUS_ANUNCIO_VISIVEL;
}

$busca = texto($_GET, 'busca', 100);
if ($busca !== '') {
    $condicoes[] = '(a.titulo LIKE ? OR a.descricao LIKE ?)';
    $params[] = "%$busca%";
    $params[] = "%$busca%";
}

$categoria = texto($_GET, 'categoria', 60);
if ($categoria !== '') {
    $condicoes[] = 'a.categoria = ?';
    $params[] = categoria_chave($categoria);
}

$cidade = texto($_GET, 'cidade', 100);
if ($cidade !== '') {
    $condicoes[] = 'a.localizacao LIKE ?';
    $params[] = "%$cidade%";
}

if (($_GET['disponiveis'] ?? '') === '1') {
    $condicoes[] = 'a.quantidade_estoque > 0';
}

$ordens = [
    'recentes'   => 'a.data_criacao DESC, a.id DESC',
    'menorPreco' => 'a.preco ASC, a.id DESC',
    'maiorPreco' => 'a.preco DESC, a.id DESC',
    'nome'       => 'a.titulo ASC, a.id DESC',
];
$ordem = $ordens[$_GET['ordem'] ?? 'recentes'] ?? $ordens['recentes'];

$limite = isset($_GET['limite']) && ctype_digit((string)$_GET['limite'])
    ? min(100, max(1, (int)$_GET['limite']))
    : 100;

$sql = 'SELECT a.*, u.nome AS produtor_nome FROM anuncios a
        JOIN usuarios u ON u.id = a.vendedor_id
        WHERE ' . implode(' AND ', $condicoes) . " ORDER BY $ordem LIMIT $limite";
$stmt = db()->prepare($sql);
$stmt->execute($params);
$linhas = $stmt->fetchAll();

$fotos = fotos_por_anuncio(array_map(static fn($l) => (int)$l['id'], $linhas));
$produtos = array_map(
    static fn($l) => produto_publico($l, $fotos[(int)$l['id']] ?? []),
    $linhas
);

responder($produtos);
