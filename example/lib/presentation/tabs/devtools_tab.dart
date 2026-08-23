import 'package:flutter/material.dart';
import '../../application/demo_controller.dart';
import '../widgets/section_card.dart';

class DevToolsTab extends StatelessWidget {
  final DemoController controller;
  final ValueChanged<String> onNotify;

  const DevToolsTab({
    super.key,
    required this.controller,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        SectionCard(
          title: 'Logs',
          icon: Icons.terminal_rounded,
          subtitle: 'Structured log lines captured by the Logs tab.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: controller.logInfo,
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('Log Info'),
                style: OutlinedButton.styleFrom(foregroundColor: colorScheme.primary),
              ),
              OutlinedButton.icon(
                onPressed: controller.logWarning,
                icon: const Icon(Icons.warning_amber_rounded, size: 18),
                label: const Text('Log Warning'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
              ),
              OutlinedButton.icon(
                onPressed: controller.logError,
                icon: const Icon(Icons.error_outline_rounded, size: 18),
                label: const Text('Log Error'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Success Requests',
          icon: Icons.check_circle_outline_rounded,
          subtitle: 'Common request shapes captured by the Network tab.',
          child: _ScenarioGrid(
            color: Colors.green,
            scenarios: {
              'GET 200': controller.sendGet200,
              'Query Params': controller.sendGetWithQueryParams,
              'POST Body': controller.sendPostWithBody,
              'PUT Body': controller.sendPutWithBody,
              'PATCH Raw': controller.sendPatchWithRawBody,
              'DELETE': controller.sendDelete,
              'Multipart': controller.sendMultipartFormData,
              'Binary Resp': controller.sendBinaryResponse,
              'HTML Resp': controller.sendHtmlResponse,
              'Large Resp': controller.sendLargeResponse,
              'Redirect': controller.sendRedirect,
              'Parallel x3': controller.sendParallelRequests,
              'Empty 204': controller.sendEmptyResponse,
            },
            onRun: _run,
          ),
        ),
        SectionCard(
          title: 'Client Errors (4xx)',
          icon: Icons.person_off_outlined,
          subtitle: 'Auth, validation and conflict responses from a real backend.',
          child: _ScenarioGrid(
            color: Colors.deepOrange,
            scenarios: {
              '400 Bad Request': controller.sendGet400,
              '401 Unauthorized': controller.sendUnauthorized,
              '403 Forbidden': controller.sendForbidden,
              '404 Not Found': controller.sendNotFound,
              '409 Conflict': controller.sendConflict,
              '422 Validation': controller.sendValidationError,
              '429 Rate Limited': controller.sendRateLimited,
            },
            onRun: _run,
          ),
        ),
        SectionCard(
          title: 'Server Errors (5xx)',
          icon: Icons.dns_outlined,
          subtitle: 'Backend and infrastructure failures.',
          child: _ScenarioGrid(
            color: Colors.redAccent,
            scenarios: {
              '500 Server Error': controller.sendGet500,
              '502 Bad Gateway': controller.sendBadGateway,
              '503 Maintenance': controller.sendMaintenanceMode,
              '504 Gateway Timeout': controller.sendGatewayTimeout,
            },
            onRun: _run,
          ),
        ),
        SectionCard(
          title: 'Malformed & Edge-Case Payloads',
          icon: Icons.data_object_rounded,
          subtitle: 'Responses that break naive parsing code.',
          child: _ScenarioGrid(
            color: Colors.purple,
            scenarios: {
              'Malformed JSON': controller.sendMalformedJson,
              'HTML Error Page': controller.sendHtmlErrorPage,
            },
            onRun: _run,
          ),
        ),
        SectionCard(
          title: 'Connectivity Failures',
          icon: Icons.wifi_off_rounded,
          subtitle: 'Timeouts, unreachable hosts and cancellations.',
          child: _ScenarioGrid(
            color: Colors.blueGrey,
            scenarios: {
              'Receive Timeout': controller.sendTimeout,
              'Connect Timeout': controller.sendConnectionTimeout,
              'DNS/Network Error': controller.sendNetworkError,
              'Cancelled Request': controller.sendCancelledRequest,
            },
            onRun: _run,
          ),
        ),
      ],
    );
  }

  Future<void> _run(String label, Future<void> Function() action) async {
    onNotify('Running: $label…');
    await action();
    onNotify('Completed: $label');
  }
}

class _ScenarioGrid extends StatelessWidget {
  final Map<String, Future<void> Function()> scenarios;
  final Color color;
  final Future<void> Function(String label, Future<void> Function() action) onRun;

  const _ScenarioGrid({
    required this.scenarios,
    required this.color,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: scenarios.entries
          .map(
            (entry) => OutlinedButton(
              onPressed: () => onRun(entry.key, entry.value),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(entry.key),
            ),
          )
          .toList(),
    );
  }
}