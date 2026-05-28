import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class DetailCatinPage extends StatefulWidget {
  final Map userData;
  const DetailCatinPage({super.key, required this.userData});

  @override
  State<DetailCatinPage> createState() => _DetailCatinPageState();
}

class _DetailCatinPageState extends State<DetailCatinPage> {
  late Map currentUserData;
  bool isLoading = false;
  String _currentIp = 'farel.dwirez.app';

  @override
  void initState() {
    super.initState();
    currentUserData = Map.from(widget.userData);
    _loadIp();
  }

  Future<void> _loadIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    });
  }

  // Fungsi ambil data terbaru dari server
  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("https://$_currentIp/catin_api/get_catin_detail.php?id=${currentUserData['id']}"),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          String originalNamaAktif = currentUserData['nama_aktif'];
          setState(() {
            currentUserData = data['user'];
            currentUserData['nama_aktif'] = originalNamaAktif;
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF19e62b);
    const Color bgLight = Color(0xFFF6F8F6);
    
    String namaAktif = currentUserData['nama_aktif'] ?? '';
    bool isSuami = (namaAktif == currentUserData['nama_suami']);
    
    // Data Spesifik berdasarkan siapa yang login
    String myNik = isSuami ? (currentUserData['nik_suami'] ?? '-') : (currentUserData['nik_istri'] ?? '-');
    String myPhone = isSuami ? (currentUserData['phone_suami'] ?? '-') : (currentUserData['phone_istri'] ?? '-');
    String myEmail = isSuami ? (currentUserData['email_suami'] ?? '-') : (currentUserData['email_istri'] ?? '-');
    String myAlamat = isSuami ? (currentUserData['alamat_suami'] ?? '-') : (currentUserData['alamat_istri'] ?? '-');
    String myDocKtp = isSuami ? (currentUserData['ktp_suami'] ?? '') : (currentUserData['ktp_istri'] ?? '');
    String myDocKk = isSuami ? (currentUserData['kk_suami'] ?? '') : (currentUserData['kk_istri'] ?? '');

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgLight,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(primaryColor, namaAktif, isSuami),
            const SizedBox(height: 30),
            
            // Personal Information Section
            _buildSectionTitle('Informasi Pribadi'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoTile(Icons.badge_outlined, 'NIK', myNik),
              _buildDivider(),
              _buildInfoTile(Icons.phone_android_rounded, 'Nomor HP', myPhone),
              _buildDivider(),
              _buildInfoTile(Icons.email_outlined, 'Email', myEmail),
              _buildDivider(),
              _buildInfoTile(Icons.location_on_outlined, 'Alamat', myAlamat),
            ]),
            
            const SizedBox(height: 30),

            // Partner Info (Summary)
            _buildSectionTitle('Informasi Pasangan'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildInfoTile(
                isSuami ? Icons.female_rounded : Icons.male_rounded, 
                isSuami ? 'Calon Istri' : 'Calon Suami', 
                isSuami ? (currentUserData['nama_istri'] ?? '-') : (currentUserData['nama_suami'] ?? '-')
              ),
            ]),

            const SizedBox(height: 30),

            // Documents Section
            _buildSectionTitle('Dokumen Persyaratan'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildDocTile(Icons.assignment_ind_outlined, 'KTP Saya', myDocKtp.isNotEmpty, () => _showUploadOptionSheet('KTP')),
              _buildDivider(),
              _buildDocTile(Icons.family_restroom_outlined, 'Kartu Keluarga', myDocKk.isNotEmpty, () => _showUploadOptionSheet('KK')),
            ]),

            const SizedBox(height: 30),
            
            // Actions
            _buildSectionTitle('Pengaturan'),
            const SizedBox(height: 16),
            _buildInfoCard([
              _buildActionTile(Icons.edit_note_rounded, 'Edit Data Profil', () => _showEditForm(isSuami)),
              _buildDivider(),
              _buildActionTile(Icons.logout_rounded, 'Keluar Sesi', () => _logout(context), isDanger: true),
            ]),
            
            const SizedBox(height: 40),
            const Text(
              'E-Learning KUA Mojo • Versi 1.1.0',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Color color, String name, bool isSuami) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withAlpha(60), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(isSuami ? Icons.male_rounded : Icons.female_rounded, size: 40, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            isSuami ? 'Calon Suami' : 'Calon Istri',
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Rencana Nikah: ${currentUserData['wedding_date'] ?? '-'}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF19e62b)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile(IconData icon, String label, bool isUploaded, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isUploaded ? Colors.green : Colors.orange),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(isUploaded ? 'Sudah Diunggah' : 'Belum Ada File', style: TextStyle(color: isUploaded ? Colors.green : Colors.orange, fontSize: 11)),
      trailing: const Icon(Icons.cloud_upload_outlined, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildActionTile(IconData icon, String label, VoidCallback onTap, {bool isDanger = false}) {
    Color color = isDanger ? Colors.red : Colors.black87;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 50, color: Colors.grey.withAlpha(50));
  }

  // Form Edit
  void _showEditForm(bool isSuami) {
    final nameCtrl = TextEditingController(text: isSuami ? currentUserData['nama_suami'] : currentUserData['nama_istri']);
    final nikCtrl = TextEditingController(text: isSuami ? currentUserData['nik_suami'] : currentUserData['nik_istri']);
    final phoneCtrl = TextEditingController(text: isSuami ? currentUserData['phone_suami'] : currentUserData['phone_istri']);
    final emailCtrl = TextEditingController(text: isSuami ? currentUserData['email_suami'] : currentUserData['email_istri']);
    final alamatCtrl = TextEditingController(text: isSuami ? currentUserData['alamat_suami'] : currentUserData['alamat_istri']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Data Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildTextField('Nama Lengkap', nameCtrl),
              _buildTextField('NIK', nikCtrl),
              _buildTextField('Nomor HP', phoneCtrl),
              _buildTextField('Email', emailCtrl),
              _buildTextField('Alamat', alamatCtrl, maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19e62b),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => _updateProfile(nameCtrl.text, nikCtrl.text, phoneCtrl.text, emailCtrl.text, alamatCtrl.text),
                  child: const Text('SIMPAN PERUBAHAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _updateProfile(String name, String nik, String phone, String email, String alamat) async {
    Navigator.pop(context);
    setState(() => isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse("https://$_currentIp/catin_api/update_catin_profile.php"),
        body: {
          "catin_id": currentUserData['id'].toString(),
          "nama_aktif": currentUserData['nama_aktif'],
          "nama": name,
          "nik": nik,
          "phone": phone,
          "email": email,
          "alamat": alamat,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            currentUserData = data['user'];
            currentUserData['nama_aktif'] = name; // Update nama aktif jika berubah
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showUploadOptionSheet(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Unggah Dokumen $type",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "Pilih sumber untuk mengambil foto dokumen $type Anda.",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _uploadDocument(type, ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.camera_alt_outlined, size: 32, color: Color(0xFF19e62b)),
                            const SizedBox(height: 8),
                            const Text("Kamera", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _uploadDocument(type, ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.photo_outlined, size: 32, color: Color(0xFF19e62b)),
                            const SizedBox(height: 8),
                            const Text("Galeri", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadDocument(String type, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70, // Compress to ensure faster upload
    );

    if (image == null) return;

    // Tampilkan preview gambar sebelum mengunggah
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Preview Dokumen $type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(File(image.path), height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            const Text("Apakah Anda yakin ingin mengunggah dokumen ini? Pastikan gambar terlihat jelas."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF19e62b)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Unggah", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      var uri = Uri.parse("https://$_currentIp/catin_api/upload_catin_dokumen.php");
      var request = http.MultipartRequest('POST', uri);

      request.fields['catin_id'] = currentUserData['id'].toString();
      request.fields['nama_aktif'] = currentUserData['nama_aktif'] ?? '';
      request.fields['type'] = type;

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        image.path,
      );
      request.files.add(multipartFile);

      var streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$type berhasil diunggah!'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${data['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunggah dokumen ke server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
