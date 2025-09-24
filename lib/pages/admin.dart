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
  final String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
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
          isScrollable: true,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
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
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final headers = await _authHeaders();
      final uri = showApproved
          ? Uri.parse('${widget.baseUrl}/api/admin/approved-users')
          : Uri.parse('${widget.baseUrl}/api/admin/users');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode != 200) throw Exception('failed');
      items = jsonDecode(res.body) as List<dynamic>;
    } catch (_) {
      error = 'Failed to load users';
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _act(String id, String action) async {
    try {
      final headers = await _authHeaders();
      final res = await http.patch(
        Uri.parse('${widget.baseUrl}/api/admin/$action/$id'),
        headers: headers,
      );
      if (res.statusCode == 200) _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _StatCard(label: showApproved ? 'Approved' : 'Pending', value: items.length),
                  ChoiceChip(
                    label: const Text('Pending'),
                    selected: !showApproved,
                    onSelected: (v) { setState(() { showApproved = false; }); _load(); },
                  ),
                  ChoiceChip(
                    label: const Text('Approved'),
                    selected: showApproved,
                    onSelected: (v) { setState(() { showApproved = true; }); _load(); },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.post_add),
                    label: const Text('Post to Institution'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CreateInstitutionPostPage(baseUrl: widget.baseUrl),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final u = items[i] as Map<String, dynamic>;
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text((u['name'] ?? u['email'] ?? '').toString()),
                              subtitle: Text((u['email'] ?? '').toString()),
                              trailing: showApproved
                                  ? null
                                  : Wrap(spacing: 4, children: [
                                      IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _act(u['_id'].toString(), 'approve')),
                                      IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _act(u['_id'].toString(), 'reject')),
                                    ]),
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

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  const _StatCard({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _CreateInstitutionPostPage extends StatefulWidget {
  final String baseUrl;
  const _CreateInstitutionPostPage({required this.baseUrl});

  @override
  State<_CreateInstitutionPostPage> createState() =>
      _CreateInstitutionPostPageState();
}

class _CreateInstitutionPostPageState
    extends State<_CreateInstitutionPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String? _institution;
  bool _submitting = false;

  final List<String> _institutions = const [
    "Alva’s Pre-University College, Vidyagiri",
    "Alva’s Degree College, Vidyagiri",
    "Alva’s Centre for Post Graduate Studies and Research, Vidyagiri",
    "Alva’s College of Education, Vidyagiri",
    "Alva’s College of Physical Education, Vidyagiri",
    "Alva’s Institute of Engineering & Technology (AIET), Mijar",
    "Alva’s Ayurvedic Medical College, Vidyagiri",
    "Alva’s Homeopathic Medical College, Mijar",
    "Alva’s College of Naturopathy and Yogic Science, Mijar",
    "Alva’s College of Physiotherapy, Moodbidri",
    "Alva’s College of Nursing, Moodbidri",
    "Alva’s Institute of Nursing, Moodbidri",
    "Alva’s College of Medical Laboratory Technology, Moodbidri",
    "Alva’s Law College, Moodbidri",
    "Alva’s College, Moodbidri (Affiliated with Mangalore University)",
    "Alva’s College of Nursing (Affiliated with Rajiv Gandhi University of Health Sciences, Bangalore)",
    "Alva’s Institute of Engineering & Technology (AIET) (Affiliated with Visvesvaraya Technological University, Belgaum)",
  ];

  Future<Map<String, String>> _authHeaders() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
    });
    try {
      final headers = await _authHeaders();
      final res = await http.post(
        Uri.parse('${widget.baseUrl}/api/content/institution-posts'),
        headers: headers,
        body: jsonEncode({
          'institution': _institution,
          'title': _titleCtrl.text.trim(),
          'content': _contentCtrl.text.trim(),
          'status': 'approved',
        }),
      );
      if (res.statusCode == 201 && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Institution post created')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${res.statusCode}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request failed')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post to Institution')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _institution, // ✅ shows current selection
                items: _institutions
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _institution = v;
                  });
                },
                decoration: const InputDecoration(labelText: 'Institution'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Select institution' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(labelText: 'Content'),
                minLines: 3,
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Content required'
                    : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- POSTS ADMIN --------------------

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

  Future<Map<String, String>> _authHeaders() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final headers = await _authHeaders();
      final uri = showApproved
          ? Uri.parse('${widget.baseUrl}/api/admin/approved-posts')
          : Uri.parse('${widget.baseUrl}/api/admin/pending-posts');
      final res = await http.get(uri, headers: headers);
      if (res.statusCode != 200) throw Exception('failed');
      items = jsonDecode(res.body) as List<dynamic>;
    } catch (_) {
      error = 'Failed to load posts';
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _act(String id, String status) async {
    try {
      final headers = await _authHeaders();
      final res = await http.put(
        Uri.parse('${widget.baseUrl}/api/admin/posts/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
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
              onSelected: (v) {
                setState(() {
                  showApproved = false;
                });
                _load();
              },
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Approved'),
              selected: showApproved,
              onSelected: (v) {
                setState(() {
                  showApproved = true;
                });
                _load();
              },
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
                      IconButton(
                        icon: const Icon(Icons.check,
                            color: Colors.green),
                        onPressed: () => _act(
                            p['_id'].toString(), 'approved'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red),
                        onPressed: () => _act(
                            p['_id'].toString(), 'rejected'),
                      ),
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

// -------------------- PENDING EVENTS --------------------

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http.get(
          Uri.parse('${widget.baseUrl}/api/admin/pending-events'), headers: headers);
      if (res.statusCode != 200) throw Exception('failed');
      setState(() {
        _items = jsonDecode(res.body) as List<dynamic>;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _act(String id, String status) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http.put(
        Uri.parse('${widget.baseUrl}/api/admin/events/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
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
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () =>
                      _act(e['_id'].toString(), 'approved'),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () =>
                      _act(e['_id'].toString(), 'rejected'),
                ),
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
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http.get(Uri.parse('${widget.baseUrl}/api/admin/pending-opportunities'), headers: headers);
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
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final res = await http.put(
        Uri.parse('${widget.baseUrl}/api/admin/opportunities/$id/status'),
        headers: headers,
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


