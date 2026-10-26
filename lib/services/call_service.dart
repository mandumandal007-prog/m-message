import 'package:url_launcher/url_launcher.dart';
import '../core/helpers.dart';

class CallService {
  /// Opens a Jitsi Meet room. Voice = mute video, Video = full.
  static Future<bool> startCall({
    required String chatId,
    required bool video,
    required String chatName,
  }) async {
    final room = Helpers.sanitizeRoomId(chatId);
    final config = video
        ? '#config.startWithVideoMuted=false'
        : '#config.startWithVideoMuted=true&config.startAudioOnly=true';
    final nameParam = Uri.encodeComponent(chatName);
    final url = Uri.parse('https://meet.jit.si/MMessage_$room$config&config.displayName=$nameParam');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      return launchUrl(url, mode: LaunchMode.platformDefault);
    }
    return true;
  }
}
