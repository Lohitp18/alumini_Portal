import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  final String _baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Events'),
            Tab(text: 'Opportunities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingEvents(baseUrl: _baseUrl),
          _PendingOpportunities(baseUrl: _baseUrl),
        ],
      ),
    );
  }
}

class _PendingEvents extends StatefulWidget {
  final String baseUrl;
  const _PendingEvents({required this.baseUrl});

  @override
  State<_PendingEvents> createState() => _PendingEventsState();
}

class _PendingEventsState extends State<_PendingEvents> {
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
      final res = await http.get(Uri.parse('${widget.baseUrl}/api/content/admin/pending-events'));
      if (res.statusCode != 200) throw Exception('failed');
      setState(() { _items = jsonDecode(res.body) as List<dynamic>; });
    } catch (_) {
      setState(() { _error = 'Failed to load'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _act(String id, String status) async {
    try {
      final res = await http.put(
        Uri.parse('${widget.baseUrl}/api/content/admin/events/$id/status'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ 'status': status }),
      );
      if (res.statusCode == 200) _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_items.isEmpty) return const Center(child: Text('No pending events'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = _items[i] as Map<String, dynamic>;
          return ListTile(
            title: Text((e['title'] ?? '').toString()),
            subtitle: Text((e['description'] ?? '').toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _act(e['_id'].toString(), 'approved')),
                IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _act(e['_id'].toString(), 'rejected')),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PendingOpportunities extends StatefulWidget {
  final String baseUrl;
  const _PendingOpportunities({required this.baseUrl});

  @override
  State<_PendingOpportunities> createState() => _PendingOpportunitiesState();
}

class _PendingOpportunitiesState extends State<_PendingOpportunities> {
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
      final res = await http.get(Uri.parse('${widget.baseUrl}/api/content/admin/pending-opportunities'));
      if (res.statusCode != 200) throw Exception('failed');
      setState(() { _items = jsonDecode(res.body) as List<dynamic>; });
    } catch (_) {
      setState(() { _error = 'Failed to load'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _act(String id, String status) async {
    try {
      final res = await http.put(
        Uri.parse('${widget.baseUrl}/api/content/admin/opportunities/$id/status'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ 'status': status }),
      );
      if (res.statusCode == 200) _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_items.isEmpty) return const Center(child: Text('No pending opportunities'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = _items[i] as Map<String, dynamic>;
          return ListTile(
            title: Text((e['title'] ?? '').toString()),
            subtitle: Text((e['company'] ?? '').toString()),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _act(e['_id'].toString(), 'approved')),
                IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _act(e['_id'].toString(), 'rejected')),
              ],
            ),
          );
        },
      ),
    );
  }
}


