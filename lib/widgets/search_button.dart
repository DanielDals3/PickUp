import 'package:flutter/material.dart';
import '../services/translator_service.dart';

class SearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SearchButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      label: Text(
        Translator.of('search_here'),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      icon: const Icon(Icons.refresh, color: Colors.white),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }
}