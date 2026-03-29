import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/backend_debug_store.dart';

class BackendDebugPanel extends StatefulWidget {
  const BackendDebugPanel({super.key});

  @override
  State<BackendDebugPanel> createState() => _BackendDebugPanelState();
}

class _BackendDebugPanelState extends State<BackendDebugPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Positioned(
      right: 12,
      bottom: 90,
      child: ValueListenableBuilder<BackendDebugState>(
        valueListenable: BackendDebugStore.instance.state,
        builder: (context, state, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: _expanded ? 360 : 56,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _expanded
                ? _ExpandedPanel(
                    state: state,
                    onClose: () => setState(() => _expanded = false),
                  )
                : IconButton(
                    onPressed: () => setState(() => _expanded = true),
                    icon: const Icon(Icons.bug_report_outlined),
                  ),
          );
        },
      ),
    );
  }
}

class _ExpandedPanel extends StatelessWidget {
  final BackendDebugState state;
  final VoidCallback onClose;

  const _ExpandedPanel({
    required this.state,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Backend Debug', style: textTheme.titleMedium),
              const Spacer(),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          _item('Endpoint', '${state.method} ${state.endpoint}'.trim()),
          _item('HTTP', state.statusCode?.toString() ?? '-'),
          _item('Handler', state.backendHandler.isEmpty ? '-' : state.backendHandler),
          _item(
            'Execution',
            state.executionTimeMs == null ? '-' : '${state.executionTimeMs} ms',
          ),
          _item('WebSocket', state.websocketStatus),
          _item('WS Event', state.websocketEvent),
          _item('AI Result', state.aiResult),
          _item('Storage Read', state.storageRead),
          _item('Storage Write', state.storageWrite),
          _item('Errors', state.errorMessage),
          _item('WS Payload', state.websocketPayload),
          _item('Raw JSON', state.rawResponse),
        ],
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value.isEmpty ? '-' : value,
            style: const TextStyle(fontSize: 11, height: 1.35),
          ),
        ],
      ),
    );
  }
}
