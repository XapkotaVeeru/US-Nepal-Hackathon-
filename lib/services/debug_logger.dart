import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'backend_debug_store.dart';

/// Structured debug logger for API / WebSocket / Lambda diagnostics.
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
    String lambdaFunction = headers?['x-lambda-function'] ?? '';
    try {
      parsedBody = jsonDecode(body);
      if (parsedBody is Map<String, dynamic>) {
        lambdaFunction = (parsedBody['lambdaFunction'] as String?) ?? lambdaFunction;
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
        lambdaFunction: lambdaFunction,
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

  // ── Lambda ──────────────────────────────────────
  static void lambdaResult(String functionName, {
    String? riskLevel,
    String? matchId,
    int? statusCode,
    String? error,
  }) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        lambdaFunction: functionName,
        statusCode: statusCode,
        errorMessage: error ?? BackendDebugStore.instance.state.value.errorMessage,
      ),
    );
    _log('LAMBDA', {
      'function': functionName,
      if (riskLevel != null) 'riskLevel': riskLevel,
      if (matchId != null) 'matchId': matchId,
      if (statusCode != null) 'statusCode': statusCode,
      if (error != null) 'error': error,
    });
  }

  // ── Bedrock AI ──────────────────────────────────
  static void bedrockClassification({
    required String postId,
    required String riskLevel,
    List<String>? topics,
    Duration? latency,
  }) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        bedrockResult: jsonEncode({
          'postId': postId,
          'riskLevel': riskLevel,
          'topics': topics ?? [],
          if (latency != null) 'latencyMs': latency.inMilliseconds,
        }),
      ),
    );
    _log('BEDROCK', {
      'postId': postId,
      'riskLevel': riskLevel,
      if (topics != null) 'topics': topics,
      if (latency != null) 'latencyMs': latency.inMilliseconds,
    });
  }

  // ── DynamoDB ────────────────────────────────────
  static void dynamoWrite(String table, String id, {bool success = true, String? error}) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        dynamoWrite: jsonEncode({
          'table': table,
          'id': id,
          'success': success,
          'error': error,
        }),
      ),
    );
    _log(success ? 'DDB_WRITE' : 'DDB_ERR', {
      'table': table,
      'id': id,
      'success': success,
      if (error != null) 'error': error,
    });
  }

  static void dynamoRead(String table, {int? count, String? error}) {
    BackendDebugStore.instance.update(
      BackendDebugStore.instance.state.value.copyWith(
        dynamoRead: jsonEncode({
          'table': table,
          'count': count,
          'error': error,
        }),
      ),
    );
    _log(error == null ? 'DDB_READ' : 'DDB_ERR', {
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
