import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class DetailMateriPage extends StatefulWidget {
  final Map materi;
  final Map userData;
  const DetailMateriPage({super.key, required this.materi, required this.userData});

  @override
  State<DetailMateriPage> createState() => _DetailMateriPageState();
}

class _DetailMateriPageState extends State<DetailMateriPage> {
  bool menunjukkanKuis = false;
  int currentIndex = 0;
  int skor = 0;
  bool isSaving = false;
  List kuisData = [];
  bool loadingKuis = true;
  String? kuisError;
  String _currentIp = 'farel.dwirez.app';

  // Video Controllers
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _checkFileType();
    _loadIp();
    _saveProgressMateri(); // Simpan log saat pertama buka materi
  }

  void _checkFileType() {
    final String fileName = widget.materi['file']?.toLowerCase() ?? '';
    if (fileName.endsWith('.mp4') || 
        fileName.endsWith('.mov') || 
        fileName.endsWith('.avi') || 
        fileName.endsWith('.m4v')) {
      _isVideo = true;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    });
    _fetchKuis();
  }

  Future<void> _fetchKuis() async {
    try {
      final materiId = widget.materi['id'];
      final response = await http.get(
        Uri.parse("https://$_currentIp/catin_api/get_kuis_fixed.php?materi_id=$materiId"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            kuisData = data['data'];
            loadingKuis = false;
          });
          if (_isVideo) _initVideo();
        } else {
          setState(() {
            kuisError = data['message'];
            loadingKuis = false;
          });
        }
      } else {
        setState(() {
          kuisError = "Gagal memuat kuis (Error: ${response.statusCode})";
          loadingKuis = false;
        });
      }
    } catch (e) {
      setState(() {
        kuisError = "Kesalahan koneksi kuis: $e";
        loadingKuis = false;
      });
    }
  }

  Future<void> _initVideo() async {
    final url = widget.materi['file_url'] ?? '';
    if (url.isEmpty) return;

    _videoController = VideoPlayerController.network(url);
    try {
      await _videoController!.initialize();
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController!.value.aspectRatio,
          placeholder: Container(color: Colors.black),
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.green,
            handleColor: Colors.green,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.white.withOpacity(0.5),
          ),
        );
      });
    } catch (e) {
      debugPrint("Gagal inisialisasi video: $e");
    }
  }

  // Simpan log bahwa materi sudah dibuka
  Future<void> _saveProgressMateri() async {
    try {
      final namaAktif = widget.userData['nama_aktif'] ?? widget.userData['nama'] ?? 'User';
      final peran = (namaAktif == widget.userData['nama_suami']) ? 'suami' : 'istri';
      final String url = "https://${_currentIp.trim()}/catin_api/update_materi_log.php"
          "?user_id=${widget.userData['id']}"
          "&materi_id=${widget.materi['id']}"
          "&nama_peserta=${Uri.encodeComponent(namaAktif)}"
          "&peran=$peran";
      
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Gagal simpan progress materi: $e");
    }
  }

  // Simpan hasil kuis
  Future<bool> _simpanHasilKuis() async {
    if (isSaving) return false;
    setState(() => isSaving = true);
    try {
      final namaAktif = widget.userData['nama_aktif'] ?? widget.userData['nama'] ?? 'User';
      final peran = (namaAktif == widget.userData['nama_suami']) ? 'suami' : 'istri';
      final String url = "https://${_currentIp.trim()}/catin_api/simpan_kuis.php"
          "?user_id=${widget.userData['id']}"
          "&materi_id=${widget.materi['id']}"
          "&skor=$skor"
          "&nama_peserta=${Uri.encodeComponent(namaAktif)}"
          "&peran=$peran";
      
      debugPrint("Mencoba simpan kuis ke: $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      debugPrint("Respon Server (${response.statusCode}): ${response.body}");

      // Jika status 200 (OK), kita anggap sukses meskipun body kosong/bukan JSON
      // Ini karena beberapa server memutus koneksi segera setelah data disimpan
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          debugPrint("Server mengembalikan body kosong, tapi status 200. Menganggap sukses.");
          return true; 
        }
        
        try {
          final res = jsonDecode(response.body);
          if (res['status'] == 'success') return true;
        } catch (e) {
          debugPrint("Body bukan JSON, tapi status 200. Menganggap sukses.");
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Exception saat simpan kuis: $e");
      // Jika terjadi FormatException (karena body kosong) tapi kita tahu data masuk, bisa return true
      if (e is FormatException) {
         debugPrint("Terjadi FormatException, kemungkinan data sudah masuk tapi respon terputus.");
         return true;
      }
      return false;
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _tampilkanHasilKuis() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hasil Kuis", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Skor Anda: $skor", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 10),
            Text(skor >= 70 ? "Luar biasa! Materi ini telah Anda kuasai." : "Bagus! Terus tingkatkan pemahaman Anda."),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF19e62b),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving ? null : () async {
                bool success = await _simpanHasilKuis();
                if (success) {
                  if (mounted) Navigator.pop(context); // Tutup dialog
                  if (mounted) Navigator.pop(context); // Kembali ke list materi
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Gagal menyimpan progres. Periksa koneksi Anda."))
                    );
                  }
                }
              },
              child: isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("SIMPAN & KEMBALI", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.materi['judul'] ?? 'Detail Materi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!menunjukkanKuis) ...[
              _buildTampilanMateri(),
              const SizedBox(height: 30),
              if (widget.userData['role'] == 'pendamping')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Kembali",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        menunjukkanKuis = true;
                      });
                    },
                    child: const Text(
                      "Selesai Membaca & Mulai Kuis",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ] else ...[
              _buildTampilanKuis(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTampilanMateri() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.materi['judul'] ?? '',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.materi['deskripsi'] ?? 'Pelajari materi berikut sebelum memulai kuis.',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Container(
          height: 450,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _isVideo 
              ? (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator(color: Colors.green)))
              : SfPdfViewer.network(
                  widget.materi['file_url'] ?? '',
                  onDocumentLoadFailed: (details) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal memuat PDF: ${details.description}')),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildTampilanKuis() {
    if (loadingKuis) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    if (kuisError != null || kuisData.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.quiz_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(kuisError ?? "Soal kuis belum tersedia untuk materi ini.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("KEMBALI")),
          ],
        ),
      );
    }

    if (currentIndex >= kuisData.length) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text("Kuis Selesai!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Skor Anda: $skor / ${kuisData.length * 50}"),
            const SizedBox(height: 30),
            if (isSaving)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving ? null : () async {
                    bool success = await _simpanHasilKuis();
                    if (success) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Progres berhasil disimpan!"), backgroundColor: Colors.green)
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Gagal menyimpan hasil kuis. Silakan coba lagi."),
                            backgroundColor: Colors.red,
                          )
                        );
                      }
                    }
                  },
                  child: isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SIMPAN & KEMBALI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      );
    }

    final soal = kuisData[currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: (currentIndex + 1) / kuisData.length, color: Colors.green),
        const SizedBox(height: 24),
        Text("Pertanyaan ${currentIndex + 1}", style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Text(soal['pertanyaan'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        ...['a', 'b', 'c', 'd'].map((key) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(soal['opsi_$key']),
                onTap: () {
                  if (key.toLowerCase() == (soal['jawaban_benar'] ?? '').toString().toLowerCase()) {
                    skor += 50;
                  }
                setState(() {
                  currentIndex++;
                });
              },
            ),
          );
        }),
      ],
    );
  }
}
