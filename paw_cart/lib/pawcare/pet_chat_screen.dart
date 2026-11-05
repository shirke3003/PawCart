import 'package:flutter/material.dart';
import 'pawcare_service.dart';

const Color _pink = Color(0xFFFF6F9F);
const Color _palePink = Color(0xFFFFE7EF);
const Color _cream = Color(0xFFFFFAF7);
const Color _ink = Color(0xFF382B32);
const Color _muted = Color(0xFF8E7D85);

class PetChatScreen extends StatefulWidget {
  const PetChatScreen({super.key, required this.pet});

  final Map<String, dynamic> pet;

  @override
  State<PetChatScreen> createState() => _PetChatScreenState();
}

class _PetChatScreenState extends State<PetChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _sending = false;

  String get _species => (widget.pet['species'] as String? ?? '').toLowerCase().trim();
  String get _petName => widget.pet['name'] as String? ?? 'your pet';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _sending) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _sending = true;
    });
    _scrollToBottom();

    try {
      final result = await PawCareService.sendChatMessage(
        question: question,
        species: _species,
        petName: _petName,
      );
      if (!mounted) return;
      final answer = result['answer']?.toString() ??
          'PawCare AI did not return an answer.';
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': answer,
          'status': result['status']?.toString() ?? '',
          'sources': (result['sources'] as List?) ?? const [],
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'I could not reach PawCare AI just now. Please try again.\n\n$e',
          'sources': const [],
        });
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: Text('Ask about $_petName 🐾',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w900)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🐾', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Hi! What would you like to know about $_petName?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ask about everyday nutrition, hygiene, behaviour or care.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_sending && index == _messages.length) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: _pink),
                          ),
                        );
                      }
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      final sources = (message['sources'] as List?) ?? const [];
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 650),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isUser ? _palePink : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFF0E4E9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                message['text']?.toString() ?? '',
                                style: const TextStyle(color: _ink, height: 1.55, fontSize: 13),
                              ),
                              if (!isUser && sources.isNotEmpty) ...[
                                const Divider(height: 22),
                                const Text('Sources',
                                    style: TextStyle(color: _pink, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 5),
                                ...sources.map((item) {
                                  final source = Map<String, dynamic>.from(item as Map);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Text(
                                      '${source['reference'] ?? ''} · ${source['title'] ?? 'Reference'}'
                                      '${source['url'] == null ? '' : '\n${source['url']}'}',
                                      style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask PawCare AI...',
                        filled: true,
                        fillColor: _cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(backgroundColor: _pink, foregroundColor: Colors.white),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
