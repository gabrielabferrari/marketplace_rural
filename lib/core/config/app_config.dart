/// Configurações do aplicativo.
///
/// Nenhuma credencial de banco de dados fica no app: o Flutter conversa
/// apenas com a API REST em PHP. A URL pode ser trocada no build:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://buzzcodex.com.br/api
/// ```
abstract final class AppConfig {
  static const appName = 'Marketplace Rural';
  static const appVersion = '1.0.0';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://buzzcodex.com.br/api',
  );

  /// E-mail exibido na tela de suporte. Vazio = canal ainda não definido.
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');

  static const requestTimeout = Duration(seconds: 15);
  static const uploadTimeout = Duration(seconds: 60);

  /// Quantidade a partir da qual o estoque é considerado baixo, quando o
  /// produto não define o próprio mínimo.
  static const defaultLowStockThreshold = 10;

  static const maxProductImages = 5;
}
