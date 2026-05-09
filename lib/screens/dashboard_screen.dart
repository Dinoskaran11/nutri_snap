import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';
import 'camera_screen.dart';
import 'daily_tip_screen.dart';
import 'favorites_screen.dart';
import 'result_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GeminiService _geminiService = GeminiService();
  Map<String, dynamic> _dailyTip = {
    'title': 'Daily Tip',
    'overview': "Loading today's tip...",
    'details': '',
    'actionSteps': <String>[],
  };
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, dynamic>> _favorites = [];
  StorageService? _storage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _loadDailyTip();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storage = context.read<StorageService>();
    if (_storage != storage) {
      _storage?.removeListener(_handleStorageChanged);
      _storage = storage;
      _storage?.addListener(_handleStorageChanged);
    }
  }

  @override
  void dispose() {
    _storage?.removeListener(_handleStorageChanged);
    super.dispose();
  }

  void _handleStorageChanged() {
    _loadData();
  }

  Future<void> _loadDailyTip() async {
    final storage = context.read<StorageService>();
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final cachedTip = await storage.getCachedDailyTip(dateKey);

    if (cachedTip != null) {
      if (mounted) {
        setState(() {
          _dailyTip = cachedTip;
        });
      }
      return;
    }

    final rawTip = await _geminiService.getDailyTip();
    final tip = {
      ..._geminiService.parseDailyTip(rawTip),
      'dateKey': dateKey,
    };
    await storage.saveCachedDailyTip(tip);

    if (mounted) {
      setState(() {
        _dailyTip = tip;
      });
    }
  }

  Future<void> _loadData() async {
    final storage = context.read<StorageService>();
    final history = await storage.getHistory();
    final favorites = await storage.getFavorites();

    if (mounted) {
      setState(() {
        _scanHistory = history;
        _favorites = favorites;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/app_logo.png', height: 24),
            const SizedBox(width: 8),
            const Text(
              'nutrisnap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF2E3E5C),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Color(0xFF2E3E5C)),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActivityCard(
                      'Scanned',
                      _scanHistory.length.toString(),
                      Icons.center_focus_weak,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActivityCard(
                      'Favorites',
                      _favorites.length.toString(),
                      Icons.favorite_border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDailyTipCard(),
              const SizedBox(height: 24),
              Text(
                'Scan History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 16),
              if (_scanHistory.isEmpty)
                _buildEmptyHistory()
              else
                Column(
                  children: _scanHistory
                      .map((scan) => _buildHistoryItem(scan))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTipCard() {
    return Material(
      color: const Color(0xFF4CAF50),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DailyTipScreen(tip: _dailyTip),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Tip',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dailyTip['overview'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.center_focus_weak,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No scans yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2E3E5C),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start scanning food labels!',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> scan) {
    final name = scan['productName'] ?? 'Unknown Product';
    final score = scan['nutritionQualityScore'] ?? '?';
    final date = scan['timestamp'] != null
        ? _formatDate(scan['timestamp'])
        : 'Unknown Date';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(initialData: scan),
          ),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getScoreColor(score).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  score,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _getScoreColor(score),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2E3E5C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  Color _getScoreColor(String score) {
    switch (score.toUpperCase()) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.lightGreen;
      case 'C':
        return Colors.amber;
      case 'D':
        return Colors.orange;
      case 'E':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActivityCard(String label, String value, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (label == 'Favorites') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavoritesScreen()),
          ).then((_) => _loadData());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: label == 'Favorites'
                    ? const Color(0xFFFFF0F1)
                    : const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: label == 'Favorites'
                    ? Colors.redAccent
                    : const Color(0xFF5E6D8C),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF2E3E5C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
