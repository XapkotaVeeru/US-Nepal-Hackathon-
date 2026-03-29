import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  String _lastTranscript = '';

  bool get isInitialized => _isInitialized;
  String get lastTranscript => _lastTranscript;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    _lastTranscript = '';
    await _speech.listen(
      onResult: (result) {
        _lastTranscript = result.recognizedWords;
        onResult(_lastTranscript);
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<String> stopListening() async {
    await _speech.stop();
    return _lastTranscript;
  }

  bool get isListening => _speech.isListening;

  Future<void> cancel() async {
    await _speech.cancel();
  }

  void dispose() {
    _speech.cancel();
  }
}
