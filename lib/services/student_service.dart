import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/guardian_link.dart';

/// Covers `/students/*` (`src/routes/student.routes.ts`) for the student
/// dashboard's "Linked Guardians" tab.
///
/// SCOPE NOTE: `GET /students/my-guardians` is the only student endpoint
/// marked `x-implementation-status: implemented` in
/// `SchoolGuardian_Final_OpenAPI.yaml` today. `GET /reports/student/{id}/
/// academic|attendance|wellbeing` are all marked `planned`, so this
/// service intentionally does not add methods for them yet -- see
/// `screens/student/student_overview_tab.dart` for how the Overview tab
/// handles that gap (sample data, clearly labelled, until those ship).
class StudentService {
  StudentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String myGuardiansPath = '/students/my-guardians';

  /// `GET /students/my-guardians` -- verified parents/guardians linked to
  /// the signed-in student's account. Each row nests the guardian's
  /// profile under a `guardian` key (see [GuardianLink]) rather than
  /// being a bare list of users.
  Future<List<GuardianLink>> getMyGuardians() async {
    final decoded =
        await _apiClient.get(myGuardiansPath, requireAuth: true);
    final list = decoded['data'];
    if (list is! List) {
      throw ApiException.malformed(200);
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => GuardianLink.fromJson(json))
        .toList();
  }
}
