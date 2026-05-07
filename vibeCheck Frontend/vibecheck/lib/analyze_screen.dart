import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kApiBase = 'http://localhost:5000';

class AnalysisResult {
  final String sentimentLabel;
  final double sentimentNeg;
  final double sentimentNeu;
  final double sentimentPos;
  final Map<String, bool> toxicity;
  final Map<String, double> toxConfidence;
  final String personalityType;
  final String personalityDesc;

  const AnalysisResult({
    required this.sentimentLabel,
    required this.sentimentNeg,
    required this.sentimentNeu,
    required this.sentimentPos,
    required this.toxicity,
    required this.toxConfidence,
    required this.personalityType,
    required this.personalityDesc,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final s = json['sentiment'] as Map<String, dynamic>;
    final t = json['toxicity'] as Map<String, dynamic>;
    final p = json['personality'] as Map<String, dynamic>;
    return AnalysisResult(
      sentimentLabel: s['label'] as String,
      sentimentNeg: (s['negative'] as num).toDouble(),
      sentimentNeu: (s['neutral'] as num).toDouble(),
      sentimentPos: (s['positive'] as num).toDouble(),
      toxicity: t.map((k, v) => MapEntry(k, (v as Map)['detected'] as bool)),
      toxConfidence: t.map((k, v) => MapEntry(k, ((v as Map)['confidence'] as num).toDouble())),
      personalityType: p['type'] as String,
      personalityDesc: p['description'] as String,
    );
  }
}

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final TextEditingController _textController = TextEditingController();

  AnalysisResult? _result;
  bool _loading = false;
  String? _error;

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$kApiBase/analyze'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => _result = AnalysisResult.fromJson(json));
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => _error = json['error'] ?? 'Server error ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach server. Make sure Flask is running.\n$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _sentimentColor(String label) {
    if (label == 'Positive') return const Color(0xff2e7d32);
    if (label == 'Negative') return const Color(0xffc62828);
    return const Color(0xff1565c0);
  }

  Widget _sentimentBar(String label, double value, Color barColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        SizedBox(
          width: 72,
          child: Text(label,
              style: TextStyle(
                  color: barColor, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 13,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            '${(value * 100).toStringAsFixed(1)}%',
            textAlign: TextAlign.right,
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _toxChip(String label, bool detected, double confidence) {
    final pretty = label.replaceAll('_', ' ').toUpperCase();
    final bg = detected ? const Color(0xffb71c1c) : const Color(0xff6a1b9a);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(pretty,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(
          detected ? '${(confidence * 100).toStringAsFixed(0)}% conf.' : 'Not detected',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ]),
    );
  }

  Widget _card(String emoji, String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2d1b69))),
        ]),
        const Divider(height: 24),
        child,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeCheck',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xff4a148c),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff8fcdf6), Color(0xffdd85f8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Input card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(children: [
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  maxLength: 10000,
                  style: const TextStyle(color: Color(0xff1a1a2e), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type or paste your text here…',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xfff5f5f5),
                    counterStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _analyze,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.psychology_rounded),
                    label: Text(_loading ? 'Analysing…' : 'Analyse',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xff4a148c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200)),
                child: Text(_error!,
                    style:
                        TextStyle(color: Colors.red.shade800, fontSize: 13)),
              ),
            ],

            // Results
            if (_result != null) ...[
              const SizedBox(height: 16),

              // Sentiment
              _card(
                '😊',
                'Sentiment Analysis',
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _sentimentColor(_result!.sentimentLabel)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _result!.sentimentLabel,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _sentimentColor(_result!.sentimentLabel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sentimentBar('Negative', _result!.sentimentNeg,
                      const Color(0xffc62828)),
                  _sentimentBar('Neutral', _result!.sentimentNeu,
                      const Color(0xff1565c0)),
                  _sentimentBar('Positive', _result!.sentimentPos,
                      const Color(0xff2e7d32)),
                ]),
              ),
              const SizedBox(height: 12),

              // Toxicity
              _card(
                '⚠️',
                'Toxicity Analysis',
                Wrap(
                  children: _result!.toxicity.entries
                      .map((e) => _toxChip(e.key, e.value,
                          _result!.toxConfidence[e.key] ?? 0.0))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Personality
              _card(
                '🧠',
                'Personality Analysis',
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xff4a148c),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _result!.personalityType,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _result!.personalityDesc,
                        style: const TextStyle(
                            color: Color(0xff3d1a6e),
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ]),
              ),
              const SizedBox(height: 20),
            ],
          ]),
        ),
      ),
    );
  }
}