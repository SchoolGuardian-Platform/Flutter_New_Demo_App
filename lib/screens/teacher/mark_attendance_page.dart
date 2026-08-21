import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_record.dart';
import '../../models/school_class.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../services/attendance_service.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
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

    final target = _selectedClass;
    if (target == null) return;

    try {
      final updatedClasses = await _schoolService.getClasses();
      final freshClass = updatedClasses.firstWhere(
        (c) =>
            c.id == target.id ||
            (c.grade == target.grade &&
                c.section.toUpperCase() == target.section.toUpperCase()),
        orElse: () => target,
      );
      _selectedClass = freshClass;
    } catch (_) {}

    final activeClass = _selectedClass ?? target;
    if (activeClass.students.isNotEmpty) {
      for (final s in activeClass.students) {
        _currentRoster.add(_DisplayStudent(
          id: s.studentId,
          name: s.studentName,
          code: s.studentCode,
        ));
      }
    } else {
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

    for (final s in _currentRoster) {
      _studentStatuses[s.id] = AttendanceStatus.present;
      _noteControllers[s.id] = TextEditingController();
    }

    if (mounted) setState(() {});
  }

  void _quickFillAll(AttendanceStatus status) {
    setState(() {
      for (final s in _currentRoster) {
        _studentStatuses[s.id] = status;
      }
    });
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
      final note = _noteControllers[s.id]?.text.trim();

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
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    Navigator.of(context).pop(true);
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF10B981); // Emerald
      case AttendanceStatus.absent:
        return const Color(0xFFE11D48); // Rose
      case AttendanceStatus.late:
        return const Color(0xFFD97706); // Amber
      case AttendanceStatus.excused:
        return const Color(0xFF0284C7); // Sky
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Attendance Sheet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text('Daily Student Roster & History', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class & Date Header Card (Web style)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x05000000),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mark Attendance',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const Text(
                          'Tick a status per student, then save the sheet at once',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 12),
                        if (_classes.isNotEmpty)
                          DropdownButtonFormField<String>(
                            initialValue: _classes.any((c) => c.id == _selectedClass?.id)
                                ? _selectedClass?.id
                                : null,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Target Class',
                              prefixIcon: const Icon(Icons.class_outlined, color: KukieAccent.violet, size: 18),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            ),
                            items: _classes
                                .map((c) => DropdownMenuItem<String>(
                                      value: c.id,
                                      child: Text(c.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                            onChanged: (val) async {
                              if (val != null) {
                                final selected = _classes.firstWhere((c) => c.id == val, orElse: () => _classes.first);
                                setState(() => _selectedClass = selected);
                                await _setupRosterForSelectedClass();
                              }
                            },
                          ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, color: KukieAccent.violet, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dateStr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                const Text('Change Date', style: TextStyle(fontSize: 12, color: KukieAccent.violet, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick fill bar (Web style)
                  if (_currentRoster.isNotEmpty) ...[
                    Row(
                      children: [
                        const Text('Quick Fill All:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: AttendanceStatus.values.map((st) {
                                final color = _getStatusColor(st);
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () => _quickFillAll(st),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withAlpha(25),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: color.withAlpha(76)),
                                      ),
                                      child: Text(
                                        st.displayName.toUpperCase(),
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Roster List
                  if (_currentRoster.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 44, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'No students enrolled in this section yet.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              textAlign: TextAlign.center,
                            ),
                          ],
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: KukieAccent.violet, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                                        if (student.code != null && student.code!.isNotEmpty)
                                          Text('ID: ${student.code}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // 4 Status Pill Selection
                              Row(
                                children: AttendanceStatus.values.map((status) {
                                  final isSelected = currentStatus == status;
                                  final statusColor = _getStatusColor(status);

                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _studentStatuses[student.id] = status;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 7),
                                          decoration: BoxDecoration(
                                            color: isSelected ? statusColor : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected ? statusColor : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              status.displayName,
                                              style: TextStyle(
                                                color: isSelected ? Colors.white : const Color(0xFF475569),
                                                fontSize: 11,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              // Note Input
                              TextField(
                                controller: _noteControllers[student.id],
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Observation note (optional)...',
                                  hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving || _currentRoster.isEmpty ? null : _saveAttendance,
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(_saving ? 'Saving...' : 'Save Attendance Sheet (${_currentRoster.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: KukieAccent.violet,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
