import 'package:flutter/material.dart';

class ModeBanner extends StatelessWidget {
  const ModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      color: Colors.green.withValues(alpha: 0.18),
      child: Text(
        'MODO SUPABASE: Auth + PostgreSQL + RLS',
        style: TextStyle(
          color: Colors.green.shade800,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
