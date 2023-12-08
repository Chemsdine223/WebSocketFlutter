// class Conversation {
//   final String id;
//   final int user1Id;
//   final int user2Id;
//   final String receiverUsername;
//   final String senderUsername;

//   Conversation({
//     required this.id,
//     required this.user1Id,
//     required this.user2Id,
//     required this.receiverUsername,
//     required this.senderUsername,
//   });

//   factory Conversation.fromJson(Map<String, dynamic> json) {
//     return Conversation(
//         id: json['conversation_id'],
//         user1Id: json['user1_id'],
//         user2Id: json['user2_id'],
//         receiverUsername: json['user2_username'],
//         senderUsername: json['user1_username']);
//   }
// }

// {
//     "id": "12-13",
//     "participants": [
//         {
//             "id": 12,
//             "username": "testA"
//         },
//         {
//             "id": 13,
//             "username": "testB"
//         }
//     ],
//     "messages": [
//         {
//             "senderId": 12,
//             "content": "Hello",
//             "timestamp": "2023-12-02T15:29:44.000Z"
//         },
//         {
//             "senderId": 13,
//             "content": "Hello",
//             "timestamp": "2023-12-02T15:29:44.000Z"
//         }
//     ]
// },

class Conversation {
  final String id;
  final List<Participant> participants;
  final List<Message> messages;

  Conversation({
    required this.id,
    required this.participants,
    required this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
        id: json['id'],
        participants: List<Participant>.from(
          json['participants'].map(
            (participant) => Participant.fromJson(participant),
          ),
        ),
        messages: List<Message>.from(
          json['messages'].map(
            (message) => Message.fromJson(message),
          ),
        )
        // messages: Message.fromJson(json['messages']),
        );
  }
}

class Participant {
  final int id;
  final String username;

  Participant({
    required this.id,
    required this.username,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'],
      username: json['username'],
    );
  }
}
 

class Message {
  final int senderId;
  final String content;
  final String timestamp;
  // final String conversationId;

  Message({
    required this.senderId,
    required this.content,
    required this.timestamp,
    // required this.conversationId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      senderId: json['senderId'],
      content: json['content'],
      timestamp: json['timestamp'],
      // conversationId: json['conversation_id'],
    );
  }
}

class User {
  final int id;
  final String name;

  User({required this.name, required this.id});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['username'],
      id: json['id'],
    );
  }
}
