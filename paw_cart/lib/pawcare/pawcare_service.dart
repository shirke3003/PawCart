
import 'dart:convert';
import 'package:http/http.dart' as http;

class PawCareService {
  // Temporary development URL.
  // We will replace this with your Mac's local IP for phone testing.
  static const String baseUrl = 'http://192.168.29.82:8000';

  static const Duration timeout = Duration(seconds: 60);

  /// Checks whether the PawCare backend is running.
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(timeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Fetches species-specific assessment questions.
  static Future<List<dynamic>> getAssessmentQuestions(
    String species,
  ) async {
    final normalizedSpecies = species.toLowerCase().trim();

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/api/assessment/questions/$normalizedSpecies',
          ),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Could not load assessment questions: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is List) {
      return data;
    }

    if (data is Map && data['questions'] is List) {
      return List<dynamic>.from(data['questions']);
    }

    throw Exception('Unexpected assessment question response.');
  }

  /// Submits MCQ answers and receives a personalised assessment.
  static Future<Map<String, dynamic>> submitAssessment({
    required String species,
    required String petName,
    required Map<String, String> answers,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/assessment'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'species': species.toLowerCase().trim(),
            'pet_name': petName,
            'answers': answers,
          }),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Assessment failed: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected assessment response.');
    }

    return data;
  }

  /// Sends an open-ended pet-care question to PawCare AI.
  static Future<Map<String, dynamic>> sendChatMessage({
    required String question,
    required String species,
    String? petName,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'question': question,
            'species': species.toLowerCase().trim(),
            'pet_name': petName,
          }),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Could not get an AI response: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected chat response.');
    }

    return data;
  }
}
