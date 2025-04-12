import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ordonnance.dart';
import '../models/medicament.dart';
import '../viewmodels/ordonnance_viewmodel.dart';

class ExempleCreationOrdonnance extends StatelessWidget {
  const ExempleCreationOrdonnance({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // Créer une ordonnance de test
          final ordonnance = Ordonnance(
            patientId: "12345",
            medecinId: "M789",
            clinique: "Clinique du Parc",
            specialite: "Médecine Générale",
            date: DateTime.now(),
            medicaments: [
              Medicament(
                name: "Doliprane",
                dosage: "1000mg",
               
                
              ),
            ],
          );

          final viewModel = context.read<OrdonnanceViewModel>();
          final response = await viewModel.createOrdonnance(ordonnance);
          final bool isSuccess =
              response.containsKey('id') && response['id'] != null;

          if (isSuccess) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ordonnance créée avec succès!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('Échec de la création de l\'ordonnance');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: const Text('Créer Ordonnance Test'),
    );
  }
}
