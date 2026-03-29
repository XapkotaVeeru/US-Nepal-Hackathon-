import 'package:flutter/foundation.dart';

@immutable
class BackendDebugState {
  final String endpoint;
  final String method;
  final int? statusCode;
  final String backendHandler;
  final int? executionTimeMs;
  final String rawResponse;
  final String errorMessage;
  final String websocketStatus;
  final String websocketEvent;
  final String websocketPayload;
  final String aiResult;
  final String storageRead;
  final String storageWrite;
  final DateTime updatedAt;

  const BackendDebugState({
    this.endpoint = '',
    this.method = '',
    this.statusCode,
    this.backendHandler = '',
    this.executionTimeMs,
    this.rawResponse = '',
    this.errorMessage = '',
    this.websocketStatus = 'disconnected',
    this.websocketEvent = '',
    this.websocketPayload = '',
    this.aiResult = '',
    this.storageRead = '',
    this.storageWrite = '',
    required this.updatedAt,
  });

  factory BackendDebugState.initial() =>
      BackendDebugState(updatedAt: DateTime.now());

  BackendDebugState copyWith({
    String? endpoint,
    String? method,
    int? statusCode,
    bool clearStatusCode = false,
    String? backendHandler,
    int? executionTimeMs,
    bool clearExecutionTime = false,
    String? rawResponse,
    String? errorMessage,
    String? websocketStatus,
    String? websocketEvent,
    String? websocketPayload,
    String? aiResult,
    String? storageRead,
    String? storageWrite,
    DateTime? updatedAt,
  }) {
    return BackendDebugState(
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      statusCode: clearStatusCode ? null : (statusCode ?? this.statusCode),
      backendHandler: backendHandler ?? this.backendHandler,
      executionTimeMs:
          clearExecutionTime ? null : (executionTimeMs ?? this.executionTimeMs),
      rawResponse: rawResponse ?? this.rawResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      websocketStatus: websocketStatus ?? this.websocketStatus,
      websocketEvent: websocketEvent ?? this.websocketEvent,
      websocketPayload: websocketPayload ?? this.websocketPayload,
      aiResult: aiResult ?? this.aiResult,
      storageRead: storageRead ?? this.storageRead,
      storageWrite: storageWrite ?? this.storageWrite,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class BackendDebugStore {
  BackendDebugStore._();

  static final BackendDebugStore instance = BackendDebugStore._();
  final ValueNotifier<BackendDebugState> state =
      ValueNotifier<BackendDebugState>(BackendDebugState.initial());

  void update(BackendDebugState nextState) {
    state.value = nextState;
  }
}
