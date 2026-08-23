import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../infrastructure/network/network_service.dart';
import 'package:corextra/corextra.dart';

class DemoController extends ChangeNotifier {
  final NetworkService networkService;

  String stateMessage = 'Initial state';
  bool showAnimatedText = false;

  DemoController({required this.networkService});

  void updateState() {
    stateMessage =
        'State updated at ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}';
    notifyListeners();
  }

  void toggleAnimation() {
    showAnimatedText = !showAnimatedText;
    notifyListeners();
  }

  void logInfo() {
    debugLog('User tapped the checkout button');
  }

  void logWarning() {
    debugLog('Cache miss for key "user_profile_42" — refetching', level: LogLevel.warning);
  }

  void logError() {
    AppLogger.logError('Failed to decode push notification payload');
  }

  Future<void> sendGet200() async {
    try {
      await networkService.dio.get('/get');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendGetWithQueryParams() async {
    try {
      await networkService.dio.get(
        '/get',
        queryParameters: {'demo': 'corextra', 'page': '2', 'sort': 'desc'},
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendPostWithBody() async {
    try {
      await networkService.dio.post(
        '/post',
        data: {'name': 'corextra', 'feature': 'DevTools'},
        options: Options(headers: {'Authorization': 'Bearer secret-token'}),
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendPutWithBody() async {
    try {
      await networkService.dio.put('/put', data: {'name': 'corextra', 'version': '2.0.0'});
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendPatchWithRawBody() async {
    try {
      await networkService.dio.patch(
        '/patch',
        data: 'raw text payload, not JSON — line one\nline two',
        options: Options(contentType: Headers.textPlainContentType),
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendDelete() async {
    try {
      await networkService.dio.delete('/delete');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendMultipartFormData() async {
    try {
      final form = FormData.fromMap({'name': 'corextra', 'version': '2.0.0'});
      form.files.add(
        MapEntry(
          'avatar',
          MultipartFile.fromBytes(
            List.generate(64, (i) => i % 256),
            filename: 'avatar.png',
            contentType: DioMediaType('image', 'png'),
          ),
        ),
      );
      await networkService.dio.post('/post', data: form);
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendBinaryResponse() async {
    try {
      await networkService.dio.get(
        '/image/png',
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendHtmlResponse() async {
    try {
      await networkService.dio.get('/html');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendLargeResponse() async {
    try {
      await networkService.dio.post(
        '/anything',
        data: {
          'items': List.generate(
            400,
            (i) =>
                'Item #$i — lorem ipsum dolor sit amet, consectetur adipiscing elit.',
          ),
        },
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendGet400() async {
    try {
      await networkService.dio.get('/simulate/400');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendUnauthorized() async {
    try {
      await networkService.dio.get('/simulate/401');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendForbidden() async {
    try {
      await networkService.dio.get('/simulate/403');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendNotFound() async {
    try {
      await networkService.dio.get('/simulate/404');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendConflict() async {
    try {
      await networkService.dio.post('/simulate/409', data: {'email': 'jane@example.com'});
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendValidationError() async {
    try {
      await networkService.dio.post(
        '/simulate/422',
        data: {'email': 'not-an-email', 'password': '123'},
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendRateLimited() async {
    try {
      await networkService.dio.get('/simulate/429');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendGet500() async {
    try {
      await networkService.dio.get('/simulate/500');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendBadGateway() async {
    try {
      await networkService.dio.get('/simulate/502');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendMaintenanceMode() async {
    try {
      await networkService.dio.get('/simulate/503');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendGatewayTimeout() async {
    try {
      await networkService.dio.get('/simulate/504');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendMalformedJson() async {
    try {
      await networkService.dio.get('/simulate/malformed-json');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendHtmlErrorPage() async {
    try {
      await networkService.dio.get('/simulate/html-error-page');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendEmptyResponse() async {
    try {
      await networkService.dio.get('/simulate/empty-204');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendTimeout() async {
    try {
      await networkService.dio.get(
        '/delay/5',
        options: Options(receiveTimeout: const Duration(seconds: 1)),
      );
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendRedirect() async {
    try {
      await networkService.dio.get('/redirect/1');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendParallelRequests() async {
    try {
      await Future.wait([
        networkService.dio.get('/get'),
        networkService.dio.get('/get'),
        networkService.dio.get('/get'),
      ]);
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendNetworkError() async {
    final failingDio = Dio(
      BaseOptions(baseUrl: 'https://this-domain-does-not-exist.invalid'),
    );
    failingDio.interceptors.add(const CorextraDevToolsInterceptor());
    try {
      await failingDio.get('/x');
    } on DioException {
      /* ignore */
    } finally {
      failingDio.close();
    }
  }

  Future<void> sendConnectionTimeout() async {
    final unreachableDio = Dio(
      BaseOptions(
        baseUrl: 'https://10.255.255.1',
        connectTimeout: const Duration(seconds: 2),
      ),
    );
    unreachableDio.interceptors.add(const CorextraDevToolsInterceptor());
    try {
      await unreachableDio.get('/x');
    } on DioException {
      /* ignore */
    } finally {
      unreachableDio.close();
    }
  }

  Future<void> sendCancelledRequest() async {
    final cancelToken = CancelToken();
    Future.delayed(const Duration(milliseconds: 300), () {
      cancelToken.cancel('User navigated away');
    });
    try {
      await networkService.dio.get('/delay/3', cancelToken: cancelToken);
    } on DioException {
      /* ignore */
    }
  }

  @override
  void dispose() {
    networkService.close();
    super.dispose();
  }
}