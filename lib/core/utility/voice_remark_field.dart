import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRemarkField extends StatefulWidget {
  final TextEditingController remarkController;
  final bool isLoading;
  final ValueChanged<String?> onAudioChanged;

  const VoiceRemarkField({
    super.key,
    required this.remarkController,
    required this.isLoading,
    required this.onAudioChanged,
  });

  @override
  State<VoiceRemarkField> createState() => _VoiceRemarkFieldState();
}

class _VoiceRemarkFieldState extends State<VoiceRemarkField> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _busy = false;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();

    _positionSub = _player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _durationSub = _player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state == PlayerState.playing;

        if (state == PlayerState.completed) {
          _position = Duration.zero;
        }
      });
    });
  }

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }

  Future<void> _startRecording() async {
    if (_busy || widget.isLoading) return;

    setState(() => _busy = true);

    try {
      final allowed = await _recorder.hasPermission();

      if (!allowed) {
        throw Exception('Microphone permission denied');
      }

      await _player.stop();

      final directory = await getApplicationDocumentsDirectory();

      final path =
          '${directory.path}/remark_${DateTime.now().microsecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
        ),
        path: path,
      );

      if (mounted) {
        setState(() => _isRecording = true);
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopRecording() async {
    if (_busy || !_isRecording) return;

    setState(() => _busy = true);

    try {
      final path = await _recorder.stop();

      if (mounted) {
        setState(() {
          _isRecording = false;
          _audioPath = path;
          _position = Duration.zero;
          _duration = Duration.zero;
        });
      }

      widget.onAudioChanged(path);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _isRecording = false;
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_busy || widget.isLoading || _audioPath == null) return;

    setState(() => _busy = true);

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_position > Duration.zero &&
            (_duration == Duration.zero || _position < _duration)) {
          await _player.resume();
        } else {
          await _player.play(DeviceFileSource(_audioPath!));
        }
      }
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteRecording() async {
    if (_busy || widget.isLoading) return;

    setState(() => _busy = true);

    try {
      await _player.stop();

      final oldPath = _audioPath;

      if (oldPath != null) {
        final file = File(oldPath);

        if (await file.exists()) {
          await file.delete();
        }
      }

      if (mounted) {
        setState(() {
          _audioPath = null;
          _isPlaying = false;
          _position = Duration.zero;
          _duration = Duration.zero;
        });
      }

      widget.onAudioChanged(null);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isLoading || _busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.remarkController,
          enabled: !widget.isLoading,
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Enter your remark here...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.edit_note_rounded,
              color: Colors.blue,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.blue,
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        if (_audioPath == null)
          Row(
            children: [
              Icon(
                Icons.mic_none_rounded,
                color: _isRecording ? Colors.red : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isRecording
                      ? 'Recording voice remark...'
                      : 'Add voice remark',
                  style: TextStyle(
                    fontSize: 13,
                    color: _isRecording ? Colors.red : Colors.black87,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: disabled
                    ? null
                    : (_isRecording ? _stopRecording : _startRecording),
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  size: 18,
                ),
                label: Text(_isRecording ? 'Stop' : 'Record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isRecording ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

        if (_audioPath != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: disabled ? null : _togglePlayback,
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.blue,
                    size: 34,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Slider(
                        min: 0,
                        max: _duration.inMilliseconds > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1,
                        value: _position.inMilliseconds
                            .toDouble()
                            .clamp(
                              0,
                              _duration.inMilliseconds > 0
                                  ? _duration.inMilliseconds.toDouble()
                                  : 1,
                            ),
                        onChanged: disabled
                            ? null
                            : (value) {
                                _player.seek(
                                  Duration(milliseconds: value.round()),
                                );
                              },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(fontSize: 11),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: disabled ? null : _deleteRecording,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    if (_isRecording) {
      _recorder.stop();
    }

    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();

    _recorder.dispose();
    _player.dispose();

    super.dispose();
  }
}
