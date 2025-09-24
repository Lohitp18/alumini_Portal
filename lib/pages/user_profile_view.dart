import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserProfileViewPage extends StatefulWidget {
  final String userId;
  
  const UserProfileViewPage({super.key, required this.userId});

  @override
  State<UserProfileViewPage> createState() => _UserProfileViewPageState();
}

class _UserProfileViewPageState extends State<UserProfileViewPage> {
  final String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  Map<String, dynamic>? _userProfile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _userProfile = jsonDecode(response.body);
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'This profile is private';
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _error = 'User not found';
        });
      } else {
        setState(() {
          _error = 'Failed to load profile';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _userProfile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Profile not found',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile!['name'] ?? 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsDialog(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(),
              _buildAboutSection(),
              _buildExperienceSection(),
              _buildEducationSection(),
              _buildSkillsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Cover Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              image: _userProfile!['coverImage'] != null
                  ? DecorationImage(
                      image: NetworkImage(_userProfile!['coverImage']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _userProfile!['coverImage'] == null
                ? const Icon(Icons.image, size: 80, color: Colors.grey)
                : null,
          ),
          
          // Profile Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _userProfile!['profileImage'] != null
                      ? NetworkImage(_userProfile!['profileImage'])
                      : null,
                  child: _userProfile!['profileImage'] == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                
                const SizedBox(height: 16),
                
                // Name and Headline
                Text(
                  _userProfile!['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                if (_userProfile!['headline'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _userProfile!['headline'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                if (_userProfile!['location'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _userProfile!['location'],
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _sendConnectionRequest(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Connect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _sendMessage(),
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    if (_userProfile!['bio'] == null || _userProfile!['bio'].isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _userProfile!['bio'],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSection() {
    final experience = _userProfile!['experience'] as List<dynamic>? ?? [];
    
    if (experience.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Experience',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...experience.map((exp) => _buildExperienceItem(exp)),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp['title'] ?? 'No Title',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            exp['company'] ?? 'No Company',
            style: const TextStyle(fontSize: 14, color: Colors.blue),
          ),
          if (exp['location'] != null)
            Text(
              exp['location'],
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          Text(
            _formatDateRange(exp['startDate'], exp['endDate'], exp['current']),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (exp['description'] != null && exp['description'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              exp['description'],
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    final education = _userProfile!['education'] as List<dynamic>? ?? [];
    
    if (education.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Education',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...education.map((edu) => _buildEducationItem(edu)),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationItem(Map<String, dynamic> edu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            edu['school'] ?? 'No School',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            '${edu['degree'] ?? 'No Degree'} in ${edu['fieldOfStudy'] ?? 'No Field'}',
            style: const TextStyle(fontSize: 14, color: Colors.blue),
          ),
          Text(
            _formatDateRange(edu['startDate'], edu['endDate'], edu['current']),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (edu['description'] != null && edu['description'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              edu['description'],
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final skills = _userProfile!['skills'] as List<dynamic>? ?? [];
    
    if (skills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skills',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills.map((skill) => Chip(
                label: Text(skill),
                backgroundColor: Colors.blue.shade100,
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(String? startDate, String? endDate, bool? current) {
    String start = startDate != null ? DateTime.parse(startDate).year.toString() : '';
    String end = current == true 
        ? 'Present' 
        : endDate != null ? DateTime.parse(endDate).year.toString() : '';
    
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start - $end';
    } else if (start.isNotEmpty) {
      return start;
    } else {
      return '';
    }
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _blockUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Report User'),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _sendConnectionRequest() {
    // TODO: Implement connection request functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connection request sent!')),
    );
  }

  void _sendMessage() {
    // TODO: Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messaging feature coming soon!')),
    );
  }

  void _blockUser() {
    // TODO: Implement block user functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User blocked!')),
    );
  }

  void _reportUser() {
    // TODO: Implement report user functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User reported!')),
    );
  }
}
