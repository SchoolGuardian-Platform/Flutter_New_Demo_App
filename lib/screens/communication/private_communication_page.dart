import 'package:flutter/material.dart';
import '../../models/communication_models.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';

/// Role-Gated Private Communication Hub for Parents, Teachers, and Admins
class PrivateCommunicationPage extends StatefulWidget {
  const PrivateCommunicationPage({super.key, required this.user});

  static const routeName = '/private-communication';

  final User user;

  @override
  State<PrivateCommunicationPage> createState() => _PrivateCommunicationPageState();
}

class _PrivateCommunicationPageState extends State<PrivateCommunicationPage> {
  final TextEditingController _messageController = TextEditingController();
  late List<PrivateChannel> _availableChannels;
  late PrivateChannel _selectedChannel;

  @override
  void initState() {
    super.initState();
    _initializeChannels();
  }

  void _initializeChannels() {
    final role = widget.user.role;

    final teacherParentChannel = PrivateChannel(
      id: 'ch_teacher_parent',
      channelTitle: 'Teacher ↔ Parent Channel',
      subtitle: 'Academic progress, assignment feedback & wellbeing updates',
      icon: Icons.family_restroom,
      participantName: role == UserRole.parent ? 'Alex Morgan (Class Teacher)' : 'Parent (John Doe)',
      participantRole: role == UserRole.parent ? 'Teacher' : 'Parent',
      allowedRoles: [UserRole.parent, UserRole.teacher],
      messages: [
        ChatMessage(
          id: 'm1',
          senderName: 'Alex Morgan (Teacher)',
          senderRole: 'Teacher',
          content: 'Hello! I wanted to touch base regarding your child\'s recent mathematics project. They scored an impressive 95%!',
          timestampText: 'Yesterday, 04:15 PM',
          isMe: role == UserRole.teacher,
        ),
        ChatMessage(
          id: 'm2',
          senderName: role == UserRole.parent ? widget.user.fullName : 'Parent (John Doe)',
          senderRole: 'Parent',
          content: 'Thank you so much for the update, Mr. Morgan! We have been practicing algebra every evening.',
          timestampText: 'Yesterday, 05:20 PM',
          isMe: role == UserRole.parent,
        ),
        ChatMessage(
          id: 'm3',
          senderName: 'Alex Morgan (Teacher)',
          senderRole: 'Teacher',
          content: 'Great progress! Please let me know if you have any questions regarding next week\'s science field trip.',
          timestampText: 'Today, 09:30 AM',
          isMe: role == UserRole.teacher,
        ),
      ],
    );

    final adminParentChannel = PrivateChannel(
      id: 'ch_admin_parent',
      channelTitle: 'Administration ↔ Parent Portal',
      subtitle: 'School policies, fee statements & guardian approvals',
      icon: Icons.admin_panel_settings_outlined,
      participantName: 'School Administration & Office',
      participantRole: 'Admin',
      allowedRoles: [UserRole.parent, UserRole.admin],
      messages: [
        ChatMessage(
          id: 'am1',
          senderName: 'School Administration',
          senderRole: 'Admin',
          content: 'Notice: Mid-term report cards have been published. Please verify guardian link details if needed.',
          timestampText: '2 days ago',
          isMe: role == UserRole.admin,
        ),
        ChatMessage(
          id: 'am2',
          senderName: role == UserRole.parent ? widget.user.fullName : 'Parent',
          senderRole: 'Parent',
          content: 'Received, thank you. I have submitted the updated contact form.',
          timestampText: 'Yesterday, 10:14 AM',
          isMe: role == UserRole.parent,
        ),
      ],
    );

    final adminTeacherChannel = PrivateChannel(
      id: 'ch_admin_teacher',
      channelTitle: 'Administration ↔ Teacher Memos',
      subtitle: 'Staff announcements, curriculum reviews & class rosters',
      icon: Icons.school_outlined,
      participantName: 'School Principal & Academic Dean',
      participantRole: 'Admin',
      allowedRoles: [UserRole.teacher, UserRole.admin],
      messages: [
        ChatMessage(
          id: 'tm1',
          senderName: 'Academic Dean',
          senderRole: 'Admin',
          content: 'Faculty Notice: Staff meeting scheduled for Friday at 03:30 PM in Room 204.',
          timestampText: 'Yesterday, 02:00 PM',
          isMe: role == UserRole.admin,
        ),
        ChatMessage(
          id: 'tm2',
          senderName: role == UserRole.teacher ? widget.user.fullName : 'Alex Morgan (Teacher)',
          senderRole: 'Teacher',
          content: 'Understood. I will prepare the section attendance summary prior to the meeting.',
          timestampText: 'Today, 08:45 AM',
          isMe: role == UserRole.teacher,
        ),
      ],
    );

    // Filter channels strictly based on User Role
    _availableChannels = [
      if (role == UserRole.parent || role == UserRole.teacher) teacherParentChannel,
      if (role == UserRole.parent || role == UserRole.admin) adminParentChannel,
      if (role == UserRole.teacher || role == UserRole.admin) adminTeacherChannel,
    ];

    if (_availableChannels.isEmpty) {
      _availableChannels = [teacherParentChannel];
    }
    _selectedChannel = _availableChannels.first;
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _selectedChannel.messages.add(
        ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          senderName: widget.user.fullName,
          senderRole: widget.user.role.label,
          content: text,
          timestampText: 'Just now',
          isMe: true,
        ),
      );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Private Communication Hub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              'Role: ${widget.user.role.label} Channel',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔒 Confidentiality & Student Privacy Notice Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                border: Border(bottom: BorderSide(color: Color(0xFFFDE68A))),
              ),
              child: Row(
                children: const [
                  Icon(Icons.security_rounded, size: 18, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔒 Confidential Guardian & Faculty Channel • Students do not have access to this messaging portal.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Channel Selection Selector Pills
            if (_availableChannels.length > 1)
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.white,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _availableChannels.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final ch = _availableChannels[idx];
                    final isSelected = ch.id == _selectedChannel.id;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(ch.channelTitle),
                      selectedColor: const Color(0xFFEEF2FF),
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                      ),
                      onSelected: (_) => setState(() => _selectedChannel = ch),
                    );
                  },
                ),
              ),

            // Active Channel Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_selectedChannel.icon, color: const Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedChannel.channelTitle,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedChannel.subtitle,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Chat Messages Feed
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: _selectedChannel.messages.length,
                itemBuilder: (ctx, idx) {
                  final msg = _selectedChannel.messages[idx];
                  return _MessageBubble(message: msg);
                },
              ),
            ),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type confidential message to ${_selectedChannel.participantRole}...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.senderName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isMe ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : const Color(0xFF1E293B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.timestampText,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white60 : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
