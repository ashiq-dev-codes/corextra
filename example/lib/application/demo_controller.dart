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
      await networkService.dio.get('/status/400');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendUnauthorized() async {
    try {
      await networkService.dio.get('/status/401');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendForbidden() async {
    try {
      await networkService.dio.get('/status/403');
    } on DioException {
      /* ignore */
    }
  }

  Future<void> sendGet500() async {
    try {
      await networkService.dio.get('/status/500');
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

  @override
  void dispose() {
    networkService.close();
    super.dispose();
  }
}