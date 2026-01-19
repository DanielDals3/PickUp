import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedDate;

  // Funzione per selezionare la data di nascita
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _performRegister() async {
    // Validazione: controlliamo che i campi principali non siano vuoti
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty) {
      _showError("Nome, Cognome ed Email sono obbligatori");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Le password non coincidono!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // NOTA: Se usi l'emulatore Android, 'localhost' va sostituito con '10.0.2.2'
      final url = Uri.parse('http://10.0.2.2:3000/users/register');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'city': _cityController.text,
          'address': _addressController.text,
          'province': _provinceController.text,
          'country': _countryController.text,
          'birthDate': _selectedDate
              ?.toIso8601String(), // Inviamo la data in formato standard
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account creato con successo!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        _showError("Errore durante la registrazione: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Errore di rete: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Funzione di utilità per creare i campi di testo più velocemente
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crea Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Unisciti a PickUp",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Nome e Cognome affiancati
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _firstNameController,
                    "Nome",
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _lastNameController,
                    "Cognome",
                    Icons.person_outline,
                  ),
                ),
              ],
            ),

            _buildTextField(
              _emailController,
              "Email",
              Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),

            // Data di nascita con selettore
            _buildTextField(
              _birthDateController,
              "Data di Nascita",
              Icons.cake_outlined,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),

            _buildTextField(
              _addressController,
              "Indirizzo",
              Icons.home_outlined,
            ),

            // Città e Provincia affiancate
            // TODO fare in modo che dia dei suggerimenti automatici per città e provincia - fare in modo furbo, non scopito a codice
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    _cityController,
                    "Città",
                    Icons.location_city,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    _provinceController,
                    "Prov.",
                    Icons.map_outlined,
                  ),
                ),
              ],
            ),

            _buildTextField(_countryController, "Stato", Icons.public),

            const Divider(height: 40),

            _buildTextField(
              _passwordController,
              "Password",
              Icons.lock_outline,
              isPassword: true,
            ),
            _buildTextField(
              _confirmPasswordController,
              "Conferma Password",
              Icons.lock_reset,
              isPassword: true,
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
              onPressed: _isLoading ? null : _performRegister,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "REGISTRATI",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
