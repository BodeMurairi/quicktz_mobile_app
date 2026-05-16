import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<AuthTokens> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post(ApiEndpoints.login, data: {
      'identifier': identifier,
      'password': password,
    });
    final tokens = AuthTokens.fromJson(response.data);
    await SecureStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  Future<AuthTokens> register({
    required String fullName,
    required String password,
    String? email,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,
      'password': password,
    };
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    final response = await _dio.post(ApiEndpoints.register, data: body);
    final tokens = AuthTokens.fromJson(response.data);
    await SecureStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens;
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data);
  }

  Future<void> logout() => SecureStorage.clearTokens();
}
