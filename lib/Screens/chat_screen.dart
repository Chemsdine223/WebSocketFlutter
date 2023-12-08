import 'dart:convert';
import 'dart:math';

import 'package:chatapp/Logic/cubit/socket_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:screenshot/screenshot.dart';

import '../Models/models.dart';
import 'chat_room.dart';
import 'network_services.dart';

typedef NavigateToFunction = void Function(Widget page);

class ChatScreen extends StatefulWidget {
  final User user;
  final NetworkService networkService;
  // final IOWebSocketChannel channel;
  const ChatScreen({
    Key? key,
    required this.user,
    required this.networkService,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Conversation> _conversations = [];

  final destinationController = TextEditingController();
  final contentController = TextEditingController();

  final Map<String, String> _typingStatusMap = {};

  Future<void> getConversations() async {
    // print('called');
    final response = await NetworkService().fetchConversations(widget.user.id);
    if (mounted) {
      setState(() {
        _conversations = response;
      });
    }
  }

  bool typing = false;

  @override
  void initState() {
    super.initState();

    // context.read<SocketCubit>().listenToSocket(BuildContext context);

    getConversations();

    widget.networkService.webSocketMessageStream.listen(
      (message) {
        _handleReceivedMessage(message);
      },
      // onDone: () {
      //   print('Dooone');
      // },
    );
  }

  @override
  void dispose() {
    widget.networkService.disposeWebSocket();
    super.dispose();
  }

  void _handleReceivedMessage(dynamic message) {
    final parsedMessage = jsonDecode(message);
    // print(parsedMessage);

    switch (parsedMessage['type']) {
      case 'chat':
        createConversations(parsedMessage, null);

        break;
      case 'typing':
        handleTyping(parsedMessage);
        break;
      case 'stoppedTyping':
        handleStoppedTyping(parsedMessage);
        break;
      default:
    }
  }

  handleTyping(dynamic message) {
    if (message['type'] == 'typing') {
      final conversationId = message['conversationId'];

      setState(() {
        _typingStatusMap[conversationId] = conversationId;
      });
    }
  }

  handleStoppedTyping(dynamic message) {
    if (message['type'] == 'stoppedTyping') {
      final conversationId = message['conversationId'];

      setState(() {
        _typingStatusMap.remove(conversationId);
      });
    }
  }

  createConversations(dynamic message, int? id) {
    // print('message: $message');
    bool conversationExists = _conversations.any(
      (conversation) {
        return conversation.id == message['conversationId'];
      },
    );

    if (!conversationExists) {
      setState(() {
        _conversations.add(
          Conversation(
            id: message['conversationId'],
            participants: [
              Participant(id: widget.user.id, username: widget.user.name),
              Participant(
                  id: message['senderId'], username: message['senderUsername']),
            ],
            messages: [
              Message(
                  senderId: id ?? message['senderId'],
                  content: message['content'],
                  timestamp: DateTime.now().toString())
            ],
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // context.read<SocketCubit>().listenToSocket(context);

    // connectionCheck();

    return BlocListener<SocketCubit, SocketState>(
      listener: (context, state) {
        print(state);
        if (state is SocketError) {
          context.read<SocketCubit>().goHome(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          actions: [
            Builder(builder: (context) {
              return IconButton(
                  onPressed: () {
                    showBottomSheet(
                      context: context,
                      builder: (context) {
                        return Container(
                          color: Colors.red,
                          child: Form(
                            child: Column(
                              children: [
                                TextField(
                                  controller: destinationController,
                                  decoration:
                                      const InputDecoration(hintText: 'To:'),
                                ),
                                TextField(
                                  controller: contentController,
                                  decoration: const InputDecoration(
                                      hintText: 'Message:'),
                                ),
                                MaterialButton(
                                  onPressed: () async {
                                    var smallerId = min(
                                        int.parse(destinationController.text
                                            .toString()),
                                        widget.user.id);

                                    var largerId = max(
                                        int.parse(destinationController.text),
                                        widget.user.id);

                                    final Map<String, dynamic> messageData = {
                                      'type': 'chat',
                                      'content':
                                          contentController.text.toString(),
                                      'senderUsername': widget.user.name,
                                      'senderId': widget.user.id,
                                      'conversationId': '$smallerId-$largerId',
                                      'recipientId': destinationController.text,
                                      'timestamp': DateTime.now().toString()
                                    };

                                    final username = await NetworkService()
                                        .getUsername(int.parse(
                                            destinationController.text));

                                    widget.networkService.sendWebSocketMessage(
                                        jsonEncode(messageData));

                                    // print('ConversationId:'
                                    //     '$smallerId - $largerId');

                                    createConversations({
                                      'conversationId': '$smallerId-$largerId',
                                      'senderId':
                                          int.parse(destinationController.text),
                                      'content': contentController.text,
                                      'senderUsername': username,
                                    }, widget.user.id);
                                  },
                                  child: const Text('Send message'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.message,
                    color: Colors.black,
                  ));
            })
          ],
          backgroundColor: Colors.white38,
          toolbarHeight: 100,
          title: const Text(
            'Chat',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 50,
            ),
          ),
          centerTitle: false,
          elevation: 0,
        ),
        body: Container(
          // color: Colors.amber,
          child: _conversations.isEmpty
              ? const Center(child: Text('...'))
              : RefreshIndicator(
                  onRefresh: getConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      final conversationId = conversation.id;
                      final typingUserId = _typingStatusMap[conversationId];

                      final receiverId = conversation.participants.firstWhere(
                        (element) => element.id != widget.user.id,
                        orElse: () => Participant(id: -1, username: 'username'),
                      );

                      return ListTile(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatRoom(
                                  user: widget.user,
                                  // receiverId: conversation.user1Id,
                                  // userId: conversation.user2Id,
                                  receiver: receiverId.id.toString(),
                                  conversation: conversation,
                                  networkService: widget.networkService,
                                  messages: conversation.messages,
                                  // username: widget.user.name,
                                ),
                              ));
                        },
                        title: Text(
                          (conversation.participants[0].id == widget.user.id
                                  ? conversation.participants[1].username
                                  : conversation.participants[0].username) +
                              (typingUserId != null ? ' is typing...' : ''),
                        ),
                        subtitle: Text(conversation.messages.last.content),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
