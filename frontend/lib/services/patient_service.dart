import 'base_service.dart';
import 'api_service.dart';

class PatientService extends BaseService {
  PatientService(ApiService api) : super(api, 'patients');

  Future<dynamic> getMedicalHistory(String patientId) async {
    return getAll({'patient_id': patientId, 'type': 'medical_history'});
  }

  Future<dynamic> updateMedicalInfo(
      String patientId, Map<String, dynamic> medicalInfo) async {
    return update(patientId, {'medical_info': medicalInfo});
  }

  Future<dynamic> getAppointments(String patientId) async {
    return getAll({'patient_id': patientId, 'type': 'appointments'});
  }

  Future<dynamic> scheduleAppointment(
      String patientId, Map<String, dynamic> appointmentData) async {
    return _api.post('api/patients/$patientId/appointments', appointmentData);
  }

  Future<dynamic> cancelAppointment(
      String patientId, String appointmentId) async {
    return _api.delete('api/patients/$patientId/appointments/$appointmentId');
  }

  Future<dynamic> getXrayHistory(String patientId) async {
    return getAll({'patient_id': patientId, 'type': 'xrays'});
  }
}
