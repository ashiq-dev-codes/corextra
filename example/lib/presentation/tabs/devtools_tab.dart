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
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
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
            },
            onRun: _run,
          ),
        ),
        SectionCard(
          title: 'Error Scenarios',
          icon: Icons.error_outline_rounded,
          subtitle: 'Status codes and failures you\'ll hit in production.',
          child: _ScenarioGrid(
            color: Colors.redAccent,
            scenarios: {
              '400 Bad Req': controller.sendGet400,
              '401 Unauth': controller.sendUnauthorized,
              '403 Forbidden': controller.sendForbidden,
              '500 Server': controller.sendGet500,
              'Timeout': controller.sendTimeout,
              'Network Error': controller.sendNetworkError,
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