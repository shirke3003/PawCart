import 'package:flutter/material.dart';

const Color _pink = Color(0xFFFF6F9F);
const Color _palePink = Color(0xFFFFE7EF);
const Color _cream = Color(0xFFFFFAF7);
const Color _ink = Color(0xFF382B32);
const Color _muted = Color(0xFF8E7D85);

class PetAssessmentResultScreen extends StatelessWidget {
  const PetAssessmentResultScreen({
    super.key,
    required this.petName,
    required this.result,
  });

  final String petName;
  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final status = result['status']?.toString() ?? 'unknown';
    final report = result['assessment']?.toString() ??
        'The assessment did not return a report.';
    final sources = (result['sources'] as List?) ?? const [];
    final removedClaims = (result['removed_claims'] as List?) ?? const [];

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: const Text('Care Report', style: TextStyle(color: _ink, fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD8E5), Color(0xFFFFEEF3)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🐾', style: TextStyle(fontSize: 34)),
                const SizedBox(height: 8),
                Text(
                  '$petName’s personalised care report',
                  style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  status == 'success'
                      ? 'Your assessment is ready.'
                      : 'Please review the information below carefully.',
                  style: const TextStyle(color: _ink, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            title: 'AI Assessment',
            child: SelectableText(
              report,
              style: const TextStyle(color: _ink, height: 1.65, fontSize: 14),
            ),
          ),
          if (sources.isNotEmpty) ...[
            const SizedBox(height: 14),
            _section(
              title: 'Sources used',
              child: Column(
                children: sources.map((item) {
                  final source = Map<String, dynamic>.from(item as Map);
                  final title = source['title']?.toString() ?? 'Reference';
                  final reference = source['reference']?.toString() ?? '';
                  final sourceName = source['source']?.toString() ?? '';
                  final url = source['url']?.toString() ?? '';
                  final similarity = source['similarity'];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.menu_book_rounded, color: _pink),
                    title: Text('$reference · $title',
                        style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text(
                      [
                        if (sourceName.isNotEmpty) sourceName,
                        if (similarity != null) 'Retrieval similarity: $similarity',
                        if (url.isNotEmpty) url,
                      ].join('\n'),
                      style: const TextStyle(color: _muted, fontSize: 11, height: 1.4),
                    ),
                    isThreeLine: true,
                  );
                }).toList(),
              ),
            ),
          ],
          if (removedClaims.isNotEmpty) ...[
            const SizedBox(height: 14),
            _section(
              title: 'Grounding review',
              child: Text(
                '${removedClaims.length} unsupported claim(s) were removed during validation.',
                style: const TextStyle(color: _muted, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: _palePink,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Text(
              'Important: PawCare AI provides general, knowledge-base-grounded information. '
              'It does not diagnose or replace a qualified veterinarian. Contact a vet '
              'for health concerns or urgent symptoms.',
              style: TextStyle(color: _ink, fontSize: 12, height: 1.55),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == null),
            style: FilledButton.styleFrom(backgroundColor: _pink, foregroundColor: Colors.white),
            child: const Text('Back to PawCare'),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFF0E4E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
