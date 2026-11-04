<?php
/**
 * Funções compartilhadas pelos endpoints de produtos, pedidos, favoritos e fazenda.
 *
 * Mapeiam o esquema REAL do banco `buzzcode_marketplace_rural` (tabelas
 * `anuncios`, `anuncios_fotos`, `pedidos`, `pedido_itens`, `favoritos`, `fazendas`)
 * para o contrato JSON documentado em docs/API.md, que o app Flutter consome.
 *
 * Campos que o banco NÃO possui (unidade de venda, estoque mínimo, cidade/estado
 * da fazenda, histórico de pedidos etc.) são devolvidos como valor padrão ou
 * nulos. Nenhuma coluna é criada aqui.
 */
declare(strict_types=1);

/** Categorias aceitas (mesmos nomes usados no banco e no app). */
const CATEGORIAS_PRODUTO = ['graos', 'hortalicas', 'frutas', 'carnes', 'laticinios', 'bebidas', 'organicos', 'outros'];

/** Valores de `anuncios.status` que tornam o anúncio visível a compradores. */
const STATUS_ANUNCIO_VISIVEL = 'ativo';

/** Unidade padrão: o banco não guarda unidade de venda. */
const UNIDADE_PADRAO = 'un.';

function sem_acento(string $texto): string
{
    return strtr(mb_strtolower(trim($texto), 'UTF-8'), [
        'á' => 'a', 'à' => 'a', 'â' => 'a', 'ã' => 'a', 'ä' => 'a',
        'é' => 'e', 'è' => 'e', 'ê' => 'e', 'ë' => 'e',
        'í' => 'i', 'ì' => 'i', 'î' => 'i', 'ï' => 'i',
        'ó' => 'o', 'ò' => 'o', 'ô' => 'o', 'õ' => 'o', 'ö' => 'o',
        'ú' => 'u', 'ù' => 'u', 'û' => 'u', 'ü' => 'u',
        'ç' => 'c', 'ñ' => 'n',
    ]);
}

/** Converte rótulo ("Grãos") ou chave ("graos") para a chave do banco. Desconhecido → "outros". */
function categoria_chave(?string $valor): string
{
    $chave = str_replace(' ', '', sem_acento((string)$valor));
    return in_array($chave, CATEGORIAS_PRODUTO, true) ? $chave : 'outros';
}

/** URL pública de uma imagem armazenada como caminho relativo (ex.: uploads/produtos/x.jpg). */
function url_publica(string $caminho): string
{
    if (preg_match('#^https?://#i', $caminho)) {
        return $caminho;
    }
    return rtrim((string)config()['public_base_url'], '/') . '/' . ltrim($caminho, '/');
}

/** Converte uma URL devolvida pelo upload de volta para o caminho relativo guardado no banco. */
function caminho_imagem(string $url): ?string
{
    $base = rtrim((string)config()['public_base_url'], '/') . '/';
    if (str_starts_with($url, $base)) {
        $url = substr($url, strlen($base));
    }
    $url = ltrim($url, '/');
    // Só aceita arquivos enviados pelo endpoint de imagem.
    if (!preg_match('#^uploads/produtos/[a-f0-9]{32}\.(jpg|png|webp)$#', $url)) {
        return null;
    }
    return $url;
}

/** Busca as fotos de vários anúncios de uma vez. @return array<int, list<string>> */
function fotos_por_anuncio(array $anuncioIds): array
{
    $mapa = [];
    if ($anuncioIds === []) {
        return $mapa;
    }
    $marcas = implode(',', array_fill(0, count($anuncioIds), '?'));
    $stmt = db()->prepare("SELECT anuncio_id, url_imagem FROM anuncios_fotos WHERE anuncio_id IN ($marcas) ORDER BY anuncio_id, ordem, id");
    $stmt->execute(array_values($anuncioIds));
    foreach ($stmt->fetchAll() as $linha) {
        $mapa[(int)$linha['anuncio_id']][] = url_publica((string)$linha['url_imagem']);
    }
    return $mapa;
}

/**
 * Formata uma linha de `anuncios` (com `produtor_nome`) no contrato de produto.
 * @param array<string, mixed> $linha
 * @param list<string> $imagens
 * @return array<string, mixed>
 */
function produto_publico(array $linha, array $imagens = []): array
{
    return [
        'id'              => (int)$linha['id'],
        'produtor_id'     => (int)$linha['vendedor_id'],
        'produtor_nome'   => $linha['produtor_nome'] ?? null,
        'nome'            => $linha['titulo'],
        'descricao'       => $linha['descricao'] ?? '',
        'categoria'       => categoria_chave($linha['categoria'] ?? ''),
        'preco'           => (float)$linha['preco'],
        'unidade'         => UNIDADE_PADRAO,
        'quantidade'      => (int)$linha['quantidade_estoque'],
        'localizacao'     => $linha['localizacao'] ?? null,
        'disponivel'      => ($linha['status'] ?? '') === STATUS_ANUNCIO_VISIVEL,
        'imagens'         => $imagens,
        'estoque_minimo'  => null,
        'criado_em'       => $linha['data_criacao'] ?? null,
        'atualizado_em'   => $linha['data_atualizacao'] ?? null,
    ];
}

/** Carrega um anúncio com o nome do produtor, ou encerra com 404. @return array<string, mixed> */
function anuncio_ou_404(int $id): array
{
    $stmt = db()->prepare(
        'SELECT a.*, u.nome AS produtor_nome FROM anuncios a
         JOIN usuarios u ON u.id = a.vendedor_id WHERE a.id = ? LIMIT 1'
    );
    $stmt->execute([$id]);
    $linha = $stmt->fetch();
    if (!$linha) {
        responder_erro(404, 'Produto não encontrado.');
    }
    return $linha;
}

/** Fazenda (`fazendas`) no contrato do app. Campos sem coluna no banco ficam nulos. @return array<string, mixed> */
function fazenda_publica(array $f): array
{
    return [
        'id'                => (int)$f['id'],
        'nome'              => $f['nome'],
        'cidade'            => null,
        'estado'            => null,
        'endereco'          => $f['localizacao'] ?? null,
        'area_total_ha'     => (float)$f['area_total'],
        'area_producao_ha'  => null,
        'culturas'          => [],
        'descricao'         => null,
        'inscricao_estadual' => $f['cadastro_estadual'] ?? null,
    ];
}

/** Converte o status do app para o valor de `anuncios.status`. */
function status_anuncio(bool $disponivel): string
{
    return $disponivel ? 'ativo' : 'pausado';
}

/** Lê um inteiro positivo; aceita número ou texto numérico. Encerra com 422 se inválido. */
function inteiro_obrigatorio(mixed $valor, string $campo, int $minimo = 0): int
{
    if (is_float($valor) && floor($valor) != $valor) {
        responder_erro(422, "O campo {$campo} deve ser um número inteiro.");
    }
    if (!is_numeric($valor) || (int)$valor != $valor || (int)$valor < $minimo) {
        responder_erro(422, "Informe um valor válido para {$campo}.");
    }
    return (int)$valor;
}

/** Lê um decimal positivo. Encerra com 422 se inválido. */
function decimal_obrigatorio(mixed $valor, string $campo, bool $aceitaZero = false): float
{
    if (!is_numeric($valor) || (float)$valor < 0 || (!$aceitaZero && (float)$valor == 0.0)) {
        responder_erro(422, "Informe um valor válido para {$campo}.");
    }
    return round((float)$valor, 2);
}

/** Status do pedido: banco (`pedidos.status`) ↔ app (contrato docs/API.md). */
const STATUS_PEDIDO_BANCO_PARA_APP = [
    'recebido'    => 'recebido',
    'negociacao'  => 'recebido',   // o app não tem etapa de negociação em pedidos
    'preparo'     => 'em_preparacao',
    'entregue'    => 'concluido',
    'cancelado'   => 'cancelado',
];

const STATUS_PEDIDO_APP_PARA_BANCO = [
    'recebido'        => 'recebido',
    'em_preparacao'   => 'preparo',
    'concluido'       => 'entregue',
    'cancelado'       => 'cancelado',
];

/**
 * Transições permitidas por tipo de conta, em termos do banco.
 * O app (OrderRules) oferece apenas essas mesmas ações.
 */
const TRANSICOES_PEDIDO = [
    'produtor' => [
        'recebido' => ['preparo', 'cancelado'],
        'preparo'  => ['entregue', 'cancelado'],
    ],
    'comprador' => [
        'recebido' => ['cancelado'],
    ],
];
