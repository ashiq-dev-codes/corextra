import 'dart:async';

import 'package:corextra/corextra.dart';
import 'package:flutter_test/flutter_test.dart';

const _url = 'https://socket.example.test';

void main() {
  setUp(() {
    CorextraDevTools.instance.enabled = true;
    CorextraDevTools.instance.resetAll();
  });

  tearDown(() => CorextraDevTools.instance.resetAll());

  const logger = CorextraSocketLogger(url: _url, consoleEnabled: false);

  test('emit records a completed EMIT row with the event and payload', () {
    logger.emit('chat:open', {'chat_id': 7});

    final events = CorextraDevTools.instance.network.events;
    expect(events, hasLength(1));

    final event = events.single;
    expect(event.isSocket, isTrue);
    expect(event.method, 'EMIT');
    expect(event.socketEvent, 'chat:open');
    expect(event.url, _url);
    expect(event.requestBody, {'chat_id': 7});
    expect(event.isPending, isFalse);
    expect(event.isError, isFalse);
  });

  test('emitWithAck stays pending until the ack, then stores it', () async {
    final ackCompleter = Completer<Object?>();
    final future = logger.emitWithAck('chat:latest_messages', {
      'page': 1,
    }, () => ackCompleter.future);

    final event = CorextraDevTools.instance.network.events.single;
    expect(event.isPending, isTrue);

    ackCompleter.complete({'data': []});
    expect(await future, {'data': []});

    expect(event.isPending, isFalse);
    expect(event.responseBody, {'data': []});
    expect(event.duration, isNotNull);
  });

  test(
    'emitWithAck marks the row failed and rethrows when the ack fails',
    () async {
      await expectLater(
        logger.emitWithAck(
          'chat:latest_messages',
          null,
          () async => throw Exception('operation has timed out'),
        ),
        throwsException,
      );

      final event = CorextraDevTools.instance.network.events.single;
      expect(event.isError, isTrue);
      expect(event.errorMessage, contains('timed out'));
      expect(event.isPending, isFalse);
    },
  );

  test('receive records an ON row with the pushed data as the response', () {
    logger.receive('message:new', {'chat_id': 7});

    final event = CorextraDevTools.instance.network.events.single;
    expect(event.method, 'ON');
    expect(event.socketEvent, 'message:new');
    expect(event.responseBody, {'chat_id': 7});
    expect(event.isError, isFalse);
  });

  test('receive with isError marks the row failed', () {
    logger.receive('connect_error', 'xhr poll error', isError: true);

    final event = CorextraDevTools.instance.network.events.single;
    expect(event.isError, isTrue);
    expect(event.errorMessage, 'xhr poll error');
  });

  test('drops Socket.IO ack callbacks from the captured data', () {
    logger.receive('chat:ping', [
      {'id': 1},
      (Object? _) {},
    ]);

    final event = CorextraDevTools.instance.network.events.single;
    expect(event.responseBody, {'id': 1});
  });

  test('keeps a genuine one-item list as a list', () {
    logger.emit('chat:ids', [1]);

    expect(CorextraDevTools.instance.network.events.single.requestBody, [1]);
  });

  test('captures nothing while DevTools is disabled', () {
    CorextraDevTools.instance.enabled = false;
    logger.emit('chat:open', {'chat_id': 7});
    logger.receive('message:new', null);

    expect(CorextraDevTools.instance.network.events, isEmpty);
  });

  test('devToolsEnabled: false overrides a globally enabled DevTools', () {
    const off = CorextraSocketLogger(
      url: _url,
      consoleEnabled: false,
      devToolsEnabled: false,
    );
    off.emit('chat:open', null);

    expect(CorextraDevTools.instance.network.events, isEmpty);
  });
}
