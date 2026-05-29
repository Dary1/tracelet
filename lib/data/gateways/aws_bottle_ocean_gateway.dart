import 'package:tracelet/data/api/tracelet_api_client.dart';
import 'package:tracelet/domain/gateways/bottle_ocean_gateway.dart';

class AwsBottleOceanGateway implements BottleOceanGateway {
  AwsBottleOceanGateway(this._api);

  final TraceletApiClient _api;

  @override
  Future<void> deposit({
    required String senderUserId,
    required Map<String, dynamic> payload,
  }) async {
    await _api.post('/bottles', {'payload': payload});
  }

  @override
  Future<Map<String, dynamic>?> pull() async {
    final body = await _api.post('/bottles/pull');
    if (body.containsKey('message')) {
      return null;
    }
    return body;
  }
}
