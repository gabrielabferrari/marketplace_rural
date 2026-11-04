<?php
/** GET auth/me.php — dados do usuário do token. */
declare(strict_types=1);
require_once __DIR__ . '/../lib/bootstrap.php';

exigir_metodo('GET');
$usuario = usuario_autenticado();
responder(['usuario' => usuario_publico($usuario)]);
