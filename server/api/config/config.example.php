<?php
/**
 * MODELO de configuração da API.
 *
 * 1. Copie este arquivo para `config.php` (na mesma pasta).
 * 2. Preencha os valores OU defina as variáveis de ambiente equivalentes
 *    no painel de hospedagem (recomendado).
 * 3. Nunca envie `config.php` para o Git nem o coloque no aplicativo.
 *
 * Recomendação: crie no phpMyAdmin um usuário MySQL exclusivo da API com
 * permissões apenas de SELECT/INSERT/UPDATE/DELETE no banco
 * `buzzcode_marketplace_rural` — não use o usuário root.
 */
return [
    'db_host'     => getenv('MR_DB_HOST') ?: 'localhost',
    'db_name'     => getenv('MR_DB_NAME') ?: 'buzzcode_marketplace_rural',
    'db_user'     => getenv('MR_DB_USER') ?: 'buzzcode_ADM',
    'db_pass'     => getenv('MR_DB_PASS') ?: 'yh5{Gs6Nsy6DgQYn',

    // Chave secreta para assinar tokens. Gere com:
    //   php -r "echo bin2hex(random_bytes(32));"
    'token_secret' => getenv('MR_TOKEN_SECRET') ?: '',

    // Validade do token em segundos (padrão: 30 dias).
    'token_ttl'    => 60 * 60 * 24 * 30,

    // Endereço público do site (base das URLs de imagens) e pasta física onde
    // as fotos de produtos são gravadas. Em produção: public_base_url =
    // "https://buzzcodex.com.br/" e uploads_dir = pasta "uploads/produtos" do site.
    'public_base_url' => getenv('MR_PUBLIC_BASE_URL') ?: 'https://buzzcodex.com.br/',
    'uploads_dir'     => getenv('MR_UPLOADS_DIR') ?: __DIR__ . '/../../uploads/produtos',

    // Origens permitidas para o Flutter Web (CORS). Apps Android/iOS não usam CORS.
    'cors_origins' => ['https://buzzcodex.com.br'],
];
