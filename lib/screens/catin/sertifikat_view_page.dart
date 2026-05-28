import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class SertifikatViewPage extends StatelessWidget {
  final String pdfUrl;
  final String downloadUrl;
  final String title;

  const SertifikatViewPage({
    super.key,
    required this.pdfUrl,
    required this.downloadUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF19e62b),
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat Sertifikat: ${details.description}')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final Uri url = Uri.parse(downloadUrl);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Gagal mengunduh sertifikat.")),
              );
            }
          }
        },
        label: const Text("UNDUH PDF"),
        icon: const Icon(Icons.download),
        backgroundColor: const Color(0xFF19e62b),
      ),
    );
  }
}
