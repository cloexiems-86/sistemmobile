import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class KuisMateriPage extends StatefulWidget {
  final int materiId;
  final String materiJudul;
  final Map userData;

  const KuisMateriPage({
    super.key,
    required this.materiId,
    required this.materiJudul,
    required this.userData,
  });

  @override
  State<KuisMateriPage> createState() => _KuisMateriPageState();
}

class _KuisMateriPageState extends State<KuisMateriPage> {
  List questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;
  String _currentIp = 'farel.dwirez.app';
  Map<int, String> userAnswers = {};

  @override
  void initState() {
    super.initState();
    _initAndFetch();
  }

  Future<void> _initAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await http.get(
        Uri.parse("https://$_currentIp/catin_api/get_kuis_fixed.php?materi_id=${widget.materiId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            questions = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Gagal mengambil kuis (Status: ${response.statusCode})";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Kesalahan koneksi: $e";
        isLoading = false;
      });
    }
  }

  void _submitQuiz() async {
    setState(() => isSubmitting = true);

    try {
      // 1. Calculate Score
      int correctCount = 0;
      for (int i = 0; i < questions.length; i++) {
        if (userAnswers[i] == questions[i]['jawaban_benar']) {
          correctCount++;
        }
      }
      score = ((correctCount / questions.length) * 100).toInt();

      final userId = widget.userData['id'];
      final namaAktif = widget.userData['nama_aktif'] ?? 'User';
      final peran = (namaAktif == widget.userData['nama_suami']) ? 'suami' : 'istri';

      // 2. Save Quiz Result
      await http.post(
        Uri.parse("https://$_currentIp/catin_api/simpan_kuis.php"),
        body: {
          'user_id': userId.toString(),
          'materi_id': widget.materiId.toString(),
          'skor': score.toString(),
          'nama_peserta': namaAktif,
          'peran': peran,
        },
      );

      // 3. Update Progress / Attendance
      await http.post(
        Uri.parse("https://$_currentIp/catin_api/update_materi_log.php"),
        body: {
          'user_id': userId.toString(),
          'materi_id': widget.materiId.toString(),
          'nama_peserta': namaAktif,
          'peran': peran,
        },
      );

      if (mounted) {
        _showResultDialog(score, correctCount, questions.length);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan hasil: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showResultDialog(int score, int correct, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kuis Selesai!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF19e62b), size: 64),
            const SizedBox(height: 16),
            Text(
              "Skor Anda: $score",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("$correct dari $total jawaban benar"),
            const SizedBox(height: 16),
            const Text(
              "Kehadiran Anda untuk materi ini telah tercatat secara otomatis.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to pdf
              Navigator.pop(context); // back to materi list (to refresh progress)
            },
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF19e62b))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF19e62b);

    return Scaffold(
      appBar: AppBar(
        title: Text("Kuis: ${widget.materiJudul}"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : errorMessage != null
              ? _buildErrorState()
              : questions.isEmpty
                  ? const Center(child: Text("Tidak ada kuis untuk materi ini."))
                  : _buildQuizContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchQuestions,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizContent() {
    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(Color(0xFF19e62b)),
          minHeight: 8,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pertanyaan ${currentQuestionIndex + 1} dari ${questions.length}",
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Text(
                  question['pertanyaan'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3),
                ),
                const SizedBox(height: 32),
                _buildOption('a', question['opsi_a']),
                _buildOption('b', question['opsi_b']),
                _buildOption('c', question['opsi_c']),
                _buildOption('d', question['opsi_d']),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF19e62b),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: userAnswers[currentQuestionIndex] == null || isSubmitting
                  ? null
                  : () {
                      if (currentQuestionIndex < questions.length - 1) {
                        setState(() {
                          currentQuestionIndex++;
                        });
                      } else {
                        _submitQuiz();
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      currentQuestionIndex < questions.length - 1 ? "PERTANYAAN BERIKUTNYA" : "SELESAI & SIMPAN ABSENSI",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOption(String key, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    bool isSelected = userAnswers[currentQuestionIndex] == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          userAnswers[currentQuestionIndex] = key;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF19e62b).withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF19e62b) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF19e62b) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  key.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
