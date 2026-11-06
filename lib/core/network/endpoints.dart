/// Mapa central das rotas do backend PHP (pasta `backend/` do site).
///
/// Rotas marcadas com "(não existe)" ainda não foram implementadas no backend
/// do site; o app mostra o aviso de recurso indisponível, sem dados simulados.
abstract final class Endpoints {
  // Autenticação e perfil
  static const login = 'auth/login.php';
  static const register = 'auth/cadastro.php';
  static const me = 'auth/sessao.php';
  static const logout = 'auth/logout.php';
  static const profileUpdate = 'auth/atualizar_perfil.php';
  static const accountType = 'usuarios/tipo.php';
  static const forgotPassword = 'auth/recuperar-senha.php'; // (não existe)
  static const changePassword = 'auth/alterar-senha.php'; // (não existe)

  // Produtos e estoque
  static const products = 'produtos/listar.php';
  static const productCreate = 'produtos/cadastrar.php';
  static const productUpdate = 'produtos/editar.php';
  static const productDelete = 'produtos/excluir.php';
  static const stockUpdate = 'produtos/estoque.php';
  static const stockHistory = 'produtos/historico-estoque.php'; // (não existe)

  // Pedidos
  static const orders = 'pedidos/listar.php';
  static const orderCreate = 'pedidos/criar.php';
  static const orderUpdate = 'pedidos/atualizar.php';

  // Negociações (não existem no backend)
  static const negotiations = 'negociacoes/listar.php';
  static const negotiationDetail = 'negociacoes/detalhe.php';
  static const negotiationCreate = 'negociacoes/criar.php';
  static const negotiationRespond = 'negociacoes/responder.php';

  // Favoritos
  static const favorites = 'favoritos/listar.php';
  static const favoriteUpdate = 'favoritos/atualizar.php';

  // Fazenda (não existe no backend)
  static const farm = 'fazenda/detalhe.php';
  static const farmSave = 'fazenda/salvar.php';

  // Notificações (não existem no backend)
  static const notifications = 'notificacoes/listar.php';
  static const notificationsRead = 'notificacoes/marcar-lidas.php';
}
