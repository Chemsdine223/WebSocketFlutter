import 'dart:convert';

import 'package:chatapp/Utilities/utils.dart';
import 'package:flutter/material.dart';

import 'package:chatapp/Models/models.dart';
import 'package:chatapp/Screens/network_services.dart';

class ChatRoom extends StatefulWidget {
  final String receiver;
  final Conversation conversation;
  final NetworkService networkService;
  final List<Message> messages;
  final User user;

  const ChatRoom({
    Key? key,
    required this.receiver,
    required this.conversation,
    required this.networkService,
    required this.messages,
    required this.user,
  }) : super(key: key);

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final chatController = TextEditingController();
  List<Message> _messages = [];
  final scrollController = ScrollController();

  final Map<String, dynamic> _typingStatusMap = {};

  void setMessages() {
    setState(() {
      _messages = widget.messages;
    });
  }

  String? onlineStatus;

  @override
  void initState() {
    super.initState();

    // print(widget.receiver);
    setMessages();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );

    widget.networkService
        .sendWebSocketMessage(jsonEncode({'type': 'getOnlineStatus'}));

    widget.networkService.webSocketMessageStream.listen(onDone: () {
      print('Closed');
    }, (event) {
      handleReceivedMessage(event);
      print(event);
    });
  }

  // @override
  // void dispose() {
  //   chatController.dispose();
  //   scrollController.dispose();
  //   super.dispose();
  // }

  void onlineStatusCheck(users) {
    if (!users.contains(widget.receiver)) {
      if (mounted) {
        setState(() {
          onlineStatus = 'Offline';
        });
      }
    } else {
      if (mounted) {
        setState(() {
          onlineStatus = 'Online';
        });
      }
    }
  }

  void handleReceivedMessage(message) {
    final json = jsonDecode(message);

    switch (json['type']) {
      case 'connectedUsers':
        onlineStatusCheck(json['users']);
        break;
      case 'chat':
        messageReceived(json);
        break;
      case 'typing':
        handleTyping(json);
        break;
      case 'stoppedTyping':
        handleStoppedTyping(json);

        break;
      default:
    }
  }

  void messageReceived(message) {
    if (mounted) {
      setState(() {
        widget.messages.add(
          Message(
            senderId: message['senderId'],
            content: message['content'],
            timestamp: DateTime.now().toString(),
          ),
        );
      });
    }
  }

  void handleStoppedTyping(dynamic message) {
    final conversationId = message['conversationId'];

    if (mounted) {
      setState(() {
        _typingStatusMap.remove(conversationId);
      });
    }
  }

  void handleTyping(dynamic message) {
    final userId = message['senderId'];
    final conversationId = message['conversationId'];

    if (mounted) {
      setState(() {
        _typingStatusMap[conversationId] = userId;
      });
    }
  }

  void _sendMessage() {
    final String message = chatController.text;
    if (message.isNotEmpty) {
      final Map<String, dynamic> messageData = {
        'type': 'chat',
        'content': message,
        'senderUsername': widget.user.name,
        'senderId': widget.user.id,
        'conversationId': widget.conversation.id,
        'recipientId': widget.user.id == widget.conversation.participants[0].id
            ? '${widget.conversation.participants[1].id}'
            : widget.user.id == widget.conversation.participants[1].id
                ? '${widget.conversation.participants[0].id}'
                : '',
        'timestamp': DateTime.now().toString()
      };

      widget.networkService.sendWebSocketMessage((jsonEncode(messageData)));
      // print(messageData);
      setState(() {
        _messages.add(Message(
          senderId: widget.user.id,
          content: message,
          timestamp: DateTime.now().toString(),
        ));
      });
      _stoppedTyping();
      chatController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // connectionCheck() async {
  //   print('object');
  //   final conn = await widget.networkService.isWebSocketConnected();
  //   print(conn);
  //   if (!conn) {
  //     if (context.mounted) {
  //       Navigator.pushReplacement(context, MaterialPageRoute(
  //         builder: (context) {
  //           return const LoginScreen(
  //             networkService: null,
  //           );
  //         },
  //       ));
  //     }
  //   }
  // }

  void _sendTypingStatus() {
    final Map<String, dynamic> messageData = {
      'type': "typing",
      'senderId': widget.user.id,
      'recipientId': widget.user.id == widget.conversation.participants[0].id
          ? '${widget.conversation.participants[1].id}'
          : widget.user.id == widget.conversation.participants[1].id
              ? '${widget.conversation.participants[0].id}'
              : '',
      'conversationId': widget.conversation.id,
    };

    widget.networkService.sendWebSocketMessage(jsonEncode(messageData));
  }

  void _stoppedTyping() {
    final Map<String, dynamic> messageData = {
      'type': "stoppedTyping",
      'senderId': widget.user.id,
      'recipientId': widget.user.id == widget.conversation.participants[0].id
          ? '${widget.conversation.participants[1].id}'
          : widget.user.id == widget.conversation.participants[1].id
              ? '${widget.conversation.participants[0].id}'
              : '',
      'conversationId': widget.conversation.id,
    };

    widget.networkService.sendWebSocketMessage(jsonEncode(messageData));
  }

  @override
  Widget build(BuildContext context) {
    // connectionCheck();
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     print('object');
      //     // print(widget.conversation.participants[1].id);
      //   },
      // ),
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.participants[0].id == widget.user.id
                  ? widget.conversation.participants[1].username
                  : widget.conversation.participants[0].username,
            ),
            Text(
              _typingStatusMap.containsKey(widget.conversation.id)
                  ? 'Typing...'
                  : '$onlineStatus',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView.builder(
                controller: scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  // print(_messages);
                  final message = _messages[index];

                  return ListTile(
                    subtitle: Text(
                      formatTimestampToTime(message.timestamp),
                      textAlign: message.senderId == widget.user.id
                          ? TextAlign.right
                          : TextAlign.left,
                    ),
                    title: Text(
                      message.content.toString(),
                      textAlign: message.senderId == widget.user.id
                          ? TextAlign.right
                          : TextAlign.left,
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.red,
            height: MediaQuery.of(context).size.height / 16,
            child: Center(
              child: TextField(
                controller: chatController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    onPressed: () {
                      if (chatController.text.isNotEmpty) {
                        _sendMessage();
                      }
                    },
                    icon: const Icon(Icons.send),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _sendTypingStatus();
                  } else {
                    _stoppedTyping();
                  }
                  // print(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
