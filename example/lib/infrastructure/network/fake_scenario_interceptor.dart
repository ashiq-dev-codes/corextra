import 'package:dio/dio.dart';

/// Short-circuits `/simulate/<key>` with a canned response (real backend error shapes httpbin.org can't produce); must run last so earlier interceptors still observe it via `callFollowing = true`.
class FakeScenarioInterceptor extends Interceptor {
  const FakeScenarioInterceptor();

  static const _prefix = '/simulate/';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.path.startsWith(_prefix)) {
      handler.next(options);
      return;
    }

    final scenario = _scenarios[options.path.substring(_prefix.length)];
    if (scenario == null) {
      handler.next(options);
      return;
    }

    final response = Response(
      requestOptions: options,
      statusCode: scenario.statusCode,
      statusMessage: scenario.statusMessage,
      headers: Headers.fromMap(scenario.headers),
      data: scenario.body,
    );

    if (scenario.statusCode < 400) {
      handler.resolve(response, true);
    } else {
      handler.reject(
        DioException(
          requestOptions: options,
          response: response,
          type: DioExceptionType.badResponse,
          message: '${scenario.statusCode} ${scenario.statusMessage}',
        ),
        true,
      );
    }
  }

  static final Map<String, _FakeScenario> _scenarios = {
    '400': _FakeScenario(
      statusCode: 400,
      statusMessage: 'Bad Request',
      body: {
        'error': 'bad_request',
        'message': 'The request could not be understood due to malformed syntax.',
      },
    ),
    '401': _FakeScenario(
      statusCode: 401,
      statusMessage: 'Unauthorized',
      headers: {
        'www-authenticate': ['Bearer error="invalid_token"'],
      },
      body: {
        'error': 'invalid_token',
        'message': 'Your session has expired. Please sign in again.',
      },
    ),
    '403': _FakeScenario(
      statusCode: 403,
      statusMessage: 'Forbidden',
      body: {
        'error': 'forbidden',
        'message': "You don't have permission to access this resource.",
      },
    ),
    '404': _FakeScenario(
      statusCode: 404,
      statusMessage: 'Not Found',
      body: {
        'error': 'not_found',
        'message': 'The requested user (id: 42) could not be found.',
      },
    ),
    '409': _FakeScenario(
      statusCode: 409,
      statusMessage: 'Conflict',
      body: {
        'error': 'conflict',
        'message': 'An account with this email already exists.',
      },
    ),
    '422': _FakeScenario(
      statusCode: 422,
      statusMessage: 'Unprocessable Entity',
      body: {
        'error': 'validation_failed',
        'errors': {
          'email': ['must be a valid email address'],
          'password': ['must be at least 8 characters long'],
        },
      },
    ),
    '429': _FakeScenario(
      statusCode: 429,
      statusMessage: 'Too Many Requests',
      headers: {
        'retry-after': ['30'],
      },
      body: {
        'error': 'rate_limited',
        'message': 'Too many requests. Please try again in 30 seconds.',
      },
    ),
    '500': _FakeScenario(
      statusCode: 500,
      statusMessage: 'Internal Server Error',
      body: {
        'error': 'internal_server_error',
        'message': 'An unexpected error occurred. Our team has been notified.',
        'requestId': 'req_8f3a1c2d',
      },
    ),
    '502': _FakeScenario(
      statusCode: 502,
      statusMessage: 'Bad Gateway',
      body: {
        'error': 'bad_gateway',
        'message': 'The upstream server returned an invalid response.',
      },
    ),
    '503': _FakeScenario(
      statusCode: 503,
      statusMessage: 'Service Unavailable',
      headers: {
        'retry-after': ['120'],
      },
      body: {
        'error': 'maintenance',
        'message': "We're currently performing scheduled maintenance. Please check back soon.",
      },
    ),
    '504': _FakeScenario(
      statusCode: 504,
      statusMessage: 'Gateway Timeout',
      body: {
        'error': 'gateway_timeout',
        'message': 'The upstream server failed to respond in time.',
      },
    ),
    'malformed-json': _FakeScenario(
      statusCode: 200,
      statusMessage: 'OK',
      body: '{"user": {"id": 1, "name": "Jane Doe", "email": "jane@example.com"',
    ),
    'html-error-page': _FakeScenario(
      statusCode: 502,
      statusMessage: 'Bad Gateway',
      headers: {
        'content-type': ['text/html'],
      },
      body:
          '<html><head><title>502 Bad Gateway</title></head>'
          '<body><center><h1>502 Bad Gateway</h1></center>'
          '<hr><center>nginx</center></body></html>',
    ),
    'empty-204': _FakeScenario(
      statusCode: 204,
      statusMessage: 'No Content',
      body: null,
    ),
  };
}

class _FakeScenario {
  const _FakeScenario({
    required this.statusCode,
    required this.statusMessage,
    required this.body,
    this.headers = const {},
  });

  final int statusCode;
  final String statusMessage;
  final Object? body;
  final Map<String, List<String>> headers;
}