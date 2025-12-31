import 'package:flutter/material.dart';
import '../services/translator.dart';

class SearchButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SearchButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          label: Text(
            Translator.of('search_here'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.refresh, color: Colors.white),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}