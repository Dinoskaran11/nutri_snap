import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../services/ocr_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../utils/app_colors.dart';

class ResultScreen extends StatefulWidget {
  final String? imagePath;
  final Map<String, dynamic>? initialData;

  const ResultScreen({super.key, this.imagePath, this.initialData});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final OCRService _ocrService = OCRService();
  final GeminiService _geminiService = GeminiService();

  String _status = "Initializing...";
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _loadInitialData();
    } else if (widget.imagePath != null) {
      _processImage();
    } else {
      setState(() {
        _status = "No data or image provided.";
        _isLoading = false;
        _errorMessage = "Invalid state: No scan data found.";
      });
    }
  }

  void _loadInitialData() {
    setState(() {
      _data = widget.initialData;
      _isLoading = false;
      _status = "Loaded";
    });
    // Check favorite status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavorite();
    });
  }

  Future<void> _checkFavorite() async {
    if (_data != null && mounted) {
      final storage = context.read<StorageService>();
      final isFav = await storage.isFavorite(_data!['productName'] ?? '');
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _processImage() async {
    if (widget.imagePath == null) return;

    setState(() {
      _status = "Scanning ingredients...";
      _isLoading = true;
      _errorMessage = null;
    });

    final extractedText = await _ocrService.extractText(widget.imagePath!);

    if (extractedText == null || extractedText.isEmpty) {
      setState(() {
        _status = "No text found. Please try again.";
        _isLoading = false;
        _errorMessage =
            "Could not identify any text on the image. Please try scanning a clearer label.";
      });
      return;
    }

    setState(() {
      _status = "Analyzing nutrition data...";
    });

    final jsonString = await _geminiService.analyzeNutrition(extractedText);

    if (jsonString != null && jsonString.startsWith("Error:")) {
      setState(() {
        _status = "Analysis failed";
        _isLoading = false;
        _errorMessage = jsonString; // Show the specific error from Gemini
      });
      return;
    }

    try {
      if (jsonString != null) {
        // Basic sanitization just in case
        final cleanJson = jsonString.trim();
        final parsedData = jsonDecode(cleanJson) as Map<String, dynamic>;

        // Add local image path to data so it can be saved in history
        if (widget.imagePath != null) {
          parsedData['imagePath'] = widget.imagePath;
        }

        setState(() {
          _data = parsedData;
          _isLoading = false;
        });

        // Save to History and Check Favorite status using StorageService
        if (mounted) {
          final storage = context.read<StorageService>();
          await storage.saveScan(parsedData);
          await _checkFavorite();
        }
      } else {
        throw Exception("Empty response from AI");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "Parsing Error";
          _isLoading = false;
          _errorMessage =
              "Failed to process nutrition data. Raw: $jsonString. Error: $e";
        });
      }
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Helper to extract data safely
    final productName = _data?['productName'] ?? "Unknown Product";
    final tags = List<String>.from(_data?['tags'] ?? []);
    final score = _data?['nutritionQualityScore'] ?? "?";
    final scoreDesc =
        _data?['nutritionQualityDescription'] ?? "No analysis available.";
    final summary = _data?['analysisSummary'] ?? "";
    final nutrients = List<Map<String, dynamic>>.from(
      _data?['nutrients'] ?? [],
    );

    // Determine image provider
    ImageProvider? headerImage;
    if (widget.imagePath != null && File(widget.imagePath!).existsSync()) {
      headerImage = FileImage(File(widget.imagePath!));
    } else if (_data != null && _data!.containsKey('imagePath')) {
      final savedPath = _data!['imagePath'];
      if (savedPath != null && File(savedPath).existsSync()) {
        headerImage = FileImage(File(savedPath));
      }
    }
    // Fallback?
    // If no image, maybe show a color or asset.

    return Scaffold(
      backgroundColor: const Color(0xFFF8FDF8), // Mint White background
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 300.0,
                  pinned: true,
                  backgroundColor: AppColors.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: headerImage != null
                        ? Image(image: headerImage, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: _errorMessage != null
                        ? Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Error",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                if (widget.imagePath != null)
                                  ElevatedButton(
                                    onPressed: _processImage,
                                    child: const Text("Retry"),
                                  ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      productName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tags.map((tag) {
                                  Color tagColor = Colors.green;
                                  if (tag.toLowerCase().contains('processed') ||
                                      tag.toLowerCase().contains('sugar')) {
                                    tagColor = Colors.orange;
                                  }
                                  return _buildTag(tag, tagColor);
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Nutrition Quality",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _getScoreColor(
                                          score,
                                        ).withOpacity(0.3),
                                        width: 4,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        score,
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: _getScoreColor(score),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      scoreDesc,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Dynamic Nutrients Grid
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: nutrients.map((n) {
                                  return _buildNutrientItem(
                                    Icons.circle,
                                    n['value'] ?? '-',
                                    n['label'] ?? 'Unknown',
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 32),
                              // Analysis Result Summary
                              Text(
                                "AI Analysis",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 10),
                              MarkdownBody(data: summary),

                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_data == null) return;
                                    final storage = context
                                        .read<StorageService>();
                                    final newStatus = await storage
                                        .toggleFavorite(_data!);
                                    if (mounted) {
                                      setState(() {
                                        _isFavorite = newStatus;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isFavorite
                                        ? Colors.red
                                        : Colors.orange,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    _isFavorite
                                        ? "REMOVE FAVORITE"
                                        : "ADD FAVORITE",
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNutrientItem(IconData icon, String value, String label) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50], // very light grey
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.clip,
                ),
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
