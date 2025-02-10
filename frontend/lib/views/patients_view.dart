
import 'package:flutter/material.dart';

class PatientsView extends StatelessWidget {
  const PatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Patients Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'Your patient list will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}