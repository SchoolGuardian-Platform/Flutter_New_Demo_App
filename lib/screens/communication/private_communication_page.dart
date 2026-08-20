import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/communication_models.dart';
import '../../models/student_link.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/communication_service.dart';
import '../../services/parent_service.dart';
import '../../services/school_management_service.dart';
import '../../theme/kukie_accent.dart';

class AppMessageNotif {
  final String senderName;
  final String content;
  final String senderId;
  final DateTime time;

  AppMessageNotif({
    required this.senderName,
    required this.content,
    required this.senderId,
    required this.time,
  });
}

class PrivateCommunicationPage extends StatefulWidget {
  const PrivateCommunicationPage({super.key, required this.user});
  static const routeName = '/private-communication';
  final User user;
  @override
  State<PrivateCommunicationPage> createState() => _PrivateCommunicationPageState();
}

class _PrivateCommunicationPageState extends State<PrivateCommunicationPage> {
  final _msgCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _commService = CommunicationService();
  final _parentService = ParentService();
  final _schoolService = SchoolManagementService();

  // Parent state
  List<StudentLink> _myChildren = [];
  StudentLink? _selectedChild;
  List<Map<String, dynamic>> _subjects = [];
  String? _selectedTeacherId;
  bool _loadingParent = false;

  // Teacher state
  List<Map<String, dynamic>> _guardians = [];
  String? _selectedGuardianId;
  bool _loadingTeacher = false;
  Map<String, dynamic>? _foundStudent;
  String? _lookupError;

  // Teacher autocomplete state
  List<Map<String, dynamic>> _allTeacherStudents = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _loadingStudents = false;
  bool _showSuggestions = false;
  Timer? _debounce;

  // Chat state
  String? _targetId;
  String _targetName = 'Recipient';
  List<ChatMessage> _messages = [];
  bool _loadingMsgs = false;

  // Notification state
  int _unreadCount = 0;
  Timer? _pollTimer;
  int _prevMsgCount = 0;
  AppMessageNotif? _activeNotif;

  @override
  void initState() {
    super.initState();
    _init();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_targetId != null && mounted) _pollMessages();
      if (mounted) _pollUnread();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _debounce?.cancel();
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.user.role == UserRole.parent) {
      await _loadParent();
    } else if (widget.user.role == UserRole.teacher) {
      await _loadAllTeacherStudents();
    }
    _pollUnread();
  }

  Future<void> _pollUnread() async {
    final count = await _commService.getUnreadCount();
    if (!mounted) return;
    if (count > _unreadCount && _targetId != null) {
      try {
        final history = await _commService.getChatHistory(
          otherUserId: _targetId!,
          currentUserId: widget.user.id,
        );
        if (history.isNotEmpty && !history.last.isMe) {
          _triggerAppNotif(
            senderName: history.last.senderName,
            content: history.last.content,
            senderId: history.last.senderId ?? '',
          );
        }
      } catch (_) {}
    }
    setState(() => _unreadCount = count);
  }

  void _triggerAppNotif({
    required String senderName,
    required String content,
    required String senderId,
  }) {
    setState(() {
      _activeNotif = AppMessageNotif(
        senderName: senderName,
        content: content,
        senderId: senderId,
        time: DateTime.now(),
      );
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _activeNotif?.senderId == senderId) {
        setState(() => _activeNotif = null);
      }
    });
  }

  Future<void> _pollMessages() async {
    try {
      final history = await _commService.getChatHistory(
        otherUserId: _targetId!,
        currentUserId: widget.user.id,
      );
      if (!mounted) return;
      if (history.length > _prevMsgCount && _prevMsgCount > 0) {
        final last = history.last;
        if (!last.isMe) {
          _triggerAppNotif(
            senderName: last.senderName,
            content: last.content,
            senderId: last.senderId ?? '',
          );
        }
      }
      setState(() {
        _messages = history;
        _prevMsgCount = history.length;
      });
    } catch (_) {}
  }

  // ── PARENT ──────────────────────────────────────────────────────

  Future<void> _loadParent() async {
    setState(() => _loadingParent = true);
    try {
      final children = await _parentService.getMyStudents();
      if (!mounted) return;
      setState(() => _myChildren = children);
      if (children.isNotEmpty) {
        _selectedChild = children.first;
        await _loadChildSubjects(_selectedChild!.studentId);
      }
    } catch (e) {
      debugPrint('Parent load: $e');
    } finally {
      if (mounted) setState(() => _loadingParent = false);
    }
  }

  Future<void> _loadChildSubjects(String studentUuid) async {
    List<Map<String, dynamic>> list = [];
    
    // Always fetch REAL teachers from DB first via CommunicationService
    try {
      final ts = await _commService.getStudentTeachers(studentUuid);
      for (final t in ts) {
        final id = t['id'] as String? ?? '';
        if (id.isNotEmpty && !list.any((x) => x['id'] == id)) {
          list.add({
            'id': id,
            'subject': t['subject'] ?? 'Subject Teacher',
            'teacherName': '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim(),
            'className': '',
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading student teachers from DB: $e');
    }

    // Secondary fallback only if DB returned nothing
    if (list.isEmpty) {
      try {
        final classes = await _schoolService.getClasses();
        for (final sc in classes) {
          for (final t in sc.teachers) {
            final id = t.teacherId.isNotEmpty ? t.teacherId : '';
            if (id.isNotEmpty && !list.any((x) => x['id'] == id)) {
              list.add({
                'id': id,
                'subject': t.subjectName,
                'teacherName': t.teacherName.isNotEmpty ? t.teacherName : 'Subject Teacher',
                'className': sc.displayName,
              });
            }
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _subjects = list;
      if (list.isNotEmpty) {
        _selectedTeacherId = list.first['id'] as String;
        _targetId = _selectedTeacherId;
        _targetName = list.first['teacherName'] as String;
      }
    });
    if (_targetId != null) await _fetchChat(_targetId!);
  }

  // ── TEACHER ─────────────────────────────────────────────────────

  /// Pre-fetch all students in the teacher's classes on page open and auto-load the first student.
  Future<void> _loadAllTeacherStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final students = await _commService.getTeacherStudents();
      if (!mounted) return;
      setState(() => _allTeacherStudents = students);
      if (students.isNotEmpty && _foundStudent == null) {
        await _selectStudent(students.first);
      }
    } catch (e) {
      debugPrint('Load teacher students: $e');
    } finally {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = query.trim().toLowerCase();
      final filtered = _allTeacherStudents.where((s) {
        final sid = (s['studentId'] ?? '').toString().toLowerCase();
        final fname = (s['firstName'] ?? '').toString().toLowerCase();
        final lname = (s['lastName'] ?? '').toString().toLowerCase();
        return sid.contains(q) || fname.contains(q) || lname.contains(q);
      }).take(6).toList();
      if (mounted) setState(() { _suggestions = filtered; _showSuggestions = filtered.isNotEmpty; });
    });
  }

  void _selectSuggestion(Map<String, dynamic> student) {
    _selectStudent(student);
  }

  /// Selects a student directly from memory (suggestion or list) and loads their linked guardians.
  Future<void> _selectStudent(Map<String, dynamic> student) async {
    final sid = (student['studentId'] as String? ?? '').isNotEmpty
        ? student['studentId'] as String
        : student['id'] as String;
    final fullName = '${student['firstName'] ?? ''} ${student['lastName'] ?? ''}'.trim();
    _searchCtrl.text = (student['studentId'] as String? ?? '').isNotEmpty
        ? student['studentId'] as String
        : (fullName.isNotEmpty ? fullName : sid);

    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _loadingTeacher = true;
      _lookupError = null;
      _foundStudent = student;
      _guardians = [];
    });

    try {
      final uuid = student['id'] as String;
      final parents = await _commService.getStudentParents(uuid);
      if (!mounted) return;

      List<Map<String, dynamic>> resolved = parents.map((p) => {
        'id': p['id'] as String? ?? '',
        'fullName': '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim(),
        'email': p['email'] ?? '',
        'relationshipType': p['relationshipType'] ?? 'Guardian',
      }).where((p) => (p['id'] as String).isNotEmpty).toList();

      if (resolved.isEmpty) {
        setState(() {
          _lookupError = 'Student found ($fullName) but no approved guardians linked yet.';
          _loadingTeacher = false;
        });
        return;
      }

      setState(() {
        _guardians = resolved;
        _selectedGuardianId = resolved.first['id'] as String;
        _targetId = _selectedGuardianId;
        _targetName = resolved.first['fullName'] as String;
        _loadingTeacher = false;
      });
      await _fetchChat(_targetId!);
    } catch (e) {
      if (mounted) setState(() { _lookupError = 'Error: ${e.toString()}'; _loadingTeacher = false; });
    }
  }

  /// Performs text-based lookup when user manually types a student ID or name into the search bar.
  Future<void> _lookupStudent(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Check if query matches a student in memory first
    final qLower = trimmed.toLowerCase();
    final match = _allTeacherStudents.firstWhere(
      (s) => (s['studentId'] ?? '').toString().toLowerCase() == qLower ||
             (s['id'] ?? '').toString().toLowerCase() == qLower ||
             '${s['firstName']} ${s['lastName']}'.toLowerCase() == qLower,
      orElse: () => <String, dynamic>{},
    );

    if (match.isNotEmpty) {
      await _selectStudent(match);
      return;
    }

    setState(() { _loadingTeacher = true; _lookupError = null; _foundStudent = null; _guardians = []; });

    try {
      // Resolve query via backend
      final student = await _commService.lookupStudentBySchoolId(trimmed);
      if (!mounted) return;
      if (student == null) {
        setState(() { _lookupError = 'No student found with ID: $trimmed'; _loadingTeacher = false; });
        return;
      }
      await _selectStudent(student);
    } catch (e) {
      if (mounted) setState(() { _lookupError = 'Error: ${e.toString()}'; _loadingTeacher = false; });
    }
  }

  // ── CHAT ────────────────────────────────────────────────────────

  Future<void> _fetchChat(String receiverId, {bool silent = false}) async {
    if (!silent && mounted) setState(() => _loadingMsgs = true);
    try {
      final history = await _commService.getChatHistory(
        otherUserId: receiverId,
        currentUserId: widget.user.id,
      );
      if (mounted) {
        setState(() {
          _messages = history;
          _prevMsgCount = history.length;
        });
      }
    } catch (_) {}
    if (!silent && mounted) setState(() => _loadingMsgs = false);
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _targetId == null) return;
    _msgCtrl.clear();

    // Optimistic local
    setState(() {
      _messages.add(ChatMessage(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        senderId: widget.user.id,
        receiverId: _targetId,
        senderName: widget.user.fullName,
        senderRole: widget.user.role.label,
        content: text,
        timestampText: 'Just now',
        isMe: true,
      ));
    });

    try {
      await _commService.sendMessage(
        receiverId: _targetId!,
        content: text,
        currentUserId: widget.user.id,
      );
      // Show outgoing notification banner briefly
      if (mounted) {
        _triggerAppNotif(
          senderName: 'You',
          content: 'Sent to $_targetName: $text',
          senderId: widget.user.id,
        );
      }
      await _fetchChat(_targetId!, silent: true);
    } catch (e) {
      debugPrint('Send error: $e');
    }
  }

  // ── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isParent = widget.user.role == UserRole.parent;
    final isTeacher = widget.user.role == UserRole.teacher;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(isParent, isTeacher),
      body: Column(
        children: [
          if (_activeNotif != null) _buildNotifBanner(),
          if (isParent) _buildParentHeader(),
          if (isTeacher) _buildTeacherHeader(),
          Expanded(child: _buildChat()),
          _buildComposer(),
        ],
      ),
    );
  }

  AppBar _buildAppBar(bool isParent, bool isTeacher) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isParent ? 'Talk to Subject Teacher' : isTeacher ? 'Message Guardian' : 'Messages',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const Text('Neon DB • Live Sync', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
      actions: [
        if (_unreadCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Badge(
              label: Text('$_unreadCount'),
              child: const Icon(Icons.notifications_rounded, color: KukieAccent.violet),
            ),
          ),
      ],
    );
  }

  Widget _buildNotifBanner() {
    if (_activeNotif == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFF334155), width: 1),
        ),
        child: InkWell(
          onTap: () {
            setState(() => _activeNotif = null);
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: Center(
                  child: Text(
                    _activeNotif!.senderName.isNotEmpty
                        ? _activeNotif!.senderName[0].toUpperCase()
                        : '💬',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _activeNotif!.senderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Just now',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _activeNotif!.content,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
                onPressed: () => setState(() => _activeNotif = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParentHeader() {
    final safeId = _subjects.any((s) => s['id'] == _selectedTeacherId)
        ? _selectedTeacherId
        : (_subjects.isNotEmpty ? _subjects.first['id'] as String : null);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (_myChildren.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _myChildren.map((c) {
                final sel = c.studentId == _selectedChild?.studentId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.fullName, style: const TextStyle(fontSize: 12)),
                    selected: sel,
                    selectedColor: KukieAccent.violetTint,
                    onSelected: (_) { setState(() { _selectedChild = c; }); _loadChildSubjects(c.studentId); },
                  ),
                );
              }).toList()),
            ),
          const SizedBox(height: 8),
          const Text('Select Subject / Teacher:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 8),
          if (_loadingParent)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_subjects.isEmpty)
            const Text('No teachers found for this student.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: safeId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: KukieAccent.violet),
                  items: _subjects.map((s) => DropdownMenuItem<String>(
                    value: s['id'] as String,
                    child: Text('${s['subject']}  •  ${s['teacherName']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final m = _subjects.firstWhere((s) => s['id'] == id);
                    setState(() { _selectedTeacherId = id; _targetId = id; _targetName = m['teacherName'] as String; });
                    _fetchChat(id);
                  },
                ),
              ),
            ),
        ]),
      ),
      const Divider(height: 1),
    ]);
  }

  Widget _buildTeacherHeader() {
    final safeId = _guardians.any((g) => g['id'] == _selectedGuardianId)
        ? _selectedGuardianId
        : (_guardians.isNotEmpty ? _guardians.first['id'] as String : null);

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const Text('Search Student by Name or ID:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          const SizedBox(height: 4),
          if (_loadingStudents)
            const Text('Loading your students...', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))
          else
            Text('${_allTeacherStudents.length} student${_allTeacherStudents.length != 1 ? 's' : ''} in your classes', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Type name or ID  (e.g. SG-2026-000001)',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: KukieAccent.violet),
              suffixIcon: _loadingTeacher
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                  : _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)), onPressed: () { _searchCtrl.clear(); setState(() { _suggestions = []; _showSuggestions = false; _foundStudent = null; _guardians = []; _lookupError = null; }); })
                      : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: KukieAccent.violet, width: 2)),
              isDense: true,
            ),
            onChanged: _onSearchChanged,
            onSubmitted: _lookupStudent,
          ),

          // ── Suggestion dropdown ──
          if (_showSuggestions && _suggestions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _suggestions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final fullName = '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}'.trim();
                  final sid = s['studentId'] as String? ?? '';
                  final cls = s['className'] as String? ?? '';
                  return InkWell(
                    onTap: () => _selectSuggestion(s),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(i == 0 ? 12 : 0),
                      bottom: Radius.circular(i == _suggestions.length - 1 ? 12 : 0),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        border: i < _suggestions.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))) : null,
                      ),
                      child: Row(children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(color: KukieAccent.violetTint, shape: BoxShape.circle),
                          child: const Center(child: Icon(Icons.person_rounded, size: 18, color: KukieAccent.violet)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                          Text(fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                          Text('$sid${cls.isNotEmpty ? '  •  $cls' : ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ])),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          if (_lookupError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFCA5A5))),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_lookupError!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)))),
              ]),
            ),
          ],

          if (_foundStudent != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF93C5FD))),
              child: Row(children: [
                const Icon(Icons.person_rounded, color: Color(0xFF3B82F6), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'Student: ${_foundStudent!['firstName']} ${_foundStudent!['lastName']}  (${_foundStudent!['studentId']})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  overflow: TextOverflow.ellipsis,
                )),
              ]),
            ),
          ],

          if (_guardians.isNotEmpty && safeId != null) ...[
            const SizedBox(height: 10),
            const Text('Select Guardian to Message:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: safeId,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: KukieAccent.violet),
                  items: _guardians.map((g) => DropdownMenuItem<String>(
                    value: g['id'] as String,
                    child: Text('${g['fullName']}  •  ${g['relationshipType']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final m = _guardians.firstWhere((g) => g['id'] == id);
                    setState(() { _selectedGuardianId = id; _targetId = id; _targetName = m['fullName'] as String; });
                    _fetchChat(id);
                  },
                ),
              ),
            ),
          ],
        ]),
      ),
      const Divider(height: 1),
    ]);
  }

  Widget _buildChat() {
    if (_loadingMsgs) return const Center(child: CircularProgressIndicator());
    if (_messages.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.mark_chat_read_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('No messages with $_targetName yet.', style: const TextStyle(fontSize: 13, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          const Text('Type below to start chatting.', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final isMe = msg.isMe;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMe ? KukieAccent.violet : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (!isMe) ...[
                Text('${msg.senderName} (${msg.senderRole})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KukieAccent.violet)),
                const SizedBox(height: 4),
              ],
              Text(msg.content, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : const Color(0xFF1E293B), height: 1.35)),
              const SizedBox(height: 6),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(msg.timestampText, style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : const Color(0xFF94A3B8))),
                if (isMe) ...[const SizedBox(width: 4), const Icon(Icons.done_all_rounded, size: 12, color: Colors.white70)],
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
      child: SafeArea(
        top: false,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _msgCtrl,
              maxLines: 1,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Message $_targetName...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                isDense: true,
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: KukieAccent.violet,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _send,
              customBorder: const CircleBorder(),
              child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.send_rounded, color: Colors.white, size: 20)),
            ),
          ),
        ]),
      ),
    );
  }
}
