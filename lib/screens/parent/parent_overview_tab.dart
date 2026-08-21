import 'package:flutter/material.dart';

import '../../models/student_link.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/communication_service.dart';
import '../../services/parent_service.dart';
import '../../theme/kukie_accent.dart';
import 'link_student_page.dart';

class ParentOverviewTab extends StatefulWidget {
  const ParentOverviewTab({super.key, required this.user, required this.onNavigateToChildTab});

  final User user;
  final VoidCallback onNavigateToChildTab;

  @override
  State<ParentOverviewTab> createState() => _ParentOverviewTabState();
}

class _ParentOverviewTabState extends State<ParentOverviewTab> {
  final _parentService = ParentService();
  final _appointmentService = AppointmentService();

  List<StudentLink>? _students;
  List<AppointmentItem> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final students = await _parentService.getMyStudents();
      final appointments = await _appointmentService.getParentAppointments();
      if (!mounted) return;
      setState(() {
        _students = students;
        _appointments = appointments;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLinkStudent() async {
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LinkStudentPage()),
    );
    if (linked == true) _loadData();
  }

  Future<void> _showBookMeetingModal() async {
    final students = _students ?? [];
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please link a student account first before booking teacher meetings.')),
      );
      return;
    }

    final commService = CommunicationService();
    final reasonController = TextEditingController();

    String? selectedStudentId = students.first.studentId;
    List<Map<String, dynamic>> teachers = [];
    String? selectedTeacherId;
    List<AppointmentSlotItem> slots = [];
    String? selectedSlotId;

    bool loadingTeachers = false;
    bool loadingSlots = false;
    bool submitting = false;

    // Helper to fetch slots for teacher
    Future<void> fetchSlots(String teacherId, StateSetter setModalState) async {
      setModalState(() {
        loadingSlots = true;
        slots = [];
        selectedSlotId = null;
      });
      try {
        final res = await _appointmentService.getAvailableSlots(teacherId);
        setModalState(() {
          slots = res;
          if (slots.isNotEmpty) {
            selectedSlotId = slots.first.id;
          }
          loadingSlots = false;
        });
      } catch (_) {
        setModalState(() => loadingSlots = false);
      }
    }

    // Helper to fetch teachers for student
    Future<void> fetchTeachers(String studentId, StateSetter setModalState) async {
      setModalState(() {
        loadingTeachers = true;
        teachers = [];
        selectedTeacherId = null;
        slots = [];
        selectedSlotId = null;
      });
      try {
        final res = await commService.getStudentTeachers(studentId);
        setModalState(() {
          teachers = res;
          if (teachers.isNotEmpty) {
            selectedTeacherId = teachers.first['id'] as String?;
          }
          loadingTeachers = false;
        });
        if (selectedTeacherId != null) {
          await fetchSlots(selectedTeacherId!, setModalState);
        }
      } catch (_) {
        setModalState(() => loadingTeachers = false);
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (teachers.isEmpty && !loadingTeachers && selectedStudentId != null) {
              fetchTeachers(selectedStudentId!, setModalState);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: KukieAccent.violetTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.event_available_rounded, color: KukieAccent.violet, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Schedule Teacher Conference',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Select Child *
                    Row(
                      children: const [
                        Text('Select Child', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStudentId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: students
                          .map((s) => DropdownMenuItem(value: s.studentId, child: Text(s.fullName)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedStudentId = val);
                          fetchTeachers(val, setModalState);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // 2. Select Teacher *
                    Row(
                      children: const [
                        Text('Select Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    loadingTeachers
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                        : teachers.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: const Text('No assigned teachers found for this student.', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                              )
                            : DropdownButtonFormField<String>(
                                initialValue: selectedTeacherId,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                items: teachers.map((t) {
                                  final name = '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim();
                                  return DropdownMenuItem(
                                    value: t['id'] as String,
                                    child: Text(name.isNotEmpty ? name : 'Teacher'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => selectedTeacherId = val);
                                    fetchSlots(val, setModalState);
                                  }
                                },
                              ),
                    const SizedBox(height: 14),

                    // 3. Select Open Availability Slot *
                    Row(
                      children: const [
                        Text('Select Open Availability Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    loadingSlots
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                        : slots.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Text('No open availability slots offered by this teacher.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              )
                            : DropdownButtonFormField<String>(
                                initialValue: selectedSlotId,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                                items: slots.map((s) {
                                  final dateStr = s.date.contains('T') ? s.date.split('T').first : s.date;
                                  return DropdownMenuItem(
                                    value: s.id,
                                    child: Text('$dateStr  ${s.startTime} - ${s.endTime}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedSlotId = val);
                                },
                              ),
                    const SizedBox(height: 14),

                    // 4. Meeting Reason / Topics to Discuss
                    const Text('Meeting Reason / Topics to Discuss', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Discuss term 1 math assessment and study habits',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: (submitting || selectedSlotId == null || selectedStudentId == null)
                              ? null
                              : () async {
                                  setModalState(() => submitting = true);
                                  final success = await _appointmentService.bookAppointment(
                                    slotId: selectedSlotId!,
                                    studentId: selectedStudentId!,
                                    reason: reasonController.text.trim(),
                                  );
                                  if (context.mounted) {
                                    Navigator.of(ctx).pop();
                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Teacher conference booked successfully!')),
                                      );
                                      _loadData();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Failed to book appointment. Please check slot availability.')),
                                      );
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: KukieAccent.violet,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _cancelAppointment(AppointmentItem apt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: Text('Are you sure you want to cancel your conference request with ${apt.teacherName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _appointmentService.cancelAppointment(apt.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled.')));
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not cancel appointment.')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = _students ?? [];
    final linkedCount = students.length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        children: [
          // ── Header Section ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Parent & Guardian Overview',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: KukieAccent.violetTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PARENT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: KukieAccent.violet),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Monitor your children's academic progress, attendance percentage, upcoming assignments, and faculty meetings.",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Action Buttons ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openLinkStudent,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 16, color: Color(0xFF334155)),
                  label: const Text(
                    'Link Another Student',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _showBookMeetingModal,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: KukieAccent.violet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text(
                    'Book Teacher Meeting',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── 4 Stat Cards (2x2 Grid) ──
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              _statCard(
                title: 'LINKED CHILDREN',
                value: '$linkedCount',
                subtitle: 'Verified student accounts',
                icon: Icons.school_rounded,
                iconColor: KukieAccent.violet,
                bgColor: KukieAccent.violetTint,
              ),
              _statCard(
                title: 'ATTENDANCE & ABSENCES',
                value: 'Live Tracking',
                subtitle: 'Real-time daily status',
                icon: Icons.calendar_today_rounded,
                iconColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
              _statCard(
                title: 'ACADEMIC GRADES',
                value: 'Report Cards',
                subtitle: 'Assessment scores & feedback',
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
              ),
              _statCard(
                title: 'FACULTY APPOINTMENTS',
                value: '${_appointments.length}',
                subtitle: 'Scheduled parent conferences',
                icon: Icons.event_note_rounded,
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── My Linked Students Section ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'My Linked Students',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Verified child academic profiles',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              TextButton(
                onPressed: widget.onNavigateToChildTab,
                child: Row(
                  children: const [
                    Text('Manage Links', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: KukieAccent.violet)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: KukieAccent.violet),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_loading && students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (students.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_add_rounded, color: KukieAccent.violet, size: 28),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'No verified children linked yet. Click "Link Another Student" above to add your student.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            )
          else
            ...students.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: KukieAccent.violetTint,
                            child: Text(
                              s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: KukieAccent.violet, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  s.email,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _tabActionButton(
                              label: 'Attendance',
                              icon: Icons.calendar_month_outlined,
                              onTap: widget.onNavigateToChildTab,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _tabActionButton(
                              label: 'Grades',
                              icon: Icons.assessment_outlined,
                              onTap: widget.onNavigateToChildTab,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _tabActionButton(
                              label: 'Homework',
                              icon: Icons.assignment_outlined,
                              onTap: widget.onNavigateToChildTab,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 20),

          // ── Parent-Teacher Appointments Section ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Teacher Conferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Upcoming scheduled meetings & status',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showBookMeetingModal,
                child: Row(
                  children: const [
                    Text('+ Book', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: KukieAccent.violet)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: KukieAccent.violet),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_appointments.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.event_busy_rounded, size: 40, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 10),
                  Text(
                    'No scheduled appointments found.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            ..._appointments.map((apt) {
              final dateStr = apt.date.contains('T') ? apt.date.split('T').first : apt.date;
              final isCancelled = apt.status.contains('CANCELLED');

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: KukieAccent.violetTint, shape: BoxShape.circle),
                              child: const Icon(Icons.event_rounded, color: KukieAccent.violet, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  apt.teacherName,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  'Student: ${apt.studentName}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCancelled ? const Color(0xFFFEF2F2) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            apt.status.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isCancelled ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date & Time: $dateStr  ${apt.startTime} - ${apt.endTime}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                          if (apt.reason.isNotEmpty && apt.reason != 'null') ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${apt.reason}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isCancelled) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _cancelAppointment(apt),
                          icon: const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFEF4444)),
                          label: const Text('Cancel Appointment', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: KukieAccent.violet),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }
}
