import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
// ignore_for_file: deprecated_member_use
import 'sertifikat_page.dart';

class UjianPage extends StatefulWidget {
  final Map userData;
  
  const UjianPage({super.key, required this.userData});

  @override
  State<UjianPage> createState() => _UjianPageState();
}

class _UjianPageState extends State<UjianPage> {
  List daftarUjian = [];
  Map<int, String> jawabanUser = {};
  bool loading = true;
  bool submitting = false;
  final String _currentIp = 'farel.dwirez.app';
  
  // Timer State Variables
  static const int _durasiUjianMenit = 15;
  Timer? _timer;
  int _remainingSeconds = _durasiUjianMenit * 60;

  // Fungsi mengambil 10 soal random dari database lewat API PHP
  Future<void> ambilUjian() async {
    try {
      // Ganti IP ini sesuai dengan IP laptop kamu saat ini
      var url = Uri.parse("https://$_currentIp/catin_api/get_ujian.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          daftarUjian = data is List ? data : [];
          loading = false;
        });
        if (daftarUjian.isNotEmpty) {
          _startTimer();
        }
      } else {
        setState(() => loading = false);
        if (mounted) {
          _showErrorDialog("Gagal memuat soal ujian. Status: ${response.statusCode}");
        }
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Gagal memuat soal ujian: $e");
      if (mounted) {
        _showErrorDialog("Gagal memuat soal ujian: $e");
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _durasiUjianMenit * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _autoSubmitUjian();
      }
    });
  }

  void _autoSubmitUjian() {
    if (submitting) return;
    
    // Tampilkan dialog pemberitahuan bahwa waktu habis dan auto-submit berjalan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.alarm_off, color: Colors.red),
            SizedBox(width: 10),
            Text("Waktu Ujian Habis!"),
          ],
        ),
        content: const Text(
          "Waktu pengerjaan ujian Anda telah selesai. Jawaban Anda yang telah diisi akan dikirimkan otomatis ke server.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              _kirimJawaban();
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    // Auto-pop setelah 3 detik jika tidak diklik, lalu panggil kirim jawaban
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Tutup dialog jika masih terbuka
        }
        _kirimJawaban();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    ambilUjian();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ujian Akhir Catin", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : daftarUjian.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        "Tidak ada soal ujian tersedia.",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => loading = true);
                          ambilUjian();
                        },
                        child: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      _buildTimerHeader(),
                      Text(
                        "Selesaikan ${daftarUjian.length} soal berikut untuk mendapatkan sertifikat.",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: daftarUjian.length,
                        itemBuilder: (context, index) {
                          var soal = daftarUjian[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${index + 1}. ${soal['pertanyaan'] ?? 'Pertanyaan tidak tersedia'}",
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 10),
                                  
                                  // OPSI JAWABAN (Menggunakan ID Soal sebagai Key)
                                  _buildRadioOption(soal['id'], "a", soal['opsi_a'] ?? ""),
                                  _buildRadioOption(soal['id'], "b", soal['opsi_b'] ?? ""),
                                  _buildRadioOption(soal['id'], "c", soal['opsi_c'] ?? ""),
                                  _buildRadioOption(soal['id'], "d", soal['opsi_d'] ?? ""),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      // Info jumlah soal yang belum dijawab
                      if (jawabanUser.length < daftarUjian.length)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            "Belum dijawab: ${daftarUjian.length - jawabanUser.length} soal",
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: !submitting ? () => _konfirmasiKirim() : null,
                          child: submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "SUBMIT JAWABAN UJIAN",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTimerHeader() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    String timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    
    bool isLowTime = _remainingSeconds < 120; // less than 2 minutes
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLowTime 
              ? [Colors.red.shade700, Colors.red.shade500] 
               : [Colors.orange.shade600, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isLowTime ? Icons.alarm_on : Icons.timer,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isLowTime ? "Sisa Waktu (Hampir Habis!):" : "Sisa Waktu Ujian:",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _konfirmasiKirim() {
    int totalSoal = daftarUjian.length;
    int terjawab = jawabanUser.length;
    int belumTerjawab = totalSoal - terjawab;

    if (belumTerjawab > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text("Soal Belum Lengkap", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Ada $belumTerjawab soal yang belum Anda jawab. Apakah Anda yakin ingin mengumpulkan ujian sekarang?\n\n(Soal yang belum dijawab akan dianggap salah).",
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Periksa Kembali", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _kirimJawaban();
              },
              child: const Text("Ya, Kumpulkan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text("Kumpulkan Ujian?", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Apakah Anda yakin seluruh jawaban sudah benar dan siap untuk dikirim?",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _kirimJawaban();
              },
              child: const Text("Kumpulkan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  // Widget pembantu untuk Radio Button agar kodingan rapi dan bebas error
  Widget _buildRadioOption(dynamic questionId, String value, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    return RadioListTile<String>(
      title: Text(text),
      value: value,
      groupValue: jawabanUser[int.parse(questionId.toString())],
      onChanged: (val) {
        setState(() {
          jawabanUser[int.parse(questionId.toString())] = val!;
        });
      },
    );
  }

  Future<void> _kirimJawaban() async {
    if (submitting) return;
    
    setState(() => submitting = true);

    try {
      // Konversi jawaban ke format JSON
      Map<String, String> jawabanMap = {};
      jawabanUser.forEach((key, value) {
        jawabanMap[key.toString()] = value;
      });
      String jawabanJson = jsonEncode(jawabanMap);

      // Ambil user_id dan nama dari userData
      String userId = widget.userData['id']?.toString() ?? '1';
      String namaPeserta = widget.userData['nama_aktif'] ?? widget.userData['nama'] ?? 'User';

      // Kirim ke server
      var url = Uri.parse("https://$_currentIp/catin_api/simpan_ujian.php");
      var response = await http.post(
        url,
        body: {
          "user_id": userId,
          "nama_peserta": namaPeserta,
          "jawaban": jawabanJson,
        },
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        
        if (result['status'] == 'success') {
          // Tampilkan dialog sukses dengan skor
          if (mounted) {
            _showSuccessDialog(
              result['skor']?.toString() ?? '0',
              result['benar']?.toString() ?? '0',
              result['total']?.toString() ?? '0',
            );
          }
        } else {
          if (mounted) {
            _showErrorDialog(result['message'] ?? "Gagal menyimpan jawaban");
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog("Gagal mengirim jawaban. Status: ${response.statusCode}");
        }
      }
    } catch (e) {
      debugPrint("Error saat mengirim jawaban: $e");
      if (mounted) {
        _showErrorDialog("Gagal mengirim jawaban: $e");
      }
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // MODIFIKASI: Menambahkan pengecekan kelulusan berdasarkan nilai (skor >= 70)
  void _showSuccessDialog(String skor, String benar, String total) {
    double nilai = double.tryParse(skor) ?? 0.0;
    bool isLulus = nilai >= 70;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isLulus ? "Ujian Selesai!" : "Ujian Selesai",
          style: TextStyle(color: isLulus ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLulus ? Icons.check_circle : Icons.cancel, 
              color: isLulus ? Colors.green : Colors.red, 
              size: 64
            ),
            const SizedBox(height: 16),
            Text(
              isLulus 
                  ? "Selamat! Kamu dinyatakan LULUS." 
                  : "Maaf, kamu dinyatakan TIDAK LULUS karena nilaimu di bawah 70.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              "Skor: $skor%",
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: isLulus ? Colors.green : Colors.red
              ),
            ),
            Text("$benar dari $total soal benar"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup dialog
              
              if (isLulus) {
                // Pindah ke halaman sertifikat jika lulus
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SertifikatPage(userData: widget.userData),
                  ),
                );
              } else {
                // Jika tidak lulus, arahkan keluar dari halaman ujian (kembali ke menu sebelumnya)
                Navigator.pop(context);
              }
            },
            child: Text(
              isLulus ? "LIHAT SERTIFIKAT" : "KEMBALI",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}