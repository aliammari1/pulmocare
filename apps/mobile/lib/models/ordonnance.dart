import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'medicament.dart';

class Ordonnance {
  String? id; // Changed from final to allow updating
  final String patientId;
  final String medecinId;
  final String patientName;
  final String doctorName;
  final String diagnosis;
  final String instructions;
  final String clinique;
  final String specialite;
  final DateTime date;
  final List<Medicament> medicaments;
  final Uint8List? signature;
  final Uint8List? cachet;

  Ordonnance({
    this.id,
    required this.patientId,
    required this.medecinId,
    this.patientName = '',
    this.doctorName = '',
    this.diagnosis = '',
    this.instructions = '',
    this.clinique = '',
    this.specialite = '',
    required this.date,
    required this.medicaments,
    this.signature,
    this.cachet,
  });

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'patient_name': patientName,
      'doctor_name': doctorName,
      'medications': medicaments
          .map(
            (medication) => {
              'name': medication.name,
              'dosage': medication.dosage ?? '',
              'frequency': medication.posologie?.trim().isNotEmpty == true
                  ? medication.posologie!.trim()
                  : 'As directed',
              'duration': null,
            },
          )
          .toList(),
      'instructions': instructions,
      'diagnosis': diagnosis,
      if (signature != null)
        'signature': 'data:image/png;base64,${base64Encode(signature!)}',
    };
  }

  factory Ordonnance.fromJson(Map<String, dynamic> json) {
    final rawMedications =
        (json['medications'] ?? json['medicaments']) as List? ?? const [];
    Uint8List? signatureBytes;
    final signatureValue = json['signature']?.toString();
    if (signatureValue != null && signatureValue.isNotEmpty) {
      try {
        final encoded = signatureValue.contains(',')
            ? signatureValue.substring(signatureValue.indexOf(',') + 1)
            : signatureValue;
        signatureBytes = base64Decode(encoded);
      } catch (_) {
        signatureBytes = null;
      }
    }

    return Ordonnance(
      id: (json['id'] ?? json['_id'])?.toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      medecinId:
          (json['doctor_id'] ?? json['medecin_id'] ?? '').toString(),
      patientName: (json['patient_name'] ?? '').toString(),
      doctorName: (json['doctor_name'] ?? '').toString(),
      diagnosis: (json['diagnosis'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      clinique: (json['clinique'] ?? '').toString(),
      specialite: (json['specialite'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      medicaments: rawMedications
          .whereType<Map>()
          .map(
            (item) {
              final data =
                  item.map((key, value) => MapEntry(key.toString(), value));
              return Medicament(
                name: (data['name'] ?? '').toString(),
                dosage: data['dosage']?.toString(),
                posologie:
                    (data['frequency'] ?? data['posologie'])?.toString(),
                usage: data['usage']?.toString(),
                laboratoire: data['laboratoire']?.toString(),
                route: data['route']?.toString(),
                warning: data['warning']?.toString(),
              );
            },
          )
          .toList(),
      signature: signatureBytes,
    );
  }

  Future<Uint8List> generatePdf() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Ajout de la signature et du cachet s'ils existent
    final signatureImage =
        signature != null ? pw.MemoryImage(signature!) : null;
    final cachetImage = cachet != null ? pw.MemoryImage(cachet!) : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'ORDONNANCE MEDICALE',
                    style: const pw.TextStyle(
                      fontSize: 24,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Info section
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('PATIENT: ${patientId.toUpperCase()}'),
                      pw.Text('MEDECIN: ${medecinId.toUpperCase()}'),
                      pw.Text('CLINIQUE: ${clinique.toUpperCase()}'),
                      pw.Text('SPECIALITE: ${specialite.toUpperCase()}'),
                      pw.Text('DATE: ${dateFormat.format(date).toUpperCase()}'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Medications section
                pw.Text(
                  'MEDICAMENTS PRESCRITS:',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),

                // Medications table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('MEDICAMENT'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('DOSAGE'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('POSOLOGIE'),
                        ),
                      ],
                    ),
                    // Data rows
                    ...medicaments.map(
                      (med) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(med.name.toUpperCase()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text((med.dosage ?? '-').toUpperCase()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child:
                                pw.Text((med.posologie ?? '-').toUpperCase()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Signatures section
                if (signature != null || cachet != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 50),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        if (signature != null)
                          pw.Column(
                            children: [
                              pw.Text('SIGNATURE'),
                              pw.Image(pw.MemoryImage(signature!), height: 70),
                            ],
                          ),
                        if (cachet != null)
                          pw.Column(
                            children: [
                              pw.Text('CACHET'),
                              pw.Image(pw.MemoryImage(cachet!), height: 100),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    // Ajout de la signature et du cachet
    if (signatureImage != null || cachetImage != null) {
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (signatureImage != null)
                pw.Column(
                  children: [
                    pw.Text('Signature'),
                    pw.Image(signatureImage, height: 70),
                  ],
                ),
              if (cachetImage != null)
                pw.Column(
                  children: [
                    pw.Text('Cachet'),
                    pw.Image(cachetImage, height: 100),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }
}
