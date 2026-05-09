import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nutri_snap/utils/secrets.dart';

void main() {
  test('Find working Gemini model', () async {
    final apiKey = Secrets.geminiApiKey;
    print('\n\n========== STARTING MODEL CHECK ==========\n');

    final modelNames = [
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-pro',
      'gemini-1.0-pro',
      'gemini-pro',
    ];

    bool found = false;

    for (final name in modelNames) {
      print('>>> Trying model: "$name"');
      try {
        final model = GenerativeModel(model: name, apiKey: apiKey);
        // Minimal token request
        final response = await model.generateContent([Content.text('Hi')]);
        print(
          '✅ SUCCESS: "$name" IS WORKING! Response: ${response.text?.substring(0, 5)}...\n',
        );
        found = true;
        // Keep checking others just to see? No, just stop at first success to be fast.
        break;
      } catch (e) {
        print('❌ FAILED: "$name". Error: $e\n');
      }
    }

    print('========== END MODEL CHECK ==========\n\n');
    if (!found) {
      fail('NO WORKING MODELS FOUND for this API Key.');
    }
  });
}
