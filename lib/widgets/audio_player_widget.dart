import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../core/helpers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final int durationSec;
  final Color color;
  const AudioPlayerWidget({super.key, required this.url, required this.durationSec, required this.color});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _total = Duration(seconds: widget.durationSec);
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onDurationChanged.listen((d) => setState(() => _total = d));
    _player.onPlayerComplete.listen((_) => setState(() {
      _playing = false;
      _position = Duration.zero;
    }));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _total.inMilliseconds > 0
        ? _position.inMilliseconds / _total.inMilliseconds
        : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: widget.color, size: 34),
          onPressed: () async {
            if (_playing) {
              await _player.pause();
              setState(() => _playing = false);
            } else {
              await _player.play(UrlSource(widget.url));
              setState(() => _playing = true);
            }
          },
        ),
        SizedBox(
          width: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: widget.color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(widget.color),
                minHeight: 3,
              ),
              const SizedBox(height: 4),
              Text(
                '${Helpers.shortDuration(_position)} / ${Helpers.shortDuration(_total)}',
                style: TextStyle(fontSize: 11, color: widget.color.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
