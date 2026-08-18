import 'package:flutter/material.dart';
import '../../models/course_offering.dart';
import '../../models/student_course_registration.dart';
import '../../services/course_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class CourseRegistrationPage extends StatefulWidget {
  const CourseRegistrationPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/student/register-courses';
  final String studentId;

  @override
  State<CourseRegistrationPage> createState() => _CourseRegistrationPageState();
}

class _CourseRegistrationPageState extends State<CourseRegistrationPage> {
  final _courseService = CourseService();
  List<CourseOffering> _availableOfferings = [];
  List<StudentCourseRegistration> _myRegistrations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final offerings = await _courseService.getAvailableOfferings(term: 'Fall 2026');
    final myRegs = await _courseService.getStudentRegistrations(widget.studentId, term: 'Fall 2026');
    if (!mounted) return;
    setState(() {
      _availableOfferings = offerings;
      _myRegistrations = myRegs;
      _loading = false;
    });
  }

  bool _isEnrolled(String courseId) {
    return _myRegistrations.any((r) => r.course.id == courseId);
  }

  Future<void> _enroll(CourseOffering course) async {
    try {
      await _courseService.registerStudentForCourse(
        studentId: widget.studentId,
        studentName: 'Alexander Hayes',
        course: course,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully registered for ${course.code}: ${course.title}! Connected to teacher ${course.teacherName}.'),
          backgroundColor: KukieAccent.success,
        ),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semester Course Registration'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: KukieAccent.violetTint,
                      borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
                      border: Border.all(color: KukieAccent.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.how_to_reg, color: KukieAccent.violet),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Select Director-approved semester courses to enroll. Once registered, your enrollment automatically connects with the assigned teacher.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: KukieAccent.ink,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Available Courses for Fall 2026',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._availableOfferings.map((course) {
                    final enrolled = _isEnrolled(course.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: enrolled ? Colors.green.shade100 : KukieAccent.violetTint,
                              child: Icon(
                                enrolled ? Icons.check_circle : Icons.book,
                                color: enrolled ? Colors.green.shade800 : KukieAccent.violet,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${course.code}: ${course.title}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Teacher: ${course.teacherName} · ${course.credits} Credits',
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                                  ),
                                  Text(
                                    course.department,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: enrolled ? null : () => _enroll(course),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: enrolled ? Colors.grey.shade300 : KukieAccent.violet,
                                foregroundColor: enrolled ? Colors.grey.shade700 : Colors.white,
                              ),
                              child: Text(enrolled ? 'Enrolled' : 'Register'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
