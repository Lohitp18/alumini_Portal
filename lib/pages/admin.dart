import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(text: 'Users'),
            Tab(text: 'Posts'),
            Tab(text: 'Events'),
            Tab(text: 'Opportunities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersAdmin(baseUrl: _baseUrl),
          _PostsAdmin(baseUrl: _baseUrl),
          _PendingEvents(baseUrl: _baseUrl),
          _PendingOpportunities(baseUrl: _baseUrl),
        ],
      ),
    );
  }
}

class _UsersAdmin extends StatefulWidget {
  final String baseUrl;
  const _UsersAdmin({required this.baseUrl});

  @override
  State<_UsersAdmin> createState() => _UsersAdminState();
}

class _UsersAdminState extends State<_UsersAdmin> {
  bool loading = true;
  String? error;
  bool showApproved = false;
  List<dynamic> items = [];

  Future<Map<String, String>> _authHeaders() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ' + token,
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final headers = await _authHeaders();
      final uri = showApproved
          ? Uri.parse(widget.baseUrl + '/admin/approved-users')
          : Uri.parse(widget.baseUrl + '/admin/users');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode != 200) throw Exception('failed');
      items = jsonDecode(res.body) as List<dynamic>;
    } catch (e) {
      error = 'Failed to load users';
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  Future<void> _act(String id, String action) async {
    try {
      final headers = await _authHeaders();
      final res = await http.patch(
        Uri.parse(widget.baseUrl + '/admin/' + action + '/' + id),
        headers: headers,
      );
      if (res.statusCode == 200) _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Pending'),
              selected: !showApproved,
              onSelected: (v) { setState(() { showApproved = false; }); _load(); },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Approved'),
              selected: showApproved,
              onSelected: (v) { setState(() { showApproved = true; }); _load(); },
            ),
          ],
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text(error!))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final u = items[i] as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Text((u['name'] ?? u['email'] ?? '').toString()),
                            subtitle: Text((u['email'] ?? '').toString()),
                            trailing: showApproved
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _act(u['_id'].toString(), 'approve')),
                                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _act(u['_id'].toString(), 'reject')),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _PostsAdmin extends StatefulWidget {
  final String baseUrl;
  const _PostsAdmin({required this.baseUrl});

  @override
  State<_PostsAdmin> createState() => _PostsAdminState();
}

class _PostsAdminState extends State<_PostsAdmin> {
  bool loading = true;
  String? error;
  bool showApproved = false;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final uri = showApproved
          ? Uri.parse(widget.baseUrl + '/api/content/posts')
          : Uri.parse(widget.baseUrl + '/api/content/admin/pending-posts');
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('failed');
      items = jsonDecode(res.body) as List<dynamic>;
    } catch (e) {
      error = 'Failed to load posts';
    } finally {
      if (mounted) setState(() { loading = false; });
    }
  }

  Future<void> _act(String id, String status) async {
    try {
      final res = await http.put(
        Uri.parse(widget.baseUrl + '/api/content/admin/posts/' + id + '/status'),
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({ 'status': status }),
      );
      if (res.statusCode == 200) _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Pending'),
              selected: !showApproved,
              onSelected: (v) { setState(() { showApproved = false; }); _load(); },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Approved'),
              selected: showApproved,
              onSelected: (v) { setState(() { showApproved = true; }); _load(); },
            ),
          ],
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text(error!))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final p = items[i] as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.article),
                            title: Text((p['title'] ?? '').toString()),
                            subtitle: Text((p['author'] ?? '').toString()),
                            trailing: showApproved
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _act(p['_id'].toString(), 'approved')),
                                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _act(p['_id'].toString(), 'rejected')),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
        ),
      ],
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


