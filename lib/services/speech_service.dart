import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  bool _sessionActive = false;
  bool _manualStopRequested = false;
  bool _restartInFlight = false;

  String _accumulatedTranscript = '';
  String _currentSegmentTranscript = '';
  String _lastTranscript = '';

  void Function(String)? _onResult;

  bool get isInitialized => _isInitialized;
  String get lastTranscript => _lastTranscript;
  bool get isListening => _sessionActive;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (_) {
        if (_sessionActive && !_manualStopRequested) {
          _restartAfterPause();
        }
      },
      onStatus: _handleStatus,
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required void Function(String) onResult,
    bool resetTranscript = true,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    _onResult = onResult;
    _manualStopRequested = false;
    _sessionActive = true;

    if (resetTranscript) {
      _accumulatedTranscript = '';
      _currentSegmentTranscript = '';
      _lastTranscript = '';
    }

    await _beginListeningCycle();
  }

  Future<String> stopListening() async {
    _manualStopRequested = true;
    _sessionActive = false;
    _commitCurrentSegment();
    if (_speech.isListening) {
      await _speech.stop();
    }
    return _lastTranscript.trim();
  }

  Future<void> cancel() async {
    _manualStopRequested = true;
    _sessionActive = false;
    _accumulatedTranscript = '';
    _currentSegmentTranscript = '';
    _lastTranscript = '';
    await _speech.cancel();
  }

  void dispose() {
    _manualStopRequested = true;
    _sessionActive = false;
    _speech.cancel();
  }

  Future<void> _beginListeningCycle() async {
    if (_speech.isListening) return;

    _currentSegmentTranscript = '';
    await _speech.listen(
      onResult: _handleResult,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      ),
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords.trim();
    if (recognized.isEmpty) return;

    if (result.finalResult) {
      _accumulatedTranscript = _mergeTranscript(
        _accumulatedTranscript,
        recognized,
      );
      _currentSegmentTranscript = '';
      _lastTranscript = _accumulatedTranscript;
      _onResult?.call(_lastTranscript);
      return;
    }

    _currentSegmentTranscript = recognized;
    _lastTranscript = _mergeTranscript(
      _accumulatedTranscript,
      _currentSegmentTranscript,
    );
    _onResult?.call(_lastTranscript);
  }

  void _handleStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('done') || normalized.contains('notlistening')) {
      _commitCurrentSegment();

      if (_sessionActive && !_manualStopRequested) {
        _restartAfterPause();
      }
    }
  }

  void _commitCurrentSegment() {
    if (_currentSegmentTranscript.trim().isEmpty) {
      _lastTranscript = _accumulatedTranscript.trim();
      return;
    }

    _accumulatedTranscript = _mergeTranscript(
      _accumulatedTranscript,
      _currentSegmentTranscript,
    );
    _currentSegmentTranscript = '';
    _lastTranscript = _accumulatedTranscript.trim();
    _onResult?.call(_lastTranscript);
  }

  Future<void> _restartAfterPause() async {
    if (_restartInFlight || !_sessionActive || _manualStopRequested) return;
    _restartInFlight = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!_sessionActive || _manualStopRequested || _speech.isListening) {
        return;
      }
      await _beginListeningCycle();
    } finally {
      _restartInFlight = false;
    }
  }

  String _mergeTranscript(String base, String incoming) {
    final normalizedBase = _normalize(base);
    final normalizedIncoming = _normalize(incoming);

    if (normalizedBase.isEmpty) return normalizedIncoming;
    if (normalizedIncoming.isEmpty) return normalizedBase;
    if (normalizedBase == normalizedIncoming) return normalizedBase;
    if (normalizedIncoming.startsWith(normalizedBase)) {
      return normalizedIncoming;
    }
    if (normalizedBase.endsWith(normalizedIncoming)) {
      return normalizedBase;
    }
    if (normalizedIncoming.contains(normalizedBase)) {
      return normalizedIncoming;
    }
    if (normalizedBase.contains(normalizedIncoming)) {
      return normalizedBase;
    }

    final baseWords = normalizedBase.split(' ');
    final incomingWords = normalizedIncoming.split(' ');
    final maxOverlap =
        baseWords.length < incomingWords.length ? baseWords.length : incomingWords.length;

    for (var overlap = maxOverlap; overlap > 0; overlap--) {
      final baseSuffix = baseWords.skip(baseWords.length - overlap).join(' ');
      final incomingPrefix = incomingWords.take(overlap).join(' ');
      if (baseSuffix == incomingPrefix) {
        return [
          ...baseWords,
          ...incomingWords.skip(overlap),
        ].join(' ');
      }
    }

    return '$normalizedBase $normalizedIncoming';
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
