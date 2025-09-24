import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController favTeacherController = TextEditingController();
  final TextEditingController socialMediaController = TextEditingController();

  String? _institution;
  String? _course;
  String? _year; // year of passed out

  final List<String> _institutions = <String>['AIET','AIT','AIIMS','NIT','IIT'];
  final List<String> _courses = <String>['CSE','ECE','EEE','MECH','CIVIL','MBA','MCA'];
  final List<String> _years = List<String>.generate(30, (i) => (DateTime.now().year - i).toString());

  bool _isLoading = false;
  String? _error;
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      setState(() { _error = null; });

      try {
        final uri = Uri.parse('$_baseUrl/api/auth/signup');
        final response = await http.post(
          uri,
          headers: { 'Content-Type': 'application/json' },
          body: jsonEncode({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'phone': phoneController.text.trim(),
            'dob': DateTime.tryParse(dobController.text) != null ? dobController.text : DateTime.now().toIso8601String(),
            'institution': _institution ?? '',
            'course': _course ?? '',
            'year': _year ?? '',
            'password': passwordController.text,
            'favTeacher': favTeacherController.text.trim(),
            'socialMedia': socialMediaController.text.trim(),
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 201) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final String token = data['token'] as String;
          await _secureStorage.write(key: 'auth_token', value: token);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registered successfully. Await approval.')),
          );
          Navigator.pop(context);
        } else {
          final Map<String, dynamic>? err = response.body.isNotEmpty ? jsonDecode(response.body) : null;
          setState(() { _error = err != null && err['message'] is String ? err['message'] as String : 'Sign up failed'; });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() { _error = 'Network error. Please try again.'; });
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Join the Alumni community",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.redAccent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 16),
              ],
              // Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) => value!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 10),

              // Email
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 10),

              // Phone
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? "Enter phone number" : null,
              ),
              const SizedBox(height: 10),

              // DOB
              TextFormField(
                controller: dobController,
                decoration: const InputDecoration(labelText: "Date of Birth"),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    dobController.text = "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                  }
                },
              ),
              const SizedBox(height: 10),

              // Institution dropdown
              DropdownButtonFormField<String>(
                value: _institution,
                items: [
                  ..._institutions.map((i) => DropdownMenuItem(value: i, child: Text(i)))
                ],
                onChanged: (v) => setState(() { _institution = v; }),
                decoration: const InputDecoration(labelText: "Institution"),
                validator: (v) => (v == null || v.isEmpty) ? 'Select institution' : null,
              ),
              const SizedBox(height: 10),

              // Course dropdown
              DropdownButtonFormField<String>(
                value: _course,
                items: [
                  ..._courses.map((c) => DropdownMenuItem(value: c, child: Text(c)))
                ],
                onChanged: (v) => setState(() { _course = v; }),
                decoration: const InputDecoration(labelText: "Course"),
                validator: (v) => (v == null || v.isEmpty) ? 'Select course' : null,
              ),
              const SizedBox(height: 10),

              // Year of passed-out dropdown
              DropdownButtonFormField<String>(
                value: _year,
                items: [
                  ..._years.map((y) => DropdownMenuItem(value: y, child: Text(y)))
                ],
                onChanged: (v) => setState(() { _year = v; }),
                decoration: const InputDecoration(labelText: "Year of Passed-out"),
                validator: (v) => (v == null || v.isEmpty) ? 'Select year' : null,
              ),
              const SizedBox(height: 10),

              // Password
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
              ),
              const SizedBox(height: 10),

              // Confirm Password
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Confirm Password"),
                validator: (value) => value != passwordController.text ? "Passwords don’t match" : null,
              ),
              const SizedBox(height: 10),

              // Favorite Teacher
              TextFormField(
                controller: favTeacherController,
                decoration: const InputDecoration(labelText: "Favourite Teacher"),
              ),
              const SizedBox(height: 10),

              // Social Media
              TextFormField(
                controller: socialMediaController,
                decoration: const InputDecoration(labelText: "Social Media Link"),
              ),
              const SizedBox(height: 20),

              // Submit Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
