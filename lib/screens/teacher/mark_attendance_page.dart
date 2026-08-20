import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_record.dart';
import '../../models/school_class.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../services/attendance_service.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class MarkAttendancePage extends StatefulWidget {
  const MarkAttendancePage({super.key});

  static const routeName = '/teacher/mark-attendance';

  @override
  State<MarkAttendancePage> createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final _attendanceService = AttendanceService();
  final _schoolService = SchoolManagementService();
  final _teacherService = TeacherService();
  final _adminService = AdminService();

  List<SchoolClass> _classes = [];
  SchoolClass? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  final List<_DisplayStudent> _currentRoster = [];

  final Map<String, AttendanceStatus> _studentStatuses = {};
  final Map<String, TextEditingController> _noteControllers = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    for (final ctrl in _noteControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final profile = await _teacherService.getTeacherProfile();
      final allClasses = await _schoolService.getClasses();

      // Filter classes teacher teaches
      final teacherClasses = allClasses.where((c) {
        final isAssignedByJoin = c.teachers.any((t) =>
            t.teacherId == profile.id ||
            t.teacherName.toLowerCase() == profile.fullName.toLowerCase());
        final isAssignedByName = profile.assignedClasses.contains(c.displayName) ||
            profile.assignedClasses.contains(c.shortLabel);
        return isAssignedByJoin || isAssignedByName;
      }).toList();

      _classes = teacherClasses.isNotEmpty ? teacherClasses : allClasses;
      if (_classes.isNotEmpty) {
        _selectedClass = _classes.first;
        await _setupRosterForSelectedClass();
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _setupRosterForSelectedClass() async {
    _studentStatuses.clear();
    for (final ctrl in _noteControllers.values) {
      ctrl.dispose();
    }
    _noteControllers.clear();
    _currentRoster.clear();

    if (_selectedClass == null) return;

    // Refresh classes from database service to ensure latest student assignments for this section
    try {
      final updatedClasses = await _schoolService.getClasses();
      final freshClass = updatedClasses.firstWhere(
        (c) =>
            c.id == _selectedClass!.id ||
            (c.grade == _selectedClass!.grade &&
                c.section.toUpperCase() == _selectedClass!.section.toUpperCase()),
        orElse: () => _selectedClass!,
      );
      _selectedClass = freshClass;
    } catch (_) {}

    // 1. Get real students directly assigned to the selected class section
    if (_selectedClass!.students.isNotEmpty) {
      for (final s in _selectedClass!.students) {
        _currentRoster.add(_DisplayStudent(
          id: s.studentId,
          name: s.studentName,
          code: s.studentCode,
        ));
      }
    } else {
      // 2. Fallback: load active students for attendance roster
      try {
        final activeStudents = await _adminService.getActive(UserRole.student);
        for (final st in activeStudents) {
          _currentRoster.add(_DisplayStudent(
            id: st.id,
            name: '${st.firstName} ${st.lastName}'.trim(),
            code: st.studentId,
          ));
        }
      } catch (_) {}
    }

    // Initialize default Present status for each real student
    for (final s in _currentRoster) {
      _studentStatuses[s.id] = AttendanceStatus.present;
      _noteControllers[s.id] = TextEditingController();
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClass == null || _currentRoster.isEmpty) return;

    setState(() => _saving = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    int savedCount = 0;
    for (final s in _currentRoster) {
      final status = _studentStatuses[s.id] ?? AttendanceStatus.present;
      final note = _noteControllers[s.id]?.text;

      try {
        await _attendanceService.markAttendance(
          studentId: s.id,
          date: dateStr,
          status: status,
          note: note,
          studentName: s.name,
        );
        savedCount++;
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance saved for $savedCount students!'),
        backgroundColor: KukieAccent.success,
      ),
    );
    Navigator.of(context).pop(true);
  }

  InputDecoration _dropdownDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: KukieAccent.violet, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: KukieAccent.violet, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class and Date Selectors Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_classes.isEmpty)
                            const Text('No teaching classes assigned yet.', style: TextStyle(color: Colors.grey))
                          else
                            DropdownButtonFormField<SchoolClass>(
                              initialValue: _selectedClass,
                              isExpanded: true,
                              decoration: _dropdownDecoration('Target Class', Icons.class_outlined),
                              items: _classes
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c.displayName, overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) async {
                                setState(() => _selectedClass = val);
                                await _setupRosterForSelectedClass();
                              },
                            ),
                          const SizedBox(height: 14),
                          // Responsive Date Row preventing horizontal overflow
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: KukieAccent.violet, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dateStr,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.edit_calendar, size: 16),
                                label: const Text('Change Date', style: TextStyle(fontSize: 13)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Student Roster (${_currentRoster.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (_currentRoster.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No real students registered in this section yet.',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentRoster.length,
                      itemBuilder: (context, index) {
                        final student = _currentRoster[index];
                        final currentStatus = _studentStatuses[student.id] ?? AttendanceStatus.present;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: KukieAccent.violetTint,
                                      child: Text(
                                        student.name.isNotEmpty ? student.name.substring(0, 1).toUpperCase() : 'S',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: KukieAccent.violet),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          if (student.code != null && student.code!.isNotEmpty)
                                            Text('ID: ${student.code}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: AttendanceStatus.values.map((status) {
                                      final isSelected = currentStatus == status;
                                      Color activeColor;
                                      switch (status) {
                                        case AttendanceStatus.present:
                                          activeColor = KukieAccent.success;
                                          break;
                                        case AttendanceStatus.absent:
                                          activeColor = Colors.red;
                                          break;
                                        case AttendanceStatus.late:
                                          activeColor = Colors.orange;
                                          break;
                                        case AttendanceStatus.excused:
                                          activeColor = Colors.blue;
                                          break;
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ChoiceChip(
                                          label: Text(
                                            status.displayName,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : Colors.black87,
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          selected: isSelected,
                                          selectedColor: activeColor,
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() {
                                                _studentStatuses[student.id] = status;
                                              });
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving || _currentRoster.isEmpty ? null : _saveAttendance,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_saving ? 'Saving...' : 'Submit Attendance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KukieAccent.violet,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}

class _DisplayStudent {
  _DisplayStudent({required this.id, required this.name, this.code});
  final String id;
  final String name;
  final String? code;
}
