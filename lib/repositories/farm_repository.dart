import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/network/endpoints.dart';
import '../core/routes/permissions.dart';
import '../models/farm.dart';
import '../models/json_utils.dart';
import '../models/user.dart';

class FarmRepository {
  FarmRepository(this._api, this._currentUser);

  final ApiClient _api;
  final AppUser? Function() _currentUser;

  /// Retorna `null` quando o produtor ainda não cadastrou a propriedade.
  Future<Farm?> get() async {
    Permissions.ensure(_currentUser(), Feature.manageFarm);
    try {
      final data = Json.map(await _api.get(Endpoints.farm));
      final farm = Json.map(data['fazenda'] ?? data);
      if (farm.isEmpty) return null;
      return Farm.fromJson(farm);
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.notFound) return null;
      rethrow;
    }
  }

  Future<Farm> save(Farm farm) async {
    Permissions.ensure(_currentUser(), Feature.manageFarm);
    final data = Json.map(await _api.post(Endpoints.farmSave, body: farm.toRequest()));
    return Farm.fromJson(Json.map(data['fazenda'] ?? data));
  }
}
