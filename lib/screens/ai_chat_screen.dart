import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/settings_provider.dart';
import '../services/ai_service.dart';
import '../widgets/common.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _ai = AiService();
  final _ctl = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _history = []; // {role, content}
  bool _thinking = false;

  static const _systemPrompt =
      'You are ${AppConstants.aiBotName}, a friendly and helpful assistant inside the M Message app. '
      'Answer clearly and concisely. Reply in the same language the user writes in.';

  @override
  void dispose() {
    _ctl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _thinking) return;
    final settings = context.read<SettingsProvider>();
    if (!settings.hasAiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add your AI API key in Settings → AI assistant')),
      );
      return;
    }
    _ctl.clear();
    setState(() {
      _history.add({'role': 'user', 'content': text});
      _thinking = true;
    });
    _toBottom();
    final recent = _history.length > 20 ? _history.sublist(_history.length - 20) : List<Map<String, String>>.from(_history);
    final reply = await _ai.generateReply(
      apiKey: settings.aiKey,
      provider: settings.aiProvider,
      history: recent,
      systemPrompt: _systemPrompt,
    );
    if (!mounted) return;
    setState(() {
      _history.add({'role': 'assistant', 'content': reply});
      _thinking = false;
    });
    _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: scheme.tertiaryContainer,
            child: Icon(Icons.auto_awesome, size: 18, color: scheme.onTertiaryContainer),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(AppConstants.aiBotName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            Text(settings.aiProvider == 'openai' ? 'OpenAI' : 'DeepSeek', style: TextStyle(fontSize: 12, color: scheme.outline)),
          ]),
        ]),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              tooltip: 'Clear chat',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => setState(_history.clear),
            ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _history.isEmpty
              ? EmptyState(
                  icon: Icons.auto_awesome,
                  title: 'Ask ${AppConstants.aiBotName} anything',
                  subtitle: settings.hasAiKey ? 'Your messages go to ${settings.aiProvider == 'openai' ? 'OpenAI' : 'DeepSeek'} with your own key.' : 'First add your API key in Settings → AI assistant.',
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _history.length + (_thinking ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _history.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                      );
                    }
                    final m = _history[i];
                    final mine = m['role'] == 'user';
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: m['content'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: SelectableText(
                            m['content'] ?? '',
                            style: TextStyle(color: mine ? scheme.onPrimaryContainer : scheme.onSurface, fontSize: 15, height: 1.35),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctl,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(hintText: 'Message ${AppConstants.aiBotName}'),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: _thinking ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
