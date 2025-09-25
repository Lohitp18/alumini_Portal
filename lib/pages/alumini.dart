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

  // Mock lists for now; populate via API later
  final List<String> _years =
  List<String>.generate(30, (i) => (DateTime.now().year - i).toString());
  final List<String> _institutions = ['AIET', 'AIT', 'AIIMS', 'NIT', 'IIT'];
  final List<String> _courses = ['CSE', 'ECE', 'EEE', 'MECH', 'CIVIL', 'MBA', 'MCA'];

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

      final uri = Uri.parse('$_baseUrl/api/users/approved').replace(
        queryParameters: params.isEmpty ? null : params,
      );

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
      appBar: AppBar(
        title: const Text('Alumni'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: _items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          // Search + Apply button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Search name or email',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.filter_alt, size: 18),
                label: const Text('Apply', style: TextStyle(fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final dropdownWidth = isWide ? 180.0 : (constraints.maxWidth - 24) / 3 - 8;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDropdown(
                    label: 'Year',
                    value: _selectedYear,
                    items: ['Any', ..._years],
                    width: dropdownWidth,
                    onChanged: (v) => setState(() => _selectedYear = v == 'Any' ? null : v),
                  ),
                  _buildDropdown(
                    label: 'Institution',
                    value: _selectedInstitution,
                    items: ['Any', ..._institutions],
                    width: dropdownWidth,
                    onChanged: (v) => setState(() => _selectedInstitution = v == 'Any' ? null : v),
                  ),
                  _buildDropdown(
                    label: 'Course',
                    value: _selectedCourse,
                    items: ['Any', ..._courses],
                    width: dropdownWidth,
                    onChanged: (v) => setState(() => _selectedCourse = v == 'Any' ? null : v),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required double width,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value ?? 'Any',
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
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
    setState(() => _busy = true);
    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
      final res = await http.post(
        Uri.parse('${widget.baseUrl}/api/connections/${widget.user['_id']}'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (res.statusCode == 201) {
        setState(() => _sent = true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent')),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${res.statusCode}')),
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending request')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, color: Colors.blue, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (u['name'] ?? '').toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      (u['institution'] ?? '').toString(),
                      (u['course'] ?? '').toString(),
                      (u['year'] ?? '').toString(),
                    ].where((e) => e.isNotEmpty).join(' • '),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            _sent
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Requested',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _busy ? null : _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Connect', style: TextStyle(fontSize: 14)),
                  ),
          ],
        ),
      ),
    );
  }
}
