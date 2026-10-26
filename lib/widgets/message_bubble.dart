import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/helpers.dart';
import '../models/message.dart';
import 'audio_player_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final String currentUserName;
  final void Function() onReply;
  final void Function() onCopy;
  final void Function() onEdit;
  final void Function() onDelete;
  final void Function(String emoji) onReact;
  final void Function(MessageReply reply)? onTapReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.currentUserName,
    required this.onReply,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onReact,
    this.onTapReply,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (message.deleted) {
      return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.block, size: 16, color: scheme.outline),
              const SizedBox(width: 6),
              Text('This message was deleted',
                  style: TextStyle(color: scheme.outline, fontStyle: FontStyle.italic)),
            ]),
          ),
        ),
      );
    }

    final bubbleColor = isMine ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final onBubble = isMine ? scheme.onPrimaryContainer : scheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        child: GestureDetector(
          onLongPress: () => _showMenu(context),
          child: Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMine ? 18 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.replyTo != null) _replyPreview(context, message.replyTo!, onBubble),
                      _buildContent(context, onBubble),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.edited)
                            Text('edited ',
                                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: onBubble.withValues(alpha: 0.7))),
                          Text(
                            message.createdAt != null ? Helpers.formatTime(message.createdAt!) : '',
                            style: TextStyle(fontSize: 11, color: onBubble.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Wrap(
                    spacing: 4,
                    children: message.reactions.entries
                        .where((e) => e.value.isNotEmpty)
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: scheme.outlineVariant, width: 0.5),
                              ),
                              child: Text('${e.key} ${e.value.length}', style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _replyPreview(BuildContext context, MessageReply reply, Color color) {
    return GestureDetector(
      onTap: onTapReply == null ? null : () => onTapReply!(reply),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border(left: BorderSide(color: color.withValues(alpha: 0.6), width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reply', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 2),
            Text(
              reply.type == 'text' ? reply.text : '[${reply.type}]',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Color onBubble) {
    switch (message.type) {
      case 'image':
        return GestureDetector(
          onTap: () {
            if (message.mediaUrl == null) return;
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => Scaffold(
                backgroundColor: Colors.black,
                body: SafeArea(
                  child: Stack(children: [
                    PhotoView(imageProvider: CachedNetworkImageProvider(message.mediaUrl!)),
                    Positioned(
                      top: 8, left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ]),
                ),
              ),
            ));
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl ?? '',
              width: 220,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox(height: 150, width: 220, child: Center(child: CircularProgressIndicator())),
              errorWidget: (_, __, ___) => const SizedBox(
                height: 100, width: 200,
                child: Icon(Icons.broken_image),
              ),
            ),
          ),
        );

      case 'file':
        return InkWell(
          onTap: () async {
            if (message.mediaUrl == null) return;
            final uri = Uri.parse(message.mediaUrl!);
            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
              await launchUrl(uri);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: onBubble),
              const SizedBox(width: 8),
              Flexible(
                child: Text(message.fileName ?? 'File',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: onBubble, decoration: TextDecoration.underline)),
              ),
            ],
          ),
        );

      case 'audio':
        return AudioPlayerWidget(url: message.mediaUrl ?? '', durationSec: message.durationSec ?? 0, color: onBubble);

      default:
        return Text(message.text, style: TextStyle(color: onBubble, fontSize: 15, height: 1.3));
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: ['❤️', '😂', '😮', '😢', '👍', '🔥', '🎉', '🙏']
                  .map((e) => InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          onReact(e);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(e, style: const TextStyle(fontSize: 26)),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () { Navigator.pop(ctx); onReply(); },
          ),
          if (message.type == 'text')
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () { Navigator.pop(ctx); onCopy(); },
            ),
          if (isMine && message.type == 'text')
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () { Navigator.pop(ctx); onEdit(); },
            ),
          if (isMine)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () { Navigator.pop(ctx); onDelete(); },
            ),
        ]),
      ),
    );
  }
}
