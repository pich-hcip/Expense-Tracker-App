import '../core/api_client.dart';
import '../models/wallet_model.dart';

class WalletService {
  Future<List<WalletModel>> getWallets() async {
    final response = await ApiClient.dio.get('/wallets');
    return (response.data as List)
        .map((json) => WalletModel.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> getSummary() async {
    final response = await ApiClient.dio.get('/wallets/summary');
    return response.data;
  }

  Future<WalletModel> createWallet({
    required String name,
    required String currencyCode,
    required double balance,
    String? icon,
    String? colorHex,
  }) async {
    final response = await ApiClient.dio.post(
      '/wallets',
      data: {
        'name': name,
        'currencyCode': currencyCode,
        'balance': balance,
        'icon': icon,
        'colorHex': colorHex,
        'isDefault': false,
      },
    );
    return WalletModel.fromJson(response.data);
  }

  Future<void> deleteWallet(String id) async {
    await ApiClient.dio.delete('/wallets/$id');
  }

  Future<WalletModel> updateWallet({
    required String id,
    required String name,
    required String currencyCode,
    required double balance,
    String? icon,
    String? colorHex,
    bool isDefault = false,
  }) async {
    final response = await ApiClient.dio.put(
      '/wallets/$id',
      data: {
        'name': name,
        'currencyCode': currencyCode,
        'balance': balance,
        'icon': icon,
        'colorHex': colorHex,
        'isDefault': isDefault,
      },
    );
    return WalletModel.fromJson(response.data);
  }
}
