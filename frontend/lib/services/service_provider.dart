import 'api_service.dart';
import 'xray_service.dart';
import 'report_service.dart';
import 'medecin_service.dart';
import 'patient_service.dart';
import 'radiologue_service.dart';

class ServiceProvider {
  static final ServiceProvider _instance = ServiceProvider._internal();
  factory ServiceProvider() => _instance;

  late final ApiService _apiService;
  late final XrayService xrayService;
  late final ReportService reportService;
  late final MedecinService medecinService;
  late final PatientService patientService;
  late final RadiologueService radiologueService;

  ServiceProvider._internal() {
    _apiService = ApiService();
    xrayService = XrayService(_apiService);
    reportService = ReportService(_apiService);
    medecinService = MedecinService(_apiService);
    patientService = PatientService(_apiService);
    radiologueService = RadiologueService(_apiService);
  }
}
