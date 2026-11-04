/// Mapa central de endpoints da API PHP.
///
/// Situação atual no servidor (ver docs/API.md):
/// * `auth/*` e `usuarios/*` → implementados em `server/api` (tabela `usuarios`).
/// * Demais → aguardando o SQL do banco para implementação no servidor.
abstract final class Endpoints {
  // Autenticação
  static const login = 'auth/login.php';
  static const register = 'auth/cadastro.php';
  static const me = 'auth/me.php';
  static const logout = 'auth/logout.php';
  static const forgotPassword = 'auth/recuperar-senha.php';
  static const changePassword = 'auth/alterar-senha.php';

  // Perfil
  static const profileUpdate = 'usuarios/atualizar.php';

  // Produtos e estoque
  static const products = 'produtos/listar.php';
  static const productDetail = 'produtos/detalhe.php';
  static const productCreate = 'produtos/cadastrar.php';
  static const productUpdate = 'produtos/editar.php';
  static const productDelete = 'produtos/excluir.php';
  static const productImageUpload = 'produtos/imagem.php';
  static const stockUpdate = 'produtos/estoque.php';
  static const stockHistory = 'produtos/historico-estoque.php';

  // Pedidos
  static const orders = 'pedidos/listar.php';
  static const orderDetail = 'pedidos/detalhe.php';
  static const orderCreate = 'pedidos/criar.php';
  static const orderUpdate = 'pedidos/atualizar.php';

  // Negociações
  static const negotiations = 'negociacoes/listar.php';
  static const negotiationDetail = 'negociacoes/detalhe.php';
  static const negotiationCreate = 'negociacoes/criar.php';
  static const negotiationRespond = 'negociacoes/responder.php';

  // Favoritos
  static const favorites = 'favoritos/listar.php';
  static const favoriteAdd = 'favoritos/adicionar.php';
  static const favoriteRemove = 'favoritos/remover.php';

  // Fazenda
  static const farm = 'fazenda/detalhe.php';
  static const farmSave = 'fazenda/salvar.php';

  // Notificações
  static const notifications = 'notificacoes/listar.php';
  static const notificationsRead = 'notificacoes/marcar-lidas.php';
}
