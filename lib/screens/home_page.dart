import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Optional, but for better font like in the reference
import 'materi_page.dart';
import 'ujian_page.dart';
import 'sertifikat_page.dart';
import 'konsultasi_page.dart';

class HomePage extends StatelessWidget {
  final Map userData; // Data user dari login

  const HomePage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Warna Hijau Kemenag (mirip referensi)
    const Color primaryColor = Colors.green; // Updated to match primaryColor definition

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC), // Light grey background like reference
      appBar: AppBar(
        title: const Text("E-Learning KUA"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              // Fungsi Logout Sederhana
              Navigator.pop(context);
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Halo Ahmad & Siti! + Profile Picture + Notifications
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              color: primaryColor,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Placeholder for profile pic
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Halo, ${userData['nama']}! 👋",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Selamat pagi, calon pengantin. Semangat melengkapi persiapan ibadah terpanjang kalian.",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8), // Using withValues for transparency
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: primaryColor, width: 2)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Card Progres Pembelajaran 40%
                  _buildProgressCard(),
                  const SizedBox(height: 30),

                  // 3. Section Jadwal Terdekat (with image and detail button)
                  const Text("Jadwal Terdekat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildScheduleCard(),
                  const SizedBox(height: 30),

                  // 4. Grid Menu Cepat (Icons with navigation)
                  const Text("Menu Cepat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    children: [
                      _buildMenuItem(context, Icons.book, "Materi", primaryColor, const MateriPage()),
                      _buildMenuItem(context, Icons.assignment, "Ujian", Colors.orange, const UjianPage()),
                      _buildMenuItem(context, Icons.verified, "Sertifikat", Colors.blue, const SertifikatPage()),
                      _buildMenuItem(context, Icons.chat, "Konsultasi", Colors.purple, const KonsultasiPage()),
                    ],
                  ),
                  const SizedBox(height: 100), // Spacing for BottomNav
                ],
              ),
            ),
          ],
        ),
      ),
      // Optional Bottom Navigation Bar to mimic reference
      bottomNavigationBar: _buildBottomNav(primaryColor),
      floatingActionButton: _buildFloatingAction(primaryColor),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // Helper function to build progress card
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progres Pembelajaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Text("40%", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: 0.4,
            minHeight: 12,
            color: Colors.green,
            backgroundColor: Colors.green[100],
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          const Text("4 dari 10 modul selesai", style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  // Helper function to build schedule card
  Widget _buildScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              'https://images.unsplash.com/photo-1596700018593-1628d0865c32', // Placeholder for building image
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(5)),
                  child: const Text("TATAP MUKA", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                const Text("Sesi Bimbingan Tatap Muka 1", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Row(children: [Icon(Icons.calendar_today, size: 16, color: Colors.grey), SizedBox(width: 8), Text("Sabtu, 25 Mei 2024 - 09:00 WIB", style: TextStyle(color: Colors.grey))]),
                const SizedBox(height: 10),
                const Row(children: [Icon(Icons.location_on, size: 16, color: Colors.grey), SizedBox(width: 8), Text("Aula Utama KUA Kec. Gambir", style: TextStyle(color: Colors.grey))]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {}, // Function to view schedule detail
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                    child: const Text("Lihat Detail", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to build menu item with navigation
  Widget _buildMenuItem(BuildContext context, IconData icon, String label, Color color, Widget destination) {
    return InkWell( // Using InkWell for tap effect
      onTap: () {
        // --- INI FUNGSI AGAR TOMBOL BERFUNGSI ---
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), // Using withValues for transparency
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    );
  }

  // Helper to build bottom navigation bar (matching reference structure)
  Widget _buildBottomNav(Color primaryColor) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Beranda", primaryColor),
            _buildNavItem(Icons.book_outlined, "Kursus", primaryColor),
            const SizedBox(width: 40), // Spacing for floating button
            _buildNavItem(Icons.calendar_month_outlined, "Jadwal", primaryColor),
            _buildNavItem(Icons.person_outline, "Profil", primaryColor),
          ],
        ),
      ),
    );
  }

  // Helper for single nav item
  Widget _buildNavItem(IconData icon, String label, Color primaryColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: label == "Beranda" ? primaryColor : Colors.grey[400]),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: label == "Beranda" ? primaryColor : Colors.grey[400], fontSize: 10)),
      ],
    );
  }

  // Helper for floating action button in bottom nav
  Widget _buildFloatingAction(Color primaryColor) {
    return FloatingActionButton(
      onPressed: () {}, // Action for Scan button
      backgroundColor: primaryColor,
      shape: const CircleBorder(),
      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 30),
    );
  }
}