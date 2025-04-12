import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/navigation_service.dart';
import '../models/medicament.dart';
import '../viewmodels/ordonnance_viewmodel.dart';
import '../widgets/signature_pad.dart';
import '../widgets/cachet_medecin.dart';
import 'pdf_actions_screen.dart';
import '../models/ordonnance.dart';
import '../theme/style_constants.dart';
import '../services/screen_size_service.dart';
import '../services/voice_recognition_service.dart';
import '../services/ocr_service.dart';

class OrdonnanceScreen extends StatefulWidget {
  const OrdonnanceScreen({Key? key}) : super(key: key);

  @override
  State<OrdonnanceScreen> createState() => _OrdonnanceScreenState();
}

class _OrdonnanceScreenState extends State<OrdonnanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController();
  final _medecinIdController = TextEditingController();
  final _searchController = TextEditingController();
  final _cliniqueController = TextEditingController();
  final _specialiteController = TextEditingController();
  List<Medicament> medicaments = [];
  Uint8List? _signature;
  Uint8List? _cachet;
  bool isSearching = false;
  final VoiceRecognitionService _voiceService = VoiceRecognitionService();
  final List<OcrService> _ocrServices = [
    GoogleMLKitOcr(),
    ManualOcrService(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = ScreenSizeService();

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Ordonnance')),
      body: Consumer<OrdonnanceViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: screenSize.defaultPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPatientInfo(),
                  SizedBox(height: screenSize.getScaledSize(20)),
                  _buildMedicamentSearch(viewModel),
                  SizedBox(height: screenSize.getScaledSize(20)),
                  _buildMedicamentsList(),
                  SizedBox(height: screenSize.getScaledSize(20)),
                  _buildSignatureAndCachet(),
                  SizedBox(height: screenSize.getScaledSize(20)),
                  _buildActionButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientInfo() {
    final screenSize = ScreenSizeService();
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenSize.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildLogoHeader(),
            const SizedBox(height: 20),
            _buildInfoField(
              controller: _patientIdController,
              label: 'ID Patient',
              hint: 'Entrez l\'ID du patient',
              icon: StyleConstants.patientIcon,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildInfoField(
              controller: _medecinIdController,
              label: 'ID Médecin',
              hint: 'Entrez l\'ID du médecin',
              icon: StyleConstants.medecinIdIcon,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildInfoField(
              controller: _cliniqueController,
              label: 'Clinique',
              hint: 'Nom de la clinique',
              icon: StyleConstants.cliniqueIcon,
            ),
            const SizedBox(height: 16),
            _buildInfoField(
              controller: _specialiteController,
              label: 'Spécialité',
              hint: 'Spécialité du médecin',
              icon: StyleConstants.specialiteIcon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/logo.png',
            height: 60,
            width: 60,
          ),
          const SizedBox(height: 8),
          const Text(
            'Nouvelle Ordonnance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: StyleConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
  }) {
    return Container(
      decoration: StyleConstants.textFieldDecoration,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: StyleConstants.primaryColor),
          suffixIcon: required
              ? const Icon(Icons.star,
                  size: 8, color: StyleConstants.errorColor)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade100),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: StyleConstants.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: required
            ? (value) => value?.isEmpty ?? true ? 'Ce champ est requis' : null
            : null,
      ),
    );
  }

  Widget _buildMedicamentSearch(OrdonnanceViewModel viewModel) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un médicament...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      onChanged: (value) =>
                          _searchMedicaments(value, viewModel),
                    ),
                  ),
                  // Bouton OCR
                  IconButton(
                    icon: const Icon(Icons.document_scanner,
                        color: Colors.purple),
                    onPressed: () => _scanMedicamentWithOCR(),
                    tooltip: 'Scanner une ordonnance',
                  ),
                  // Bouton Microphone
                  IconButton(
                    icon: Icon(
                      _voiceService.isListening ? Icons.mic : Icons.mic_none,
                      color:
                          _voiceService.isListening ? Colors.red : Colors.blue,
                    ),
                    onPressed: () => _startVoiceRecognition(viewModel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Résultats de recherche
            if (viewModel.searchResults?.isNotEmpty ?? false)
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewModel.searchResults!.length,
                  itemBuilder: (context, index) {
                    final med = viewModel.searchResults![index];
                    return _buildMedicamentCard(med);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicamentCard(Medicament med) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showMedicamentDetails(med),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(med.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        )),
                  ),
                  _buildAddButton(med),
                ],
              ),
              if (med.dosage != null)
                _buildInfoRow(Icons.medical_services, 'Dosage:', med.dosage!),
              if (med.usage != null)
                _buildInfoRow(Icons.info, 'Usage:', med.usage!),
              if (med.route != null)
                _buildInfoRow(Icons.route, 'Voie:', med.route!),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedicamentDetails(Medicament med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(med.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (med.usage != null)
                _buildInfoRow(Icons.info, 'Usage:', med.usage!),
              if (med.dosage != null)
                _buildInfoRow(Icons.medical_services, 'Dosage:', med.dosage!),
              if (med.route != null)
                _buildInfoRow(Icons.route, 'Voie:', med.route!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[300]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _searchMedicaments(String value, OrdonnanceViewModel viewModel) async {
    if (value.isEmpty) {
      viewModel.clearResults();
      return;
    }

    setState(() => isSearching = true);
    await viewModel.fetchMedicaments(value);
    setState(() => isSearching = false);
  }

  Widget _buildMedicamentsList() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(Icons.medical_services, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Médicaments Prescrits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (medicaments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Aucun médicament sélectionné',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medicaments.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  _buildMedicamentItem(medicaments[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton(Medicament med) {
    return IconButton(
      icon: const Icon(Icons.add_circle, color: Colors.green),
      onPressed: () => _addMedicament(med),
      tooltip: 'Ajouter à l\'ordonnance',
    );
  }

  Widget _buildMedicamentItem(Medicament med) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  med.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmation(med),
              ),
            ],
          ),
          if (med.dosage != null) _buildDetailRow('Dosage', med.dosage),
          if (med.usage != null) _buildDetailRow('Usage', med.usage),
          if (med.route != null) _buildDetailRow('Voie', med.route),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Medicament med) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous retirer ${med.name} de l\'ordonnance ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              setState(() => medicaments.remove(med));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${med.name} retiré de l\'ordonnance'),
                  action: SnackBarAction(
                    label: 'Annuler',
                    onPressed: () => setState(() => medicaments.add(med)),
                  ),
                ),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureAndCachet() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return isSmallScreen
            ? Column(
                children: [
                  _buildSignatureSection(),
                  const SizedBox(height: 16),
                  _buildCachetSection(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 1,
                    child: _buildSignatureSection(),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    flex: 1,
                    child: _buildCachetSection(),
                  ),
                ],
              );
      },
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      children: [
        const Text('Signature'),
        const SizedBox(height: 8),
        SignaturePad(
          onSigned: (data) {
            setState(() => _signature = data);
          },
        ),
      ],
    );
  }

  Widget _buildCachetSection() {
    return Column(
      children: [
        const Text('Cachet'),
        const SizedBox(height: 8),
        CachetMedecin(
          imageBytes: _cachet,
          onSelect: (Uint8List bytes) {
            setState(() => _cachet = bytes);
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;

        return isSmallScreen
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(StyleConstants.saveIcon),
                    label: const Text('Sauvegarder'),
                    onPressed: _saveOrdonnance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StyleConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(StyleConstants.ordonnanceIcon),
                    label: const Text('Mes Ordonnances'),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/ordonnances-list'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StyleConstants.secondaryColor,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        icon: const Icon(StyleConstants.saveIcon),
                        label: const Text('Sauvegarder'),
                        onPressed: _saveOrdonnance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StyleConstants.primaryColor,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        icon: const Icon(StyleConstants.ordonnanceIcon),
                        label: const Text('Mes Ordonnances'),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/ordonnances-list'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StyleConstants.secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
      },
    );
  }

  void _saveOrdonnance() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      NavigationService.showTransitionDialog(context);

      final ordonnance = Ordonnance(
        patientId: _patientIdController.text,
        medecinId: _medecinIdController.text,
        clinique: _cliniqueController.text,
        specialite: _specialiteController.text,
        medicaments: medicaments,
        date: DateTime.now(),
        signature: _signature,
        cachet: _cachet,
      );

      final viewModel = context.read<OrdonnanceViewModel>();
      final response = await viewModel.createOrdonnance(ordonnance);

      if (context.mounted) {
        Navigator.pop(context); // Fermer le dialogue de transition

        if (response.containsKey('id')) {
          try {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PdfActionsScreen(
                  ordonnanceId: response['id'],
                  mode: PdfActionMode.newOrdonnance,
                ),
              ),
            );
          } catch (navError) {
            print('Erreur de navigation: $navError');
            // Fallback - Retour à l'écran principal si la navigation échoue
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/');
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec de la création de l\'ordonnance'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fermer le dialogue de transition
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addMedicament(Medicament medicament) {
    setState(() {
      // Vérifier si le médicament n'est pas déjà dans la liste
      if (!medicaments.any((med) => med.name == medicament.name)) {
        medicaments.add(medicament);
        _searchController.clear();
        context.read<OrdonnanceViewModel>().clearResults();

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicament.name} ajouté à l\'ordonnance'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Annuler',
              textColor: Colors.white,
              onPressed: () {
                setState(() => medicaments.remove(medicament));
              },
            ),
          ),
        );
      } else {
        // Afficher un message d'erreur si le médicament existe déjà
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicament.name} est déjà dans l\'ordonnance'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  Future<void> _startVoiceRecognition(OrdonnanceViewModel viewModel) async {
    try {
      if (_voiceService.isListening) {
        _voiceService.stopListening();
        return;
      }

      final hasPermission = await _voiceService.checkPermission();
      if (!hasPermission) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La permission du microphone est requise'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => isSearching = true);

      await _voiceService.startListening((text) {
        setState(() {
          _searchController.text = text;
          isSearching = false;
        });
        // Au lieu de chercher, créer directement un médicament
        _createMedicamentFromVoice(text);
      });
    } catch (e) {
      setState(() => isSearching = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _createMedicamentFromVoice(String text) {
    // Créer un nouveau médicament avec le texte dicté
    final medicament = Medicament(
      name: text,
      dosage: '', // A remplir manuellement si nécessaire
      usage: '', // A remplir manuellement si nécessaire
      route: '', // A remplir manuellement si nécessaire
    );

    _showMedicamentDetailsDialog(medicament);
  }

  void _showMedicamentDetailsDialog(Medicament medicament) {
    final dosageController = TextEditingController();
    final usageController = TextEditingController();
    final routeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Compléter les détails pour ${medicament.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'Ex: 1000mg',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usageController,
                decoration: const InputDecoration(
                  labelText: 'Usage',
                  hintText: 'Ex: 1 comprimé 3 fois par jour',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: routeController,
                decoration: const InputDecoration(
                  labelText: 'Voie d\'administration',
                  hintText: 'Ex: orale',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final completedMedicament = Medicament(
                name: medicament.name,
                dosage: dosageController.text,
                usage: usageController.text,
                route: routeController.text,
              );
              Navigator.pop(context);
              _addMedicament(completedMedicament);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanMedicamentWithOCR() async {
    try {
      final selectedService = await showDialog<OcrService>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir la méthode de saisie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _ocrServices
                .map((service) => ListTile(
                      title: Text(service.name),
                      subtitle: Text(service is ManualOcrService
                          ? 'Saisir le texte manuellement'
                          : 'Reconnaissance automatique du texte'),
                      onTap: () => Navigator.pop(context, service),
                    ))
                .toList(),
          ),
        ),
      );

      if (selectedService == null) return;

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: selectedService is ManualOcrService
              ? ImageSource.gallery
              : ImageSource.camera);

      if (image == null) return;

      String recognizedText = await selectedService.recognizeText(image.path);

      if (selectedService is ManualOcrService) {
        recognizedText = await _showManualInputDialog() ?? '';
      }

      if (recognizedText.isNotEmpty && context.mounted) {
        _showOCRResultsDialog(recognizedText);
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
  }

  Future<String?> _showManualInputDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saisir le texte'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Entrez le texte de l\'ordonnance',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showOCRResultsDialog(String recognizedText) {
    final lines = recognizedText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Texte détecté'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: lines.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(lines[index]),
                onTap: () {
                  Navigator.pop(context);
                  _createMedicamentFromText(lines[index]);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _createMedicamentFromText(String text) {
    final medicament = Medicament(
      name: text,
      dosage: '',
      usage: '',
      route: '',
    );
    _showMedicamentDetailsDialog(medicament);
  }
}
