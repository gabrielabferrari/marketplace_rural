import '../../models/user.dart';
import '../network/api_exception.dart';

/// Funcionalidades protegidas por tipo de conta.
enum Feature {
  manageProducts,
  manageStock,
  manageFarm,
  updateOrderAsProducer,
  placeOrder,
  startNegotiation,
}

/// Regras de acesso do aplicativo. São verificadas:
/// 1. no menu (o item nem aparece);
/// 2. nas rotas (a tela não abre);
/// 3. nos repositórios (a requisição não é enviada).
///
/// O servidor deve repetir as mesmas verificações usando o token.
abstract final class Permissions {
  static const _producerOnly = {
    Feature.manageProducts,
    Feature.manageStock,
    Feature.manageFarm,
    Feature.updateOrderAsProducer,
  };

  static const _buyerOnly = {
    Feature.placeOrder,
    Feature.startNegotiation,
  };

  static bool can(AppUser? user, Feature feature) {
    if (user == null) return false;
    if (_producerOnly.contains(feature)) return user.isProducer;
    if (_buyerOnly.contains(feature)) return user.isBuyer;
    return true;
  }

  /// Lança [ApiException] (forbidden) quando o usuário não tem acesso.
  static void ensure(AppUser? user, Feature feature) {
    if (user == null) {
      throw const ApiException(
          ApiErrorType.unauthorized, 'Entre na sua conta para continuar.');
    }
    if (!can(user, feature)) {
      throw const ApiException(ApiErrorType.forbidden,
          'Sua conta não tem permissão para esta ação.');
    }
  }
}
