import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AlumniPage extends StatefulWidget {
  @override
  State<AlumniPage> createState() => _AlumniPageState();
}

class _AlumniPageState extends State<AlumniPage> {
  final String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
  bool _loading = true;
  String? _error;
  List<dynamic> _items = [];

  // Filters
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedYear;
  String? _selectedInstitution;
  String? _selectedCourse;

  // Mock lists for now; you can populate via API later
  final List<String> _years = [
    ...List<String>.generate(30, (i) => (DateTime.now().year - i).toString())
  ];
  final List<String> _institutions = <String>[
    'AIET','AIT','AIIMS','NIT','IIT'
  ];
  final List<String> _courses = <String>[
    'CSE','ECE','EEE','MECH','CIVIL','MBA','MCA'
  ];

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
      final params = <String, String>{};
      if (_selectedYear != null && _selectedYear!.isNotEmpty) params['year'] = _selectedYear!;
      if (_selectedInstitution != null && _selectedInstitution!.isNotEmpty) params['institution'] = _selectedInstitution!;
      if (_selectedCourse != null && _selectedCourse!.isNotEmpty) params['course'] = _selectedCourse!;
      if (_searchCtrl.text.trim().isNotEmpty) params['q'] = _searchCtrl.text.trim();

      final uri = Uri.parse('$_baseUrl/api/users/approved').replace(queryParameters: params.isEmpty ? null : params);
      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('failed');
      setState(() {
        _items = jsonDecode(res.body) as List<dynamic>;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load alumni';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alumni')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (_, i) {
                  final u = _items[i] as Map<String, dynamic>;
                  return _AlumniTile(user: u, baseUrl: _baseUrl);
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: _items.length,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search name or email',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.filter_alt),
                label: const Text('Apply'),
              )
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String?>(
                      value: _selectedYear,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Any')),
                        ..._years.map((y) => DropdownMenuItem<String?>(value: y, child: Text(y)))
                      ],
                      onChanged: (v) => setState(() { _selectedYear = v; }),
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 600 ? 220 : (constraints.maxWidth - 130) / 2 - 12,
                    child: DropdownButtonFormField<String?>(
                      value: _selectedInstitution,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Any institution')),
                        ..._institutions.map((i) => DropdownMenuItem<String?>(value: i, child: Text(i)))
                      ],
                      onChanged: (v) => setState(() { _selectedInstitution = v; }),
                      decoration: const InputDecoration(
                        labelText: 'Institution',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth > 600 ? 220 : (constraints.maxWidth - 130) / 2 - 12,
                    child: DropdownButtonFormField<String?>(
                      value: _selectedCourse,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Any course')),
                        ..._courses.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c)))
                      ],
                      onChanged: (v) => setState(() { _selectedCourse = v; }),
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}

class _AlumniTile extends StatefulWidget {
  final Map<String, dynamic> user;
  final String baseUrl;
  const _AlumniTile({required this.user, required this.baseUrl});

  @override
  State<_AlumniTile> createState() => _AlumniTileState();
}

class _AlumniTileState extends State<_AlumniTile> {
  bool _busy = false;
  bool _sent = false;

  Future<void> _connect() async {
    setState(() { _busy = true; });
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
      final res = await http.post(
        Uri.parse('${widget.baseUrl}/api/connections/${widget.user['_id']}'),
        headers: { 'Authorization': 'Bearer $token', 'Content-Type': 'application/json' },
      );
      if (res.statusCode == 201) {
        setState(() { _sent = true; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection request sent')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${res.statusCode}')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sending request')));
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text((u['name'] ?? '').toString()),
      subtitle: Text([
        (u['institution'] ?? '').toString(),
        (u['course'] ?? '').toString(),
        (u['year'] ?? '').toString(),
      ].where((e) => e.isNotEmpty).join(' • ')),
      trailing: _sent
          ? const Text('Requested', style: TextStyle(color: Colors.green))
          : ElevatedButton(
        onPressed: _busy ? null : _connect,
        child: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Connect'),
      ),
    );
  }
}
