import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DailyTipScreen extends StatelessWidget {
  final Map<String, dynamic> tip;

  const DailyTipScreen({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    final title = tip['title'] ?? 'Daily Nutrition Tip';
    final overview = tip['overview'] ?? '';
    final details = tip['details'] ?? '';
    final actionSteps = List<String>.from(tip['actionSteps'] ?? []);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E3E5C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daily Tip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3E5C),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    overview,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Overview',
              style: TextStyle(
                color: Color(0xFF2E3E5C),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              details,
              style: const TextStyle(
                color: Color(0xFF5E6D8C),
                fontSize: 15,
                height: 1.55,
              ),
            ),
            if (actionSteps.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Try This Today',
                style: TextStyle(
                  color: Color(0xFF2E3E5C),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...actionSteps.asMap().entries.map(
                (entry) => _ActionStep(
                  number: entry.key + 1,
                  text: entry.value,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionStep extends StatelessWidget {
  final int number;
  final String text;

  const _ActionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2E3E5C),
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
