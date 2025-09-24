import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'post_opportunity.dart';
import 'package:url_launcher/url_launcher.dart';

class OpportunitiesPage extends StatefulWidget {
  const OpportunitiesPage({super.key});

  @override
  State<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends State<OpportunitiesPage> {
  final String _baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/content/opportunities'));
      if (res.statusCode != 200) throw Exception('failed');
      setState(() { _items = jsonDecode(res.body) as List<dynamic>; });
    } catch (_) {
      setState(() { _error = 'Failed to load'; });
    } finally {
      setState(() { _loading = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opportunities')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (_, i) {
                      final e = _items[i] as Map<String, dynamic>;
                      final title = (e['title'] ?? '').toString();
                      final company = (e['company'] ?? '').toString();
                      final apply = (e['applyLink'] ?? '').toString();
                      return Card(
                        child: ListTile(
                          title: Text(title),
                          subtitle: Text(company),
                          trailing: TextButton.icon(
                            onPressed: apply.isEmpty ? null : () async {
                              final uri = Uri.tryParse(apply);
                              if (uri != null) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            icon: const Icon(Icons.launch),
                            label: const Text('Apply'),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: _items.length,
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PostOpportunityPage()),
          ).then((_) => _load()); // Refresh after returning
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Opportunity'),
      ),
    );
  }
}

class OpportunitiePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Opportunities Page Content',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
