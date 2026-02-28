import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pickup/core/api_config.dart';
import 'package:pickup/pages/register_page.dart';
import 'package:pickup/services/auth_service.dart';
import 'package:pickup/services/translator_service.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translator.of('insert_valid_credentials'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. CHIAMATA API PER LOGIN
      final response = await http.post(
        Uri.parse('${ApiConfig.url}/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailUsername': email,
          'password': password,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        // 2. ESTRAZIONE DEL TOKEN
        final data = jsonDecode(response.body);
        String token = data['access_token'];

        if (!mounted) return;

        // 3. SALVATAGGIO TRAMITE PROVIDER
        await Provider.of<AuthService>(context, listen: false).login(token);

        if (mounted) Navigator.pop(context);
      } else {
        _showError(Translator.of('invalid_credentials'));
      }
    } catch (e) {
      _showError("Errore durante il login: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Translator.of('personal_area')), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Icon(
              Icons.account_circle,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              Translator.of('welcome_back'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: Translator.of('email_or_username'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _passwordController,
              obscureText: true, // Nasconde i caratteri della password
              decoration: InputDecoration(
                labelText: Translator.of('password'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : Text(Translator.of('login_btn'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 15),

            // Bottone per iscriversi (stile diverso per distinguerlo)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              },
              child: Text(
                "${Translator.of('no_account')}${Translator.of('register_here')}",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}