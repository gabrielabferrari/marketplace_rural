<?php
/**
 * POST auth/logout.php
 *
 * O token é sem estado (não há tabela de sessões), então o encerramento é
 * feito descartando o token no aplicativo. Para revogar tokens no servidor
 * antes do vencimento, será necessária uma tabela de sessões/lista negra.
 * Alterar a senha invalida todos os tokens existentes.
 */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('POST');
usuario_autenticado();
responder(null);
