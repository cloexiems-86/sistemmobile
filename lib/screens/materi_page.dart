// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MateriPage extends StatefulWidget {
  const MateriPage({super.key});

  @override
  State<MateriPage> createState() => _MateriPageState();
}

class _MateriPageState extends State<MateriPage> {
  List daftarMateri = [];
  bool loading = true;

  Future<void> ambilMateri() async {
    try {
      // Pastikan IP ini sesuai dengan IP Laptop/Laragon kamu
      var url = Uri.parse("http://192.168.1.5/catin_api/get_materi.php");
      var response = await http.get(url);
      
      if (response.statusCode == 200) {
        setState(() {
          daftarMateri = jsonDecode(response.body);
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Koneksi gagal: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    ambilMateri();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Materi Bimwin", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: daftarMateri.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.book, color: Colors.green),
                  title: Text(daftarMateri[index]['judul'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Ketuk untuk membaca materi"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MateriDetailPage(
                          idMateri: daftarMateri[index]['id'].toString(),
                          judul: daftarMateri[index]['judul'],
                          deskripsi: daftarMateri[index]['deskripsi'], // Pakai 'deskripsi' sesuai HeidiSQL
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
    );
  }
}

class MateriDetailPage extends StatefulWidget {
  final String idMateri, judul, deskripsi;
  const MateriDetailPage({super.key, required this.idMateri, required this.judul, required this.deskripsi});

  @override
  State<MateriDetailPage> createState() => _MateriDetailPageState();
}

class _MateriDetailPageState extends State<MateriDetailPage> {
  List kuisMateri = [];
  Map<int, String> jawabanUser = {};
  bool sudahBaca = false;

  Future<void> ambilKuis() async {
    // API memanggil kuis_id berdasarkan id materi
    var url = Uri.parse("http://192.168.1.5/catin_api/get_materi.php?materi_id=${widget.idMateri}");
    var response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        kuisMateri = jsonDecode(response.body);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    ambilKuis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Materi"), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.judul, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(widget.deskripsi, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 30),

            if (!sudahBaca)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => sudahBaca = true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text("SAYA SUDAH SELESAI MEMBACA", style: TextStyle(color: Colors.white)),
                ),
              ),

            if (sudahBaca) ...[
              const Divider(height: 50),
              const Text("Kuis Singkat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kuisMateri.length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pakai 'pertanyaan' sesuai kolom di HeidiSQL
                      Text("${index + 1}. ${kuisMateri[index]['pertanyaan']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      RadioListTile<String>(
                        title: Text(kuisMateri[index]['opsi_a']), // Sesuai 'opsi_a' di DB
                        value: "a",
                        groupValue: jawabanUser[index],
                        onChanged: (val) => setState(() => jawabanUser[index] = val!),
                      ),
                      RadioListTile<String>(
                        title: Text(kuisMateri[index]['opsi_b']),
                        value: "b",
                        groupValue: jawabanUser[index],
                        onChanged: (val) => setState(() => jawabanUser[index] = val!),
                      ),
                      RadioListTile<String>(
                        title: Text(kuisMateri[index]['opsi_c']),
                        value: "c",
                        groupValue: jawabanUser[index],
                        onChanged: (val) => setState(() => jawabanUser[index] = val!),
                      ),
                      const SizedBox(height: 15),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: jawabanUser.length < kuisMateri.length ? null : () => Navigator.pop(context),
                child: const Text("SIMPAN JAWABAN"),
              ),
            ],
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}