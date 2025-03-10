import 'base_service.dart';
import 'api_service.dart';

class MedecinService extends BaseService {
  MedecinService(ApiService api) : super(api, 'medecins');

  Future<dynamic> getDoctorSchedule(String doctorId) async {
    return getAll({'doctor_id': doctorId, 'type': 'schedule'});
  }

  Future<dynamic> updateAvailability(
      String doctorId, Map<String, dynamic> availability) async {
    return update(doctorId, {'availability': availability});
  }

  Future<dynamic> getPatientList(String doctorId) async {
    return getAll({'doctor_id': doctorId, 'type': 'patients'});
  }

  Future<dynamic> assignPatient(String doctorId, String patientId) async {
    return _api
        .post('api/medecins/$doctorId/patients', {'patient_id': patientId});
  }

  Future<dynamic> getWorkload(String doctorId) async {
    return getAll({'doctor_id': doctorId, 'type': 'workload'});
  }
}
