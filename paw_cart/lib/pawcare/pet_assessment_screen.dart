
import 'package:flutter/material.dart';
import 'pawcare_service.dart';
import 'pet_assessment_result_screen.dart';

const Color _pink = Color(0xFFFF6F9F);
const Color _cream = Color(0xFFFFFAF7);
const Color _ink = Color(0xFF382B32);
const Color _muted = Color(0xFF8E7D85);

class PetAssessmentScreen extends StatefulWidget {
  const PetAssessmentScreen({super.key, required this.pet});

  final Map<String, dynamic> pet;

  @override
  State<PetAssessmentScreen> createState() => _PetAssessmentScreenState();
}

class _PetAssessmentScreenState extends State<PetAssessmentScreen> {
  List<dynamic> _questions = [];
  final Map<String, String> _answers = {};

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  String get _species =>
      (widget.pet['species'] as String? ?? '').toLowerCase().trim();

  String get _petName {
    final name = (widget.pet['name'] as String? ?? '').trim();
    return name.isEmpty ? 'your pet' : name;
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final questions =
          await PawCareService.getAssessmentQuestions(_species);

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _answers.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final allAnswered = _questions.every((item) {
      final question = Map<String, dynamic>.from(item as Map);
      final id = question['id']?.toString() ?? '';

      return id.isNotEmpty && (_answers[id]?.isNotEmpty ?? false);
    });

    if (!allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer every question before submitting.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await PawCareService.submitAssessment(
        species: _species,
        petName: _petName,
        answers: _answers,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetAssessmentResultScreen(
            petName: _petName,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate assessment: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _petName == 'your pet'
        ? 'Your pet'
        : '${_petName[0].toUpperCase()}${_petName.substring(1)}';

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        title: Text(
          '$displayName’s Assessment',
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _pink),
            )
          : _error != null
              ? _buildError()
              : _questions.isEmpty
                  ? const Center(
                      child: Text('No assessment questions available.'),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(20),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD8E5),
                                      Color(0xFFFFEEF3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Text(
                                  'Let’s understand $_petName a little better. '
                                  'Choose the answer that best describes your pet.',
                                  style: const TextStyle(
                                    color: _ink,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              ...List.generate(_questions.length, (index) {
                                final questionData =
                                    Map<String, dynamic>.from(
                                  _questions[index] as Map,
                                );

                                final id =
                                    questionData['id']?.toString() ?? '';

                                final question =
                                    questionData['question']?.toString() ?? '';

                                final options = List<String>.from(
                                  questionData['options'] ?? const [],
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(17),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFF0E4E9),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'QUESTION ${index + 1}',
                                        style: const TextStyle(
                                          color: _pink,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        question,
                                        style: const TextStyle(
                                          color: _ink,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // One RadioGroup per question.
                                      RadioGroup<String>(
                                        groupValue: _answers[id],
                                        onChanged: (value) {
                                          if (value == null) return;

                                          setState(() {
                                            _answers[id] = value;
                                          });
                                        },
                                        child: Column(
                                          children: options.map((option) {
                                            return RadioListTile<String>(
                                              value: option,
                                              activeColor: _pink,
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                              title: Text(
                                                option,
                                                style: const TextStyle(
                                                  color: _ink,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              const Text(
                                'This questionnaire provides general care '
                                'guidance, not a veterinary diagnosis.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              10,
                              20,
                              16,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _submitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _pink,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Generate my care report'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: _pink,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load the assessment questions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadQuestions,
              style: FilledButton.styleFrom(
                backgroundColor: _pink,
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
