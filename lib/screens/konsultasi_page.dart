import 'package:flutter/material.dart';

class KonsultasiPage extends StatelessWidget {
  const KonsultasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Konsultasi"), backgroundColor: Colors.purple),
      body: const Center(child: Text("Halaman Konsultasi dengan Pendamping")),
    );
  }
}