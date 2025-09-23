import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  // TODO: set your backend base URL here or move to a config
  static const String _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000');
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  void _signIn() async {
    setState(() {
      _isLoading = true;
    });
    setState(() { _error = null; });

    try {
      final uri = Uri.parse('$_baseUrl/api/auth/signin');
      final response = await http.post(
        uri,
        headers: { 'Content-Type': 'application/json' },
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String token = data['token'] as String;
        await _secureStorage.write(key: 'auth_token', value: token);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in successfully')),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final Map<String, dynamic>? err = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        setState(() { _error = err != null && err['message'] is String ? err['message'] as String : 'Sign in failed'; });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Welcome Back",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),

              SizedBox(height: 8),
              Text(
                "Sign in to continue",
                style: TextStyle(color: Colors.black54),
              ),

              SizedBox(height: 28),

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

              // Email
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 20),

              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 10),

              // Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Checkbox(value: true, onChanged: (_) {}),
                    const Text('Remember me')
                  ]),
                  TextButton(
                    onPressed: () {},
                    child: const Text("Forgot Password?"),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Sign In Button
              _isLoading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      )),

              SizedBox(height: 20),

              // Sign Up link
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New here? "),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text("Create account",
                          style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                  ])
            ],
          ),
        ),
      ),
    );
  }
}
