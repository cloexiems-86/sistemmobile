import 'package:flutter/material.dart';

class SertifikatPage extends StatelessWidget {
  const SertifikatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sertifikat"), backgroundColor: Colors.blue),
      body: const Center(child: Text("Halaman Sertifikat Kamu")),
    );
  }
}