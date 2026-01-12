import 'package:flutter/material.dart';
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

                      return _buildMessageBubble(
                        msg['text'] ?? '',
                        isMe,
                        msg['senderName'] ?? 'Cyclist',
                        primaryBlue,
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

  Widget _buildMessageBubble(String text, bool isMe, String senderName, Color primaryBlue) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? primaryBlue : const Color(0xFFF0F2F5), 
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
            if (!isMe)
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
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}