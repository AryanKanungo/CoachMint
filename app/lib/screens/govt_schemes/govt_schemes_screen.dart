import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../common_widgets/widgets.dart';
import '../../services/scheme_service.dart'; // Updated path to match lib/services/

class GovtSchemesScreen extends StatefulWidget {
  const GovtSchemesScreen({super.key});

  @override
  State<GovtSchemesScreen> createState() => _GovtSchemesScreenState();
}

class _GovtSchemesScreenState extends State<GovtSchemesScreen> {
  final SchemeService _service = SchemeService();
  late Future<List<Map<String, dynamic>>> _schemesFuture;

  @override
  void initState() {
    super.initState();
    _schemesFuture = _service.fetchWelfareSchemes();
  }

  Future<void> _launchSchemeURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No application link available for this scheme.')),
        );
      }
      return;
    }

    final Uri url = Uri.parse(urlString);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121417),
      appBar: AppBar(
        title: const Text('Government Schemes', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _schemesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)));
          }

          final schemes = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: schemes.length,
            itemBuilder: (context, index) {
              final scheme = schemes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2126),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scheme['name'] ?? 'Unknown Scheme',
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 20, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scheme['description'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6), 
                        fontSize: 14, 
                        height: 1.4
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white10),
                    ),
                    _buildTag("Who can apply?", scheme['eligibility']),
                    const SizedBox(height: 12),
                    _buildTag("Required Documents", scheme['documents']),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)
                          ),
                        ),
                        onPressed: () => _launchSchemeURL(scheme['apply_url']), 
                        child: const Text('Apply Now', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTag(String label, dynamic data) {
    String displayValue = "";
    if (data is List) {
      displayValue = data.join(" • ");
    } else if (data is Map) {
      displayValue = data.entries.map((e) => "${e.key}: ${e.value}").join(", ");
    } else {
      displayValue = data?.toString() ?? "Not specified";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), 
          style: const TextStyle(
            color: Color(0xFF00E676), 
            fontSize: 11, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.2
          )
        ),
        const SizedBox(height: 4),
        Text(displayValue, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}