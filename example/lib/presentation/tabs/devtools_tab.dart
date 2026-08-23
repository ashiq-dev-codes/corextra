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
      children: [
        SectionCard(
          title: 'Network Scenarios',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildButton('Get 200', controller.sendGet200),
              _buildButton('Get Params', controller.sendGetWithQueryParams),
              _buildButton('Post Body', controller.sendPostWithBody),
              _buildButton('Put Body', controller.sendPutWithBody),
              _buildButton('Patch Raw', controller.sendPatchWithRawBody),
              _buildButton('Delete', controller.sendDelete),
              _buildButton('Multipart', controller.sendMultipartFormData),
              _buildButton('Binary', controller.sendBinaryResponse),
              _buildButton('HTML', controller.sendHtmlResponse),
              _buildButton('Large Resp', controller.sendLargeResponse),
              _buildButton('400 Error', controller.sendGet400),
              _buildButton('401 Auth', controller.sendUnauthorized),
              _buildButton('403 Forbidden', controller.sendForbidden),
              _buildButton('500 Server', controller.sendGet500),
              _buildButton('Timeout', controller.sendTimeout),
              _buildButton('Redirect', controller.sendRedirect),
              _buildButton('Parallel', controller.sendParallelRequests),
              _buildButton('Net Error', controller.sendNetworkError),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, Future<void> Function() action) {
    return ElevatedButton(
      onPressed: () async {
        onNotify('Running: $label...');
        await action();
        onNotify('Completed: $label');
      },
      child: Text(label),
    );
  }
}