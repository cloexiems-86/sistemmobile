import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> loginProses() async {
    if (_userController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Harap isi username dan password!");
      return;
    }

    try {
      // Menggunakan IP Wi-Fi rumah kamu saat ini
      var url = Uri.parse("http://192.168.1.5/catin_api/login.php");

      var response = await http.post(url, body: {
        "username": _userController.text,
        "password": _passwordController.text,
      });

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _showSnackBar("Selamat Datang, ${data['user']['nama']}");

          if (!mounted) return;

          // REDIRECT OTOMATIS BERDASARKAN ROLE DARI PHP
          if (data['user']['role'] == 'catin') {
            // Tampilkan Dialog Pilih Profil (Ciko atau Puri)
            _showPilihProfil(data['user']);
          } else {
            _showSnackBar("Anda masuk sebagai Pendamping");
            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => PendampingPage()));
          }
        } else {
          _showSnackBar(data['message']);
        }
      }
    } catch (e) {
      _showSnackBar("Gagal terhubung ke server laptop.");
    }
  }

  // FUNGSI BARU: Dialog Pilih Profil buat Ciko & Puri
  void _showPilihProfil(Map userData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Siapa yang akan belajar?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.male, color: Colors.blue),
              title: Text(userData['nama_suami']),
              onTap: () => _masukDashboard(userData, userData['nama_suami']),
            ),
            ListTile(
              leading: const Icon(Icons.female, color: Colors.pink),
              title: Text(userData['nama_istri']),
              onTap: () => _masukDashboard(userData, userData['nama_istri']),
            ),
          ],
        ),
      ),
    );
  }

  void _masukDashboard(Map userData, String namaAktif) {
    // Kita tambahkan nama yang memilih ke dalam data user
    userData['nama_aktif'] = namaAktif; 
    
    Navigator.pop(context); // Tutup dialog
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage(userData: userData)),
    );
  }

  void _showSnackBar(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login KUA Mojo"), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.lock_person, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username / Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loginProses,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("LOGIN", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}