import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatelessWidget {
  final String islandName;

  const ChatScreen({super.key, required this.islandName});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: Colors.white,
      // --- HEADER ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              // Placeholder for island icon
              backgroundImage: NetworkImage("https://placehold.co/50x50"),
              radius: 15,
            ),
            const SizedBox(width: 10),
            Text(
              "$islandName GROUPCHAT", // e.g. "NAXOS GROUPCHAT"
              style: GoogleFonts.hammersmithOne(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      
      // --- CHAT BODY ---
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildMessageBubble(true, "Hey everyone! Anyone going to Plaka beach today?"),
                _buildMessageBubble(false, "I'm heading there in an hour!"),
                _buildMessageBubble(false, "Let's meet at the bus stop."),
              ],
            ),
          ),

          // --- INPUT BAR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: primaryBlue, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F9FC),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "Type your message...",
                      style: GoogleFonts.hammersmithOne(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.send, color: primaryBlue),
              ],
            ),
          ),
          const SizedBox(height: 20), // Safety padding for bottom
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isMe, String text) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF1269C7) : const Color(0xFFF6F9FC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.hammersmithOne(
            color: isMe ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}