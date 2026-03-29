import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'backend_debug_store.dart';

/// Structured debug logger for API / WebSocket / backend diagnostics.
/// Prints colour-coded JSON-structured logs in debug mode.
class DebugLogger {
  DebugLogger._();

  // ── API Request / Response ───────────────────────
  static void apiRequest(String method, String url, {Map<String, dynamic>? body}) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        method: method,
        endpoint: url,
        rawResponse: body == null ? '' : const JsonEncoder.withIndent('  ').convert(body),
        errorMessage: '',
        clearStatusCode: true,
        clearExecutionTime: true,
      ),
    );
    _log('API_REQ', {
      'method': method,
      'url': url,
      if (body != null) 'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static void apiResponse(
    String url,
    int statusCode,
    String body,
    Duration elapsed, {
    Map<String, String>? headers,
  }) {
    final level = statusCode >= 400 ? 'ERROR' : 'API_RES';
    dynamic parsedBody;
    String handlerName =
        headers?['x-backend-handler'] ?? headers?['x-lambda-function'] ?? '';
    try {
      parsedBody = jsonDecode(body);
      if (parsedBody is Map<String, dynamic>) {
        handlerName = (parsedBody['handler'] as String?) ??
            (parsedBody['lambdaFunction'] as String?) ??
            handlerName;
      }
    } catch (_) {
      parsedBody = body.length > 200 ? '${body.substring(0, 200)}...' : body;
    }
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        endpoint: url,
        statusCode: statusCode,
        executionTimeMs: elapsed.inMilliseconds,
        rawResponse: const JsonEncoder.withIndent('  ').convert(parsedBody),
        backendHandler: handlerName,
        errorMessage: statusCode >= 400 ? 'HTTP $statusCode' : '',
      ),
    );
    _log(level, {
      'url': url,
      'statusCode': statusCode,
      'executionTimeMs': elapsed.inMilliseconds,
      'body': parsedBody,
    });
  }

  // ── Backend Handler ─────────────────────────────
  static void backendHandlerResult(String handlerName, {
    String? riskLevel,
    String? matchId,
    int? statusCode,
    String? error,
  }) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        backendHandler: handlerName,
        statusCode: statusCode,
        errorMessage: error ?? BackendDebugStore.instance.state.value.errorMessage,
      ),
    );
    _log('HANDLER', {
      'handler': handlerName,
      if (riskLevel != null) 'riskLevel': riskLevel,
      if (matchId != null) 'matchId': matchId,
      if (statusCode != null) 'statusCode': statusCode,
      if (error != null) 'error': error,
    });
  }

  // ── AI ─────────────────────────────────────────
  static void aiClassification({
    required String postId,
    required String riskLevel,
    List<String>? topics,
    Duration? latency,
  }) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        aiResult: jsonEncode({
          'postId': postId,
          'riskLevel': riskLevel,
          'topics': topics ?? [],
          if (latency != null) 'latencyMs': latency.inMilliseconds,
        }),
      ),
    );
    _log('AI', {
      'postId': postId,
      'riskLevel': riskLevel,
      if (topics != null) 'topics': topics,
      if (latency != null) 'latencyMs': latency.inMilliseconds,
    });
  }

  // ── Storage ────────────────────────────────────
  static void storageWrite(String table, String id, {bool success = true, String? error}) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        storageWrite: jsonEncode({
          'table': table,
          'id': id,
          'success': success,
          'error': error,
        }),
      ),
    );
    _log(success ? 'STORE_WRITE' : 'STORE_ERR', {
      'table': table,
      'id': id,
      'success': success,
      if (error != null) 'error': error,
    });
  }

  static void storageRead(String table, {int? count, String? error}) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        storageRead: jsonEncode({
          'table': table,
          'count': count,
          'error': error,
        }),
      ),
    );
    _log(error == null ? 'STORE_READ' : 'STORE_ERR', {
      'table': table,
      if (count != null) 'count': count,
      if (error != null) 'error': error,
    });
  }

  // ── WebSocket ───────────────────────────────────
  static void wsEvent(String event, {Map<String, dynamic>? data}) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        websocketEvent: event,
        websocketPayload:
            data == null ? '' : const JsonEncoder.withIndent('  ').convert(data),
        websocketStatus: _inferSocketStatus(event),
      ),
    );
    _log('WS', {
      'event': event,
      if (data != null) ...data,
    });
  }

  // ── Generic ─────────────────────────────────────
  static void info(String tag, String message) {
    _log(tag, {'message': message});
  }

  static void error(String tag, String message, {dynamic exception}) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        errorMessage: exception == null ? message : '$message: $exception',
      ),
    );
    _log('ERROR', {
      'tag': tag,
      'message': message,
      if (exception != null) 'exception': exception.toString(),
    });
  }

  // ── Internal ────────────────────────────────────
  static void _log(String tag, Map<String, dynamic> data) {
    if (!kDebugMode) return;
    final entry = {
      'tag': tag,
      'ts': DateTime.now().toIso8601String(),
      ...data,
    };
    const encoder = JsonEncoder.withIndent('  ');
    debugPrint('┌─[$tag]──────────────────────────');
    debugPrint(encoder.convert(entry));
    debugPrint('└───────────────────────────────────');
  }

  static String _inferSocketStatus(String event) {
    switch (event) {
      case 'connected':
        return 'connected';
      case 'connecting':
        return 'connecting';
      case 'reconnecting':
        return 'reconnecting';
      case 'disconnected':
      case 'max_reconnect_reached':
        return 'disconnected';
      default:
        return BackendDebugStore.instance.state.value.websocketStatus;
    }
  }
}
