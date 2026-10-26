import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/helpers.dart';
import '../models/status.dart';
import '../providers/auth_provider.dart';
import '../services/status_service.dart';
import '../widgets/common.dart';

class StatusViewerScreen extends StatefulWidget {
  final List<Status> statuses;
  final int initialIndex;
  const StatusViewerScreen({super.key, required this.statuses, this.initialIndex = 0});

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  static const _duration = Duration(seconds: 6);
  static const _tick = Duration(milliseconds: 50);

  final _service = StatusService();
  late int _index;
  double _progress = 0;
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.statuses.length - 1);
    _onShown();
    _timer = Timer.periodic(_tick, (_) {
      if (_paused || !mounted) return;
      setState(() => _progress += _tick.inMilliseconds / _duration.inMilliseconds);
      if (_progress >= 1) _next();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _uid => context.read<AuthProvider>().firebaseUser?.uid ?? '';

  void _onShown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final s = widget.statuses[_index];
      if (s.userId != _uid && !s.viewers.contains(_uid)) {
        _service.markViewed(s.id, _uid).catchError((_) {});
      }
    });
  }

  void _next() {
    if (_index < widget.statuses.length - 1) {
      setState(() {
        _index++;
        _progress = 0;
      });
      _onShown();
    } else {
      _timer?.cancel();
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    setState(() {
      if (_index > 0) _index--;
      _progress = 0;
    });
    _onShown();
  }

  Color _parseColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF4D6BFE);
  }

  Future<void> _delete(Status s) async {
    setState(() => _paused = true);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete status?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) {
      await _service.deleteStatus(s.id);
      if (mounted) Navigator.pop(context);
    } else {
      setState(() => _paused = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.statuses[_index];
    final isMine = s.userId == _uid;
    final isImage = s.type == 'image' && s.imageUrl != null;

    return Scaffold(
      backgroundColor: isImage ? Colors.black : _parseColor(s.backgroundColor),
      body: GestureDetector(
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          if (d.localPosition.dx < w / 3) {
            _prev();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => setState(() => _paused = true),
        onLongPressEnd: (_) => setState(() => _paused = false),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isImage)
              CachedNetworkImage(
                imageUrl: s.imageUrl!,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    s.text ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
              ),
            if (isImage && (s.text ?? '').isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Text(s.text!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: List.generate(widget.statuses.length, (i) {
                        final v = i < _index ? 1.0 : (i == _index ? _progress.clamp(0.0, 1.0) : 0.0);
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value: v,
                              minHeight: 3,
                              backgroundColor: Colors.white30,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  ListTile(
                    leading: UserAvatar(name: s.userName, photoUrl: s.userPhoto),
                    title: Text(isMine ? 'My status' : s.userName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(s.createdAt != null ? Helpers.relative(s.createdAt!) : '',
                        style: const TextStyle(color: Colors.white70)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (isMine)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: () => _delete(s),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ]),
                  ),
                  const Spacer(),
                  if (isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.visibility_outlined, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Text('${s.viewers.length} views', style: const TextStyle(color: Colors.white70)),
                      ]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
