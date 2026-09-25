import 'package:flutter_test/flutter_test.dart';
import 'package:medapp/models/medical_report.dart';
import 'package:medapp/services/analytics_service.dart';

void main() {
  group('AnalyticsService', () {
    test('builds an inclusive daily reports trend without hanging', () {
      final service = AnalyticsService();
      final reports = <MedicalReport>[
        MedicalReport(
          id: 'r1',
          patientId: 'p1',
          patientName: 'Patient One',
          doctorId: 'd1',
          doctorName: 'Doctor One',
          date: DateTime(2026, 9, 24, 10),
          symptoms: 'Cough',
          diagnosis: 'Assessment',
          vitalSigns: const {},
          status: 'completed',
          isUrgent: false,
        ),
        MedicalReport(
          id: 'r2',
          patientId: 'p1',
          patientName: 'Patient One',
          doctorId: 'd1',
          doctorName: 'Doctor One',
          date: DateTime(2026, 9, 25, 9),
          symptoms: 'Follow-up',
          diagnosis: 'Assessment',
          vitalSigns: const {},
          status: 'completed',
          isUrgent: false,
        ),
      ];

      final trend = service.getReportsTrend(
        reports,
        startDate: DateTime(2026, 9, 24),
        endDate: DateTime(2026, 9, 25),
      );

      expect(trend.length, 2);
      expect(trend[DateTime(2026, 9, 24)], 1);
      expect(trend[DateTime(2026, 9, 25)], 1);
    });
  });
}
