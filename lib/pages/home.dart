import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_profile_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  bool _loading = true;
  String? _error;
  List<dynamic> _posts = [];

  Future<void> _logout(BuildContext context) async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$_baseUrl/api/content/events')),
        http.get(Uri.parse('$_baseUrl/api/content/opportunities')),
        http.get(Uri.parse('$_baseUrl/api/content/posts')),
        http.get(Uri.parse('$_baseUrl/api/content/institution-posts')),
      ]);

      if (responses.any((r) => r.statusCode != 200)) {
        throw Exception('Failed to fetch content');
      }

      List<dynamic> events = jsonDecode(responses[0].body) as List<dynamic>;
      List<dynamic> opportunities =
      jsonDecode(responses[1].body) as List<dynamic>;
      List<dynamic> posts = jsonDecode(responses[2].body) as List<dynamic>;
      List<dynamic> institutionPosts =
      jsonDecode(responses[3].body) as List<dynamic>;

      List<dynamic> allPosts = []
        ..addAll(events)
        ..addAll(opportunities)
        ..addAll(posts)
        ..addAll(institutionPosts);

      allPosts.sort((a, b) {
        DateTime dateA = DateTime.tryParse(a['date']?.toString() ??
            a['createdAt']?.toString() ??
            '') ??
            DateTime.now();
        DateTime dateB = DateTime.tryParse(b['date']?.toString() ??
            b['createdAt']?.toString() ??
            '') ??
            DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        _posts = allPosts;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load content';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _getBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
          ],
        ),
      );
    } else if (_posts.isEmpty) {
      return const Center(child: Text('Nothing to show yet'));
    } else {
      return RefreshIndicator(
        onRefresh: _loadAll,
        child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final item = _posts[index] as Map<String, dynamic>;
                final title = (item['title'] ?? '').toString();
                final subtitle = (item['date'] ??
                    item['company'] ??
                    item['author'] ??
                    item['institution'] ??
                    '')
                    .toString();
                final type = item['type'] ?? item['category'] ?? 'Post';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post header with user info (clickable)
                      _buildUserInfoHeader(item),

                      const SizedBox(height: 8),

                      // Post header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type.toString(),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Subtitle (date/author/institution/etc.)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                      ),

                      const SizedBox(height: 8),

                      // Post content
                      if (item['content'] != null &&
                          item['content'].toString().isNotEmpty)
                        Text(
                          item['content'],
                          style: const TextStyle(fontSize: 14),
                        ),

                      const SizedBox(height: 8),

                      // Show first image if exists
                      if (item['images'] != null &&
                          item['images'] is List &&
                          (item['images'] as List).isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['images'][0],
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _LikeButton(
                            postId: item['_id'],
                            baseUrl: _baseUrl,
                            initialLiked: item['isLiked'] ?? false,
                            initialLikeCount: item['likeCount'] ?? item['likes']?.length ?? 0,
                          ),
                          _ReportButton(
                            postId: item['_id'],
                            baseUrl: _baseUrl,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const _CreatePostPage()),
                  ).then((_) => _loadAll());
                },
                icon: const Icon(Icons.post_add),
                label: const Text('Post'),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildUserInfoHeader(Map<String, dynamic> item) {
    // Get user information from the populated data
    final author = item['authorId'] ?? item['postedBy'];
    final authorName = author?['name'] ?? item['author'] ?? 'Unknown User';
    final authorImage = author?['profileImage'];
    
    return Row(
      children: [
        // Profile picture (clickable)
        GestureDetector(
          onTap: () => _navigateToUserProfile(author?['_id']),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: authorImage != null 
                ? NetworkImage(authorImage) 
                : null,
            child: authorImage == null 
                ? const Icon(Icons.person, color: Colors.grey, size: 16)
                : null,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // User name (clickable)
        GestureDetector(
          onTap: () => _navigateToUserProfile(author?['_id']),
          child: Text(
            authorName,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToUserProfile(String? userId) {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileViewPage(userId: userId),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(),
    );
  }
}

class _CreatePostPage extends StatefulWidget {
  const _CreatePostPage();
  @override
  State<_CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<_CreatePostPage> {
  final String _baseUrl = const String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000');
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
    });
    try {
      final token =
          await const FlutterSecureStorage().read(key: 'auth_token') ?? '';
      final res = await http.post(
        Uri.parse('$_baseUrl/api/posts'),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': _titleCtrl.text.trim(),
          'content': _contentCtrl.text.trim(),
        }),
      );
      if (res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Post submitted for verification')));
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${res.statusCode}')));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Network error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                    labelText: 'Content', border: OutlineInputBorder()),
                maxLines: 5,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Submit'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _LikeButton extends StatefulWidget {
  final String postId;
  final String baseUrl;
  final bool initialLiked;
  final int initialLikeCount;

  const _LikeButton({
    required this.postId,
    required this.baseUrl,
    required this.initialLiked,
    required this.initialLikeCount,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  late bool _isLiked;
  late int _likeCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLiked;
    _likeCount = widget.initialLikeCount;
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required');
      }

      final response = await http.patch(
        Uri.parse('${widget.baseUrl}/api/posts/${widget.postId}/like'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isLiked = data['liked'];
          _likeCount = data['likeCount'];
        });
      } else {
        throw Exception('Failed to toggle like');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update like: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _isLoading ? null : _toggleLike,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
              size: 18,
              color: _isLiked ? Colors.blue : Colors.grey,
            ),
      label: Text(
        _likeCount > 0 ? '$_likeCount' : 'Like',
        style: TextStyle(
          color: _isLiked ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  final String postId;
  final String baseUrl;

  const _ReportButton({
    required this.postId,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _showReportDialog(context),
      icon: const Icon(Icons.flag_outlined, color: Colors.red, size: 18),
      label: const Text('Report'),
    );
  }

  void _showReportDialog(BuildContext context) {
    String? selectedReason;
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please select a reason for reporting this post:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'spam', child: Text('Spam')),
                DropdownMenuItem(value: 'inappropriate_content', child: Text('Inappropriate Content')),
                DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                DropdownMenuItem(value: 'false_information', child: Text('False Information')),
                DropdownMenuItem(value: 'copyright_violation', child: Text('Copyright Violation')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) {
                selectedReason = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Additional Details (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Please provide more details...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitReport(context, selectedReason, descriptionController.text),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(BuildContext context, String? reason, String description) async {
    if (reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/posts/$postId/report'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reason': reason,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to submit report');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    }
  }
}
