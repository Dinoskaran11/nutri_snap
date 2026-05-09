import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/secrets.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // Reverting to gemini-pro as 1.5-flash is consistently failing with v1beta error
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Secrets.geminiApiKey,
    );
  }

  Future<String?> analyzeNutrition(String ingredientsText) async {
    final prompt =
        '''
    Analyze the following food ingredients list from a scanned product label:
    "$ingredientsText"

    Return ONLY a valid JSON object with the following structure (no markdown formatting, just plain JSON):
    {
      "productName": "Inferred product name or 'Unknown Product'",
      "tags": ["Tag1", "Tag2"], (e.g., Vegan, Gluten-Free, High Sugar, Processed. Max 3 tags.),
      "nutritionQualityScore": "A", (Score from A to E, where A is healthiest),
      "nutritionQualityDescription": "Short verdict (e.g., Healthy in moderation).",
      "nutrients": [
        {"label": "Fat / Lipid", "value": "10 g"},
        {"label": "Sugar", "value": "5 g"},
        {"label": "Sat. Fats", "value": "2 g"},
        {"label": "Salt", "value": "0.1 g"}
      ], (Estimate values per serving if possible, or leave generic),
      "analysisSummary": "A short 2-3 sentence summary of the health content and any healthier alternatives."
    }
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      // Strip any markdown code blocks if the model adds them
      String? cleanResponse = response.text
          ?.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return cleanResponse;
    } catch (e) {
      // Log the error but return null so the UI knows it failed, or return the error string starting with Error
      print("Error analyzing nutrition: $e");
      return "Error: $e";
    }
  }

  Future<String?> chatWithNutriBot(String message) async {
    // Basic chat implementation
    try {
      final prompt =
          "You are NutriBot, a helpful AI nutritionist assistant. Answer the following question: $message";
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      return "I'm having trouble connecting. Please try again.";
    }
  }

  Future<String?> getDailyTip() async {
    const prompt =
        '''
    Create one daily nutrition tip for a food label scanning app.

    Return ONLY a valid JSON object with this exact shape:
    {
      "title": "Short tip title",
      "overview": "One short sentence shown on the dashboard.",
      "details": "A clear explanation in 2 short paragraphs.",
      "actionSteps": ["Step 1", "Step 2", "Step 3"]
    }

    Make it actionable, safe for general wellness, and related to shopping, scanning labels, ingredients, hydration, balanced meals, or healthier swaps.
    ''';
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text
          ?.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
    } catch (e) {
      return jsonEncode(_fallbackDailyTip());
    }
  }

  Map<String, dynamic> parseDailyTip(String? rawTip) {
    if (rawTip == null || rawTip.trim().isEmpty) {
      return _fallbackDailyTip();
    }

    try {
      final parsed = jsonDecode(rawTip.trim()) as Map<String, dynamic>;
      return {
        'title': parsed['title'] ?? 'Daily Nutrition Tip',
        'overview': parsed['overview'] ?? 'Scan labels and choose foods with simple ingredients.',
        'details':
            parsed['details'] ??
            'A quick label scan can help you compare products before you buy. Look for foods with recognizable ingredients and reasonable amounts of sugar, sodium, and saturated fat.',
        'actionSteps': List<String>.from(
          parsed['actionSteps'] ??
              [
                'Scan the label before buying.',
                'Compare sugar, sodium, and saturated fat.',
                'Pick the simpler option when possible.',
              ],
        ),
      };
    } catch (_) {
      return {
        ..._fallbackDailyTip(),
        'overview': rawTip.trim(),
      };
    }
  }

  Map<String, dynamic> _fallbackDailyTip() {
    return {
      'title': 'Read The Ingredient List',
      'overview': 'Choose products with shorter ingredient lists when you can.',
      'details':
          'A shorter ingredient list is often easier to understand and compare. It does not automatically make a food healthy, but it helps you spot added sugars, excess sodium, and highly processed additives more quickly.\n\nWhen two similar products look the same, scan both labels and choose the one with better nutrients and ingredients that match your goals.',
      'actionSteps': [
        'Scan similar products before choosing one.',
        'Check sugar, sodium, and saturated fat first.',
        'Prefer recognizable ingredients for everyday foods.',
      ],
    };
  }
}
