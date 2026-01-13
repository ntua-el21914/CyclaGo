import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cyclago/core/destination_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String islandName;

  const GroupChatScreen({super.key, required this.islandName});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String _currentUsername = 'Cyclist';
  String? _selectedMessageId; // Track which message shows contextual menu 

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    if (_currentUserId.isEmpty) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('username')) {
        setState(() {
          _currentUsername = userDoc.data()!['username'];
        });
      }
    } catch (e) {
      print("Error fetching name for chat: $e");
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear(); 

    await FirebaseFirestore.instance
        .collection('destinations')
        .doc(widget.islandName.toLowerCase())
        .collection('messages')
        .add({
      'text': messageText,
      'senderId': _currentUserId,
      'senderName': _currentUsername,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7); // Your specific light blue

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(width: 1.5, color: primaryBlue),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 10,
                    child: IconButton(
                      // --- UPDATED COLOUR HERE ---
                      icon: const Icon(Icons.arrow_back, color: primaryBlue), 
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(DestinationService.getIslandImage(widget.islandName)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "${widget.islandName} Chat",
                        style: GoogleFonts.hammersmithOne(
                          color: Colors.black, 
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // --- MESSAGES LIST ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('destinations')
                    .doc(widget.islandName.toLowerCase())
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: primaryBlue));
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data() as Map<String, dynamic>;
                      final bool isMe = msg['senderId'] == _currentUserId;
                      final timestamp = msg['timestamp'] as Timestamp?;
                      final String senderId = msg['senderId'] ?? '';

                      // Get the next message (older message, since list is reversed)
                      Timestamp? nextTimestamp;
                      String? nextSenderId;
                      if (index < messages.length - 1) {
                        final nextMsg = messages[index + 1].data() as Map<String, dynamic>;
                        nextTimestamp = nextMsg['timestamp'] as Timestamp?;
                        nextSenderId = nextMsg['senderId'] as String?;
                      }

                      // Check if this is a consecutive message from the same sender
                      final bool isConsecutive = nextSenderId != null && nextSenderId == senderId;

                      // Determine if we should show the timestamp (5+ min gap)
                      bool showTimestamp = false;
                      if (timestamp != null) {
                        if (nextTimestamp == null) {
                          showTimestamp = true; // First message ever
                        } else {
                          final gap = timestamp.toDate().difference(nextTimestamp.toDate()).inMinutes;
                          showTimestamp = gap >= 5;
                        }
                      }

                      // Determine if we should show a date separator above this message
                      bool showDateSeparator = false;
                      if (timestamp != null) {
                        if (nextTimestamp == null) {
                          showDateSeparator = true; // First message ever
                        } else {
                          final currentDate = DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
                          final nextDate = DateTime(nextTimestamp.toDate().year, nextTimestamp.toDate().month, nextTimestamp.toDate().day);
                          showDateSeparator = currentDate != nextDate;
                        }
                      }

                      // Check if message is deleted
                      final bool isDeleted = msg['isDeleted'] == true;
                      final String messageText = isDeleted ? 'This message was deleted' : (msg['text'] ?? '');
                      final String messageId = messages[index].id;

                      return Column(
                        children: [
                          if (showDateSeparator && timestamp != null)
                            _buildDateSeparator(timestamp.toDate(), primaryBlue),
                          _buildMessageBubble(
                            messageText,
                            isMe,
                            msg['senderName'] ?? 'Cyclist',
                            primaryBlue,
                            showTimestamp ? timestamp : null,
                            isConsecutive,
                            isDeleted,
                            messageId,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // --- INPUT BOX ---
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.hammersmithOne(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: GoogleFonts.hammersmithOne(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF0F2F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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

  Widget _buildDateSeparator(DateTime date, Color primaryBlue) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              dateText,
              style: GoogleFonts.hammersmithOne(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String senderName, Color primaryBlue, Timestamp? timestamp, bool isConsecutive, bool isDeleted, String messageId) {
    String timeString = '';
    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }

    final bool isSelected = _selectedMessageId == messageId;

    return Column(
      children: [
        // Timestamp above the message
        if (timeString.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0, top: 8.0),
            child: Text(
              timeString,
              style: GoogleFonts.hammersmithOne(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ),
        // Contextual row with icons (shown when selected)
        if (isSelected && !isDeleted)
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildContextButton(
                    icon: Icons.copy,
                    color: primaryBlue,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text));
                      setState(() => _selectedMessageId = null);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Message copied', style: GoogleFonts.hammersmithOne()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 8),
                    _buildContextButton(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: () {
                        setState(() => _selectedMessageId = null);
                        _deleteMessage(messageId);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        // Message bubble with long-press
        GestureDetector(
          onLongPress: isDeleted ? null : () {
            setState(() {
              _selectedMessageId = _selectedMessageId == messageId ? null : messageId;
            });
          },
          onTap: () {
            if (_selectedMessageId != null) {
              setState(() => _selectedMessageId = null);
            }
          },
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: isConsecutive ? 1 : 5),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isDeleted 
                    ? Colors.grey[200] 
                    : (isMe ? primaryBlue : const Color(0xFFF0F2F5)), 
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe && !isDeleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        senderName,
                        style: GoogleFonts.hammersmithOne(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: GoogleFonts.hammersmithOne(
                      color: isDeleted 
                          ? Colors.grey[500] 
                          : (isMe ? Colors.white : Colors.black87),
                      fontSize: 16,
                      fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContextButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }



  Future<void> _deleteMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('destinations')
          .doc(widget.islandName.toLowerCase())
          .collection('messages')
          .doc(messageId)
          .update({'isDeleted': true});
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete message',
            style: GoogleFonts.hammersmithOne(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
