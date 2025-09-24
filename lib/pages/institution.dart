import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InstitutionsPage extends StatefulWidget {
  const InstitutionsPage({super.key});

  @override
  State<InstitutionsPage> createState() => _InstitutionsPageState();
}

class _InstitutionsPageState extends State<InstitutionsPage> {
  final List<String> _institutions = const [
    "Alva’s Pre-University College, Vidyagiri",
    "Alva’s Degree College, Vidyagiri",
    "Alva’s Centre for Post Graduate Studies and Research, Vidyagiri",
    "Alva’s College of Education, Vidyagiri",
    "Alva’s College of Physical Education, Vidyagiri",
    // Professional & Medical Institutions
    "Alva’s Institute of Engineering & Technology (AIET), Mijar",
    "Alva’s Ayurvedic Medical College, Vidyagiri",
    "Alva’s Homeopathic Medical College, Mijar",
    "Alva’s College of Naturopathy and Yogic Science, Mijar",
    "Alva’s College of Physiotherapy, Moodbidri",
    "Alva’s College of Nursing, Moodbidri",
    "Alva’s Institute of Nursing, Moodbidri",
    "Alva’s College of Medical Laboratory Technology, Moodbidri",
    "Alva’s Law College, Moodbidri",
    // Other Notable
    "Alva’s College, Moodbidri (Affiliated with Mangalore University)",
    "Alva’s College of Nursing (Affiliated with Rajiv Gandhi University of Health Sciences, Bangalore)",
    "Alva’s Institute of Engineering & Technology (AIET) (Affiliated with Visvesvaraya Technological University, Belgaum)",
  ];

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<String> filtered = _institutions
        .where((i) => i.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Institutions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search institutions',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() { _query = v; }),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 3.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final name = filtered[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.school)),
                    title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => InstitutionDetailPage(institutionName: name)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class InstitutionDetailPage extends StatefulWidget {
  final String institutionName;
  const InstitutionDetailPage({super.key, required this.institutionName});

  @override
  State<InstitutionDetailPage> createState() => _InstitutionDetailPageState();
}

class _InstitutionDetailPageState extends State<InstitutionDetailPage> {
  final String _baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');
  bool _loading = true;
  String? _error;
  List<dynamic> _posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/content/institution-posts'));
      if (res.statusCode != 200) throw Exception('failed');
      final all = jsonDecode(res.body) as List<dynamic>;
      setState(() {
        _posts = all.where((p) => (p as Map<String, dynamic>)['institution']?.toString() == widget.institutionName).toList();
      });
    } catch (_) {
      setState(() { _error = 'Failed to load'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.institutionName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (_, i) {
                      final m = _posts[i] as Map<String, dynamic>;
                      final title = (m['title'] ?? '').toString();
                      final content = (m['content'] ?? m['description'] ?? '').toString();
                      final imageUrl = (m['imageUrl'] ?? '').toString();
                      final videoUrl = (m['videoUrl'] ?? '').toString();
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              if (imageUrl.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl.startsWith('http') ? imageUrl : '$_baseUrl$imageUrl',
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (videoUrl.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_outline, size: 48),
                                      const SizedBox(height: 8),
                                      Text(videoUrl, style: const TextStyle(color: Colors.black54)),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(content),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: _posts.length,
                  ),
                ),
    );
  }
}
