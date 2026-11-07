import 'package:dio/dio.dart';

import 'constants.dart';
import 'secure_storage.dart';

class ApiClient {
  static final Dio dio =
      _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl:
            ApiConstants.baseUrl,

        connectTimeout:
            const Duration(
          seconds: 10,
        ),

        receiveTimeout:
            const Duration(
          seconds: 10,
        ),

        headers: {
          'Content-Type':
              'application/json',

          'Accept':
              'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        // ===================================================
        // REQUEST
        // ===================================================

        onRequest:
            (options, handler) async {
          final bool isAuthEndpoint =
              options.path
                  .startsWith(
            '/auth/',
          );

          // Auth endpoints don't need JWT.
          if (!isAuthEndpoint) {
            final token =
                await SecureStorage
                    .getToken();

            if (token != null &&
                token
                    .trim()
                    .isNotEmpty) {
              options.headers[
                      'Authorization'] =
                  'Bearer ${token.trim()}';

              print(
                'JWT: ATTACHED',
              );
            } else {
              print(
                'JWT: NOT FOUND',
              );
            }
          }

          print(
            '================ API REQUEST ================',
          );

          print(
            'METHOD: ${options.method}',
          );

          print(
            'URL: ${options.uri}',
          );

          print(
            'DATA: ${options.data}',
          );

          print(
            '=============================================',
          );

          handler.next(options);
        },

        // ===================================================
        // RESPONSE
        // ===================================================

        onResponse:
            (response, handler) {
          print(
            '=============== API RESPONSE ================',
          );

          print(
            'STATUS: ${response.statusCode}',
          );

          print(
            'URL: ${response.requestOptions.uri}',
          );

          print(
            'DATA: ${response.data}',
          );

          print(
            '=============================================',
          );

          handler.next(response);
        },

        // ===================================================
        // ERROR
        // ===================================================

        onError:
            (DioException e, handler) {
          print(
            '================ API ERROR ==================',
          );

          print(
            'URL: ${e.requestOptions.uri}',
          );

          print(
            'STATUS: ${e.response?.statusCode}',
          );

          print(
            'DATA: ${e.response?.data}',
          );

          print(
            'MESSAGE: ${e.message}',
          );

          print(
            '=============================================',
          );

          handler.next(e);
        },
      ),
    );

    return dio;
  }
}