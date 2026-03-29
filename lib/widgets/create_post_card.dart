import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/check_in_model.dart';
import '../providers/post_provider.dart';
import '../services/speech_service.dart';

class CreatePostCard extends StatefulWidget {
  final String anonymousId;
  final bool isSubmitting;

  const CreatePostCard({
    super.key,
    required this.anonymousId,
    this.isSubmitting = false,
  });

  @override
  State<CreatePostCard> createState() => _CreatePostCardState();
}

class _CreatePostCardState extends State<CreatePostCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SpeechService _speechService = SpeechService();

  bool _consentGiven = false;
  bool _showGuidelines = true;
  bool _isListening = false;
  String? _voiceError;
  CheckInInputMode _inputMode = CheckInInputMode.text;

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _speechService.dispose();
    super.dispose();
  }

  int get _characterCount => _controller.text.trim().length;

  bool get _isValid =>
      _characterCount >= 20 && _characterCount <= 2000 && _consentGiven;

  Future<void> _toggleVoiceCapture() async {
    if (_isListening) {
      final transcript = await _speechService.stopListening();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        if (transcript.trim().isEmpty) {
          _voiceError = 'Could not capture speech. Try again with a longer check-in.';
        } else {
          _voiceError = null;
          _controller.text = transcript.trim();
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
      });
      return;
    }

    final initialized = await _speechService.initialize();
    if (!initialized) {
      if (!mounted) return;
      setState(() {
        _voiceError = 'Speech recognition is not available on this device.';
      });
      return;
    }

    setState(() {
      _inputMode = CheckInInputMode.voice;
      _isListening = true;
      _voiceError = null;
      _controller.clear();
    });

    await _speechService.startListening(
      onResult: (transcript) {
        if (!mounted) return;
        setState(() {
          _controller.text = transcript;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );
  }

  void _submitPost() {
    if (!_isValid || widget.isSubmitting) return;

    _focusNode.unfocus();

    context.read<PostProvider>().submitPost(
          anonymousId: widget.anonymousId,
          content: _controller.text,
          inputMode: _inputMode,
          captureSource: _inputMode == CheckInInputMode.voice
              ? 'speech_to_text'
              : 'typed',
          transcript:
              _inputMode == CheckInInputMode.voice ? _controller.text : null,
        );

    _controller.clear();
    setState(() {
      _consentGiven = false;
      _isListening = false;
      _voiceError = null;
      _inputMode = CheckInInputMode.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (_showGuidelines)
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Important Information',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _showGuidelines = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• This is peer support, not professional therapy\n'
                    '• Your check-in stays anonymous\n'
                    '• We analyze emotions, intensity, and themes to find better support\n'
                    '• If risk looks elevated, we surface safer next steps first',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'How are you feeling?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use text or voice. We\'ll run one emotional check-in flow and suggest people and communities that fit what you shared.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                SegmentedButton<CheckInInputMode>(
                  segments: const [
                    ButtonSegment(
                      value: CheckInInputMode.text,
                      icon: Icon(Icons.keyboard_alt_outlined),
                      label: Text('Text'),
                    ),
                    ButtonSegment(
                      value: CheckInInputMode.voice,
                      icon: Icon(Icons.mic_none_rounded),
                      label: Text('Voice'),
                    ),
                  ],
                  selected: {_inputMode},
                  onSelectionChanged: widget.isSubmitting
                      ? null
                      : (selection) {
                          setState(() {
                            _inputMode = selection.first;
                            _voiceError = null;
                          });
                        },
                ),
                const SizedBox(height: 16),
                if (_inputMode == CheckInInputMode.voice) ...[
                  _buildVoiceCapturePanel(context),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 6,
                  minLines: 3,
                  maxLength: 2000,
                  enabled: !widget.isSubmitting,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: _inputMode == CheckInInputMode.voice
                        ? 'Transcript / editable check-in'
                        : 'Text check-in',
                    hintText: _inputMode == CheckInInputMode.voice
                        ? 'Tap the mic, speak naturally, then review what was captured here...'
                        : 'I feel overwhelmed with studies and don\'t know how to handle the pressure...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    counterText: '$_characterCount / 2000 (min 20)',
                    counterStyle: TextStyle(
                      color: _characterCount < 20
                          ? colorScheme.error
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: widget.isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _consentGiven = !_consentGiven;
                          });
                        },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _consentGiven,
                          onChanged: widget.isSubmitting
                              ? null
                              : (value) {
                                  setState(() {
                                    _consentGiven = value ?? false;
                                  });
                                },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _inputMode == CheckInInputMode.voice
                                  ? 'I understand my voice transcript will be used to analyze emotions and match support'
                                  : 'I understand my text will be used to analyze emotions and match support',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'We use your anonymous check-in to generate emotion labels, intensity, tags, and support recommendations.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.outline,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      _isValid && !widget.isSubmitting ? _submitPost : null,
                  icon: widget.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _inputMode == CheckInInputMode.voice
                              ? Icons.graphic_eq_rounded
                              : Icons.send_rounded,
                        ),
                  label: Text(
                    widget.isSubmitting
                        ? 'Understanding your check-in...'
                        : 'Share and Find Support',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (!_isValid && !widget.isSubmitting)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _characterCount < 20
                          ? 'Share at least 20 characters so we can understand your check-in'
                          : !_consentGiven
                              ? 'Please confirm consent above'
                              : '',
                      style: TextStyle(
                        color: colorScheme.error.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceCapturePanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                ),
                child: Icon(
                  _isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                  color: _isListening
                      ? Colors.white
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isListening ? 'Listening...' : 'Voice check-in',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap the mic, speak naturally, then review the transcript before sharing.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: widget.isSubmitting ? null : _toggleVoiceCapture,
            icon: Icon(_isListening ? Icons.stop_circle_outlined : Icons.mic),
            label: Text(_isListening ? 'Stop recording' : 'Start recording'),
          ),
          if (_voiceError != null) ...[
            const SizedBox(height: 10),
            Text(
              _voiceError!,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
