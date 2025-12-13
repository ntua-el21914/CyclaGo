import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatScreen extends StatefulWidget {
  final String islandName; // π.χ. "Naxos"

  const GroupChatScreen({super.key, required this.islandName});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // --- ΣΤΕΙΛΕ ΜΗΝΥΜΑ ---
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final String messageText = _messageController.text.trim();
    _messageController.clear(); // Καθαρίζουμε το πεδίο αμέσως

    // Προσθήκη στο Firebase
    // Δομή: destinations -> naxos -> messages -> (auto-id)
    await FirebaseFirestore.instance
        .collection('destinations')
        .doc(widget.islandName.toLowerCase()) // π.χ. 'naxos'
        .collection('messages')
        .add({
      'text': messageText,
      'senderId': _currentUserId,
      'senderName': 'Cyclist', // Εδώ θα μπορούσαμε να τραβήξουμε το πραγματικό όνομα
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Scroll στο τέλος μετά το μήνυμα
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      // --- HEADER ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group, color: primaryBlue, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "${widget.islandName} Chat",
              style: GoogleFonts.hammersmithOne(color: Colors.black, fontSize: 20),
            ),
          ],
        ),
      ),
      
      body: Column(
        children: [
          // --- ΛΙΣΤΑ ΜΗΝΥΜΑΤΩΝ (LIVE) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('destinations')
                  .doc(widget.islandName.toLowerCase())
                  .collection('messages')
                  .orderBy('timestamp', descending: true) // Τα πιο πρόσφατα κάτω (γιατί θα κάνουμε reverse list)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: primaryBlue));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Ξεκινάει από κάτω προς τα πάνω
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = msg['senderId'] == _currentUserId;

                    return _buildMessageBubble(
                      msg['text'] ?? '',
                      isMe,
                      msg['senderName'] ?? 'User',
                    );
                  },
                );
              },
            ),
          ),

          // --- ΠΕΔΙΟ ΕΙΣΑΓΩΓΗΣ ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
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
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String senderName) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1269C7) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
          ),
          boxShadow: [
            if (!isMe)
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
            Text(
              senderName,
              style: GoogleFonts.hammersmithOne(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              text,
              style: GoogleFonts.hammersmithOne(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}