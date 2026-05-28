import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'detail_peserta_page.dart';
import 'catatan_page.dart';
import 'profil_pendamping_page.dart';

class DaftarPesertaPage extends StatefulWidget {
  final Map userData;
  final String mode; // 'view' or 'catatan'
  const DaftarPesertaPage({super.key, required this.userData, this.mode = 'view'});

  @override
  State<DaftarPesertaPage> createState() => _DaftarPesertaPageState();
}

class _DaftarPesertaPageState extends State<DaftarPesertaPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pesertaIndividuList = [];
  String _currentIp = 'farel.dwirez.app';
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  String _sortBy = 'Nama';

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Urutkan & Saring",
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("URUTKAN BERDASARKAN", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(Icons.sort_by_alpha, color: Color(0xFF19e62b)),
                    title: Text("Nama (A - Z)", style: GoogleFonts.poppins(fontSize: 14)),
                    trailing: _sortBy == 'Nama' ? const Icon(Icons.check, color: Color(0xFF19e62b)) : null,
                    onTap: () {
                      setState(() => _sortBy = 'Nama');
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.trending_up, color: Color(0xFF19e62b)),
                    title: Text("Progress Tertinggi", style: GoogleFonts.poppins(fontSize: 14)),
                    trailing: _sortBy == 'Progress' ? const Icon(Icons.check, color: Color(0xFF19e62b)) : null,
                    onTap: () {
                      setState(() => _sortBy = 'Progress');
                      setModalState(() {});
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    });
    
    try {
      final pendampingId = widget.userData['id'];
      // Menggunakan Laravel API Route
      final url = Uri.parse("https://$_currentIp/pendamping_api/get_peserta.php?pendamping_id=$pendampingId");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> couples = data['data'] ?? [];
        
        List<Map<String, dynamic>> individuList = [];
        for (var c in couples) {
          int progSuami = int.tryParse(c['progress_suami']?.toString() ?? '0') ?? 0;
          int progIstri = int.tryParse(c['progress_istri']?.toString() ?? '0') ?? 0;
          
          if (c['nama_suami'] != null && c['nama_suami'].toString().isNotEmpty) {
            individuList.add({
              ...c,
              'nama_individu': c['nama_suami'],
              'peran': 'suami',
              'progress_individu': progSuami,
            });
          }
          if (c['nama_istri'] != null && c['nama_istri'].toString().isNotEmpty) {
            individuList.add({
              ...c,
              'nama_individu': c['nama_istri'],
              'peran': 'istri',
              'progress_individu': progIstri,
            });
          }
        }

        setState(() {
          _pesertaIndividuList = individuList;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF19e62b);
    
    final filteredList = _pesertaIndividuList.where((p) {
      final name = (p['nama_individu'] ?? "").toString().toLowerCase();
      final matchSearch = name.contains(_searchQuery.toLowerCase());
      
      bool matchFilter = true;
      int prog = p['progress_individu'] ?? 0;
      if (_selectedFilter == 'Aktif') {
        matchFilter = prog < 100;
      } else if (_selectedFilter == 'Selesai') {
        matchFilter = prog >= 100;
      }
      
      return matchSearch && matchFilter;
    }).toList();

    if (_sortBy == 'Nama') {
      filteredList.sort((a, b) => (a['nama_individu'] ?? '').toString().compareTo((b['nama_individu'] ?? '').toString()));
    } else if (_sortBy == 'Progress') {
      filteredList.sort((a, b) => (b['progress_individu'] ?? 0).compareTo(a['progress_individu'] ?? 0));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Daftar Calon Pengantin",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black87, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfilPendampingPage(userData: widget.userData)),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Cari nama calon pengantin...",
                        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.tune, color: Colors.black87, size: 20),
                  ),
                ),
              ],
            ),
          ),
          
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip("Semua", _selectedFilter == 'Semua', () => setState(() => _selectedFilter = 'Semua')),
                const SizedBox(width: 8),
                _buildFilterDropdown("Aktif", _selectedFilter == 'Aktif', () => setState(() => _selectedFilter = 'Aktif')),
                const SizedBox(width: 8),
                _buildFilterDropdown("Selesai", _selectedFilter == 'Selesai', () => setState(() => _selectedFilter = 'Selesai')),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: primaryColor))
              : filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final p = filteredList[index];
                      return _buildPesertaCard(p, primaryColor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF19e62b) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF19e62b) : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF19e62b) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF19e62b) : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: isSelected ? Colors.white : Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Tidak ada peserta ditemukan", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPesertaCard(Map<String, dynamic> p, Color primaryColor) {
    int progress = p['progress_individu'] ?? 0;
    bool isSelesai = progress >= 100;
    
    return GestureDetector(
      onTap: () {
        if (widget.mode == 'catatan') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CatatanPage(peserta: p, userData: widget.userData)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPesertaPage(peserta: p, userData: widget.userData)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Icon(p['peran'] == 'suami' ? Icons.face : Icons.face_4, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['nama_individu'] ?? 'Peserta', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelesai ? Colors.blue.withOpacity(0.1) : primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isSelesai ? "Selesai" : "Aktif",
                          style: GoogleFonts.poppins(
                            fontSize: 10, 
                            fontWeight: FontWeight.w600, 
                            color: isSelesai ? Colors.blue : primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Progress Bimbingan", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                Text("$progress%", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[200],
                color: isSelesai ? Colors.blue : primaryColor,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
