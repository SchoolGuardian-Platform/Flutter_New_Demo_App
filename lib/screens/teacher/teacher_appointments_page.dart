import 'package:flutter/material.dart';
import '../../services/appointment_service.dart';
import '../../theme/kukie_accent.dart';

class TeacherAppointmentsPage extends StatefulWidget {
  const TeacherAppointmentsPage({super.key});

  static const routeName = '/teacher/appointments';

  @override
  State<TeacherAppointmentsPage> createState() => _TeacherAppointmentsPageState();
}

class _TeacherAppointmentsPageState extends State<TeacherAppointmentsPage> {
  final _appointmentService = AppointmentService();

  List<AppointmentItem> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    try {
      final list = await _appointmentService.getTeacherAppointments();
      if (mounted) {
        setState(() {
          _appointments = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCreateSlotDialog() {
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final startController = TextEditingController(text: '14:00');
    final endController = TextEditingController(text: '14:30');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Open Appointment Time Slot',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Meeting Date (YYYY-MM-DD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  hintText: '2026-08-22',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: startController,
                          decoration: InputDecoration(
                            hintText: '14:00',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: endController,
                          decoration: InputDecoration(
                            hintText: '14:30',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: KukieAccent.violet),
              onPressed: () async {
                final d = dateController.text.trim();
                final st = startController.text.trim();
                final et = endController.text.trim();

                if (d.isEmpty || st.isEmpty || et.isEmpty) return;

                Navigator.pop(ctx);
                final ok = await _appointmentService.createSlot(date: d, startTime: st, endTime: et);
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment slot published for parents!'), backgroundColor: KukieAccent.success),
                  );
                  _loadAppointments();
                }
              },
              child: const Text('Publish Slot'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    final ok = await _appointmentService.updateAppointmentStatus(id, status);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'ACCEPTED' ? 'Appointment accepted!' : 'Appointment declined.'),
          backgroundColor: status == 'ACCEPTED' ? KukieAccent.success : Colors.red,
        ),
      );
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parent Appointments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            Text('Office Hours & Conference Requests', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)), onPressed: _loadAppointments),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSlotDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Open Time Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: KukieAccent.violet,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_appointments.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.calendar_month_outlined, size: 48, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'No Parent Appointments Booked Yet',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap "Open Time Slot" below to create office hours slots that parents can book for conferences.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._appointments.map((apt) {
                      Color statusBg;
                      Color statusColor;
                      String statusText = apt.status;

                      if (apt.status == 'ACCEPTED') {
                        statusBg = const Color(0xFFECFDF5);
                        statusColor = const Color(0xFF10B981);
                      } else if (apt.status.contains('CANCELLED')) {
                        statusBg = const Color(0xFFFFF1F2);
                        statusColor = const Color(0xFFE11D48);
                      } else {
                        statusBg = const Color(0xFFFFFBEB);
                        statusColor = const Color(0xFFD97706);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        apt.parentName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (apt.parentEmail.isNotEmpty)
                                        Text(
                                          apt.parentEmail,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.school_outlined, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text('Student: ${apt.studentName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Text('${apt.date} • ${apt.startTime} - ${apt.endTime}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                            if (apt.reason.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Reason: ${apt.reason}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                              ),
                            ],
                            if (apt.status == 'PENDING') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _updateStatus(apt.id, 'CANCELLED_BY_TEACHER'),
                                      icon: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                                      label: const Text('Decline', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFECDD3))),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _updateStatus(apt.id, 'ACCEPTED'),
                                      icon: const Icon(Icons.check_rounded, size: 14),
                                      label: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
