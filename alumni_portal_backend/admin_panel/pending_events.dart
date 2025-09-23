import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PendingEventsPage extends StatefulWidget {
  @override
  State<PendingEventsPage> createState() => _PendingEventsPageState();
}

class _PendingEventsPageState extends State<PendingEventsPage> {
  List events = [];
  bool loading = false;
  String? error;

  final String baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/content/admin/pending-events'));
      if (res.statusCode != 200) throw Exception('Failed');
      setState(() { events = jsonDecode(res.body) as List; });
    } catch (e) {
      setState(() { error = 'Failed to load'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/content/admin/events/$id/status'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ 'status': status }),
      );
      if (res.statusCode == 200) {
        _load();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Events')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (_, i) {
                      final e = events[i] as Map<String, dynamic>;
                      return ListTile(
                        leading: e['imageUrl'] != null ? Image.network('$baseUrl${e['imageUrl']}', width: 56, height: 56, fit: BoxFit.cover) : const Icon(Icons.event),
                        title: Text((e['title'] ?? '').toString()),
                        subtitle: Text((e['description'] ?? '').toString()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateStatus(e['_id'], 'approved')),
                            IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _updateStatus(e['_id'], 'rejected')),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: events.length,
                  ),
                ),
    );
  }
}


