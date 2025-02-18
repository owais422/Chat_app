import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final TextEditingController _messageController = TextEditingController();
  @override
  void dispose() {
    _messageController.dispose();

    super.dispose();
  }

  void submitMessage() async {
    final enteredMessage = _messageController.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser!;
    FocusScope.of(context).unfocus();
    _messageController.clear();
    final currentUserData = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .get();
    FirebaseFirestore.instance.collection('chat').add({
      "text": enteredMessage,
      "createdAt": Timestamp.now(),
      "userId": currentUser.uid,
      "username": currentUserData.data()!["username"],
      "userImage": currentUserData.data()!["image_url"]
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 1, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: const InputDecoration(labelText: "Send a message..."),
            ),
          ),
          IconButton(
            onPressed: () {
              submitMessage();
            },
            icon: const Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
          )
        ],
      ),
    );
  }
}
