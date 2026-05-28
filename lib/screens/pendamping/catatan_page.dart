import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'dashboard_pendamping.dart';
import '../catin/materi_page.dart';

class CatatanPage extends StatefulWidget {
  final Map<String, dynamic> peserta;
  final Map userData; // pendamping data
  
  const CatatanPage({super.key, required this.peserta, required this.userData});

  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isLoading = true;
  String _currentIp = 'farel.dwirez.app';
  List<dynamic> _messages = []; // Will store chat messages
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadIpAndFetch();
    // Auto refresh chat every 5 seconds for real-time experience
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) => _fetchMessages(showLoading: false));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadIpAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('api_ip') ?? 'farel.dwirez.app';
    });
    await _fetchMessages();
  }

  Future<void> _fetchMessages({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    try {
      final catinId = widget.peserta['id'];
      final pendampingId = widget.userData['id'];
      final url = Uri.parse("https://$_currentIp/pendamping_api/get_catatan.php?catin_id=$catinId&pendamping_id=$pendampingId");
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _messages = data['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Optimistic update
    setState(() {
      _messages.insert(0, {
        'pesan': text,
        'pengirim': 'pendamping',
        'waktu': DateTime.now().toString(),
        'is_sending': true,
      });
    });

    try {
      final url = Uri.parse("https://$_currentIp/pendamping_api/update_catatan.php");
      final response = await http.post(url, body: {
        'catin_id': widget.peserta['id'].toString(),
        'pendamping_id': widget.userData['id'].toString(),
        'catatan': text,
      }).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _fetchMessages(showLoading: false);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengirim pesan.")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nama = widget.peserta['nama_individu'] ?? 'Peserta';
    const primaryColor = Color(0xFF19e62b);
    const chatBg = Color(0xFFF4F6F4);

    return Scaffold(
      backgroundColor: chatBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text("Chat: $nama", style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("ONLINE • PENDAMPINGAN", style: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5)),
          ],
        ),
        centerTitle: true,
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8F5E9),
            child: Icon(
              widget.peserta['peran'] == 'suami' ? Icons.face : Icons.face_4,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : _messages.isEmpty
                    ? _buildEmptyState(primaryColor)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        reverse: true, // Chat starts from bottom
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['pengirim'] == 'pendamping';
                          return _buildChatBubble(msg, isMe, primaryColor);
                        },
                      ),
          ),
          _buildMessageInput(primaryColor),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Catatan is index 2
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => DashboardPendamping(userData: widget.userData)), (route) => false);
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MateriPage(userData: widget.userData)));
          } else if (index == 3) {
            // Profile - usually handles settings or details
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Materi"),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 80, color: color.withAlpha(100)),
          const SizedBox(height: 16),
          Text(
            "Mulai Diskusi",
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Tulis pesan atau catatan untuk memberikan bimbingan kepada calon pengantin ini secara langsung.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isMe, Color color) {
    final String pesan = msg['pesan'] ?? '';
    final String waktuRaw = msg['waktu'] ?? '';
    
    // Format waktu
    String waktu = "";
    if (waktuRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(waktuRaw);
        waktu = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (e) {
        waktu = waktuRaw.split(' ').last.substring(0, 5);
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? color : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pesan,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  waktu,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: isMe ? Colors.white70 : Colors.grey[500],
                  ),
                ),
                if (isMe && msg['is_sending'] == true) ...[
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: "Tulis pesan bimbingan...",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
