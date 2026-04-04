import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pickup/core/api_config.dart';
import 'package:pickup/services/translator_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  List<dynamic> _countries = [];
  String? _selectedCountryId;
  bool _isLoadingCountries = true;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.url}/countries/getCountries'));
      if (response.statusCode == 200) {
        setState(() {
          _countries = jsonDecode(response.body);
          _isLoadingCountries = false;
        });
      }
    } catch (e) {
      print("Errore caricamento stati: $e");
      setState(() => _isLoadingCountries = false);
    }
  }

  Future<Iterable<Map<String, dynamic>>> _getCitySuggestions(String query) async {
    if (query.length < 3) return const Iterable.empty();
    
    final url = Uri.parse(
        'https://photon.komoot.io/api/?q=$query&limit=5');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200 || response.statusCode == 403) { // 403 è usato come "successo" per la lista dei paesi, anche se non è il codice ideale
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>(); // Converte la lista in mappe compatibili
      }
    } catch (e) {
      debugPrint("Errore: $e");
    }
    return const Iterable.empty();
  }

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
        _emailController.text.isEmpty ||
        _selectedCountryId == null) {
      _showError(Translator.of('name_surname_email_required'));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(Translator.of('passwords_do_not_match'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // NOTA: Se usi l'emulatore Android, 'localhost' va sostituito con '10.0.2.2'
      final url = Uri.parse('${ApiConfig.url}/users/register');

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
          'countryId': int.parse(_selectedCountryId!),
          'birthDate': _selectedDate
              ?.toIso8601String(), // Inviamo la data in formato standard
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Translator.of('account_created_successfully')),
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
      appBar: AppBar(title: Text(Translator.of('create_account'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              Translator.of('sign_up_title'),
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
                    Translator.of('name'),
                    Icons.person_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _lastNameController,
                    Translator.of('surname'),
                    Icons.person_outline,
                  ),
                ),
              ],
            ),

            _buildTextField(
              _emailController,
              Translator.of('email'),
              Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),

            // Data di nascita con selettore
            _buildTextField(
              _birthDateController,
              Translator.of('birth_date'),
              Icons.cake_outlined,
              readOnly: true,
              onTap: () => _selectDate(context),
            ),

            _buildTextField(
              _addressController,
              Translator.of('address'),
              Icons.home_outlined,
            ),

            // Città e Provincia affiancate
            // TODO fare in modo che dia dei suggerimenti automatici per città e provincia - fare in modo furbo, non scopito a codice
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: RawAutocomplete<Map<String, dynamic>>( // Specifichiamo il tipo esatto invece di dynamic
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  return await _getCitySuggestions(textEditingValue.text);
                },
                displayStringForOption: (Map<String, dynamic> option) {
                  final address = option['address'] as Map<String, dynamic>? ?? {};
                  return address['city']?.toString() ?? 
                        address['town']?.toString() ?? 
                        address['village']?.toString() ?? 
                        option['display_name']?.toString() ?? "";
                },
                // CAMPO DI TESTO
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: Translator.of('city'),
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                // LA LISTA DEI SUGGERIMENTI (Risolve l'errore di layout)
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        // Constraints risolve i problemi di "weight/width"
                        constraints: BoxConstraints(
                          maxHeight: 250, 
                          maxWidth: MediaQuery.of(context).size.width - 48,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            final address = option['address'] as Map<String, dynamic>? ?? {};
                            
                            final name = address['city']?.toString() ?? 
                                        address['town']?.toString() ?? 
                                        address['village']?.toString() ?? "Città";
                            
                            final sub = address['county']?.toString() ?? 
                                        address['state']?.toString() ?? "";

                            return ListTile(
                              title: Text(name),
                              subtitle: Text(sub),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (selection) {
                  setState(() {
                    final address = selection['address'] as Map<String, dynamic>? ?? {};
                    String cityName = address['city']?.toString() ?? 
                                      address['town']?.toString() ?? 
                                      address['village']?.toString() ?? "";
                    String province = address['county']?.toString() ?? 
                                      address['state']?.toString() ?? "";
                    
                    _cityController.text = cityName;
                    _provinceController.text = province;
                  });
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: DropdownButtonFormField<String>(
                value: _selectedCountryId,
                items: _countries.map((c) => DropdownMenuItem<String>(
                  value: c['id'].toString(),
                  child: Text(c['name']),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCountryId = val),
                decoration: InputDecoration(
                  labelText: Translator.of('country'),
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                hint: Text(_isLoadingCountries ? "Caricamento stati..." : "Seleziona Stato"),
              ),
            ),

            const Divider(height: 40),

            _buildTextField(
              _passwordController,
              Translator.of('password'),
              Icons.lock_outline,
              isPassword: true,
            ),
            _buildTextField(
              _confirmPasswordController,
              Translator.of('confirm_password'),
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
                  : Text(
                      Translator.of('register_btn'),
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
