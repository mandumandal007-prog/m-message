import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../core/helpers.dart';

class VoiceRecorderSheet extends StatefulWidget {
  const VoiceRecorderSheet({super.key});

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  final _recorder = AudioRecorder();
  final _stopwatch = Stopwatch();
  Timer? _timer;
  bool _recording = false;
  String? _path;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required')));
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: _path!);
    _stopwatch.reset();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => setState(() {}));
    setState(() => _recording = true);
  }

  Future<void> _stop({bool send = false}) async {
    _timer?.cancel();
    _stopwatch.stop();
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (!mounted) return;
    if (send && path != null) {
      Navigator.pop(context, {'file': File(path), 'duration': _stopwatch.elapsed.inSeconds});
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_recording ? 'Recording…' : 'Voice Message',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          Text(
            Helpers.shortDuration(_stopwatch.elapsed),
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w300, color: scheme.primary),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_recording) ...[
                IconButton.filledTonal(
                  onPressed: () => _stop(send: false),
                  iconSize: 32,
                  icon: const Icon(Icons.close),
                ),
                const SizedBox(width: 32),
                IconButton.filled(
                  onPressed: () => _stop(send: true),
                  iconSize: 48,
                  icon: const Icon(Icons.send),
                ),
              ] else
                IconButton.filled(
                  onPressed: _start,
                  iconSize: 64,
                  icon: const Icon(Icons.mic),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
