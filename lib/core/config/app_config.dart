/// Configurações do aplicativo.
///
/// Nenhuma credencial de banco de dados fica no app: o Flutter conversa
/// apenas com o backend PHP do site (pasta `backend/`), usando a mesma
/// sessão e as mesmas rotas do site. A URL pode ser trocada no build:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://buzzcodex.com.br/backend
/// ```
abstract final class AppConfig {
  static const appName = 'Marketplace Rural';
  static const appVersion = '1.0.0';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://buzzcodex.com.br/backend',
  );

  /// Raiz pública do site: as fotos de produto são caminhos relativos a ela
  /// (ex.: `uploads/produtos/arquivo.jpg`).
  static const siteBaseUrl = String.fromEnvironment(
    'SITE_BASE_URL',
    defaultValue: 'https://buzzcodex.com.br/',
  );

  /// E-mail exibido na tela de suporte. Vazio = canal ainda não definido.
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  static const requestTimeout = Duration(seconds: 15);
  static const uploadTimeout = Duration(seconds: 60);

  /// Quantidade a partir da qual o estoque é considerado baixo, quando o
  /// produto não define o próprio mínimo.
  static const defaultLowStockThreshold = 10;

  /// O backend do site guarda uma foto por anúncio (`anuncios_fotos`).
  static const maxProductImages = 1;

  /// Converte um caminho de imagem devolvido pelo servidor em URL absoluta.
  static String absoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = siteBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
