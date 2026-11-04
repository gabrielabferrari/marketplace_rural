<?php
/**
 * Inicialização comum a todos os endpoints:
 * configuração, cabeçalhos, CORS, tratamento de erros e conexão PDO.
 */
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');

require_once __DIR__ . '/response.php';
require_once __DIR__ . '/token.php';
require_once __DIR__ . '/dominio.php';

/** @return array<string, mixed> */
function config(): array
{
    static $config = null;
    if ($config === null) {
        $file = __DIR__ . '/../config/config.php';
        if (!is_file($file)) {
            error_log('[API] config/config.php ausente.');
            responder_erro(500, 'Servidor não configurado.');
        }
        $config = require $file;
        if (($config['token_secret'] ?? '') === '' || strlen($config['token_secret']) < 32) {
            error_log('[API] token_secret ausente ou curto demais.');
            responder_erro(500, 'Servidor não configurado.');
        }
    }
    return $config;
}

// Erros inesperados nunca expõem detalhes ao cliente.
set_exception_handler(function (Throwable $e): void {
    error_log('[API] ' . $e->getMessage() . ' em ' . $e->getFile() . ':' . $e->getLine());
    responder_erro(500, 'Erro interno. Tente novamente mais tarde.');
});
set_error_handler(function (int $severity, string $message, string $file, int $line): bool {
    throw new ErrorException($message, 0, $severity, $file, $line);
});

// CORS (somente para Flutter Web).
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin !== '' && in_array($origin, config()['cors_origins'] ?? [], true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
    header('Access-Control-Allow-Headers: Authorization, Content-Type, Accept');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
}
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $c = config();
        $pdo = new PDO(
            "mysql:host={$c['db_host']};dbname={$c['db_name']};charset=utf8mb4",
            $c['db_user'],
            $c['db_pass'],
            [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false, // consultas realmente parametrizadas
            ]
        );
    }
    return $pdo;
}

function exigir_metodo(string ...$metodos): void
{
    if (!in_array($_SERVER['REQUEST_METHOD'] ?? '', $metodos, true)) {
        header('Allow: ' . implode(', ', $metodos));
        responder_erro(405, 'Método não permitido.');
    }
}

/** Corpo JSON da requisição. @return array<string, mixed> */
function corpo_json(): array
{
    $raw = file_get_contents('php://input') ?: '';
    if (strlen($raw) > 1_000_000) {
        responder_erro(413, 'Requisição muito grande.');
    }
    if ($raw === '') {
        return [];
    }
    $data = json_decode($raw, true);
    if (!is_array($data)) {
        responder_erro(400, 'JSON inválido.');
    }
    return $data;
}

function texto(array $dados, string $campo, int $max = 255): string
{
    $valor = trim((string)($dados[$campo] ?? ''));
    if (mb_strlen($valor) > $max) {
        responder_erro(422, "O campo {$campo} é muito longo.");
    }
    return $valor;
}

/** Dados públicos do usuário (nunca inclui a senha). @return array<string, mixed> */
function usuario_publico(array $u): array
{
    return [
        'id'       => (int)$u['id'],
        'nome'     => $u['nome'],
        'email'    => $u['email'],
        'telefone' => $u['telefone'],
        'tipo'     => $u['tipo'],
    ];
}
