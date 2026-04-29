import 'package:flutter/material.dart';

class UjianPage extends StatelessWidget {
  const UjianPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ujian/Kuis"), backgroundColor: Colors.orange),
      body: const Center(child: Text("Halaman Daftar Ujian")),
    );
  }
}