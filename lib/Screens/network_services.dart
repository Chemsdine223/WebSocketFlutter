import 'dart:convert';
import 'dart:async';
import 'package:chatapp/Screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import '../Logic/cubit/socket_cubit.dart';
import '../Models/models.dart';

class NetworkService {
  static String baseUrl = 'http://192.168.100.30:3000';

  Future<User> login(
      String username, String password, BuildContext context) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    // print(response.statusCode);
    // Establish WebSocket connection after successful login

    if (response.statusCode == 200) {
      final user = User.fromJson(jsonDecode(response.body));
      initWebSocket(user.id, context);
      return user;
    } else if (response.statusCode == 401) {
      throw 'Check your credentials';
    } else {
      throw response.body;
    }
  }

  Future<List<Conversation>> fetchConversations(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversationss/$id'),
    );

    // print('Response: ${response.body}');

    final data = jsonDecode(response.body) as List<dynamic>;

    // print('Conversations: $data');

    final conversations =
        data.map((json) => Conversation.fromJson(json)).toList();

    return conversations;
  }

  late IOWebSocketChannel webSocketChannel;
  late StreamController<dynamic> _webSocketController;

  Future<bool> isWebSocketConnected() async {
    bool connectionDone = await webSocketChannel.sink.done;

    print(connectionDone);

    return connectionDone;
    // !webSocketChannel.sink.done;
  }

  Stream<dynamic> get webSocketMessageStream => _webSocketController.stream;

  void initWebSocket(int userId, BuildContext context) {
    try {
      webSocketChannel = IOWebSocketChannel.connect(
        'ws://192.168.100.30:8080',
        connectTimeout: const Duration(seconds: 4),

        // headers: {},

        // pingInterval:
        // pingInterval: Duration()
      );
      _webSocketController = StreamController<dynamic>.broadcast();

      // webSocketChannel.stream.asBroadcastStream();
      // webSocketChannel.pingInterval
      context.read<SocketCubit>().listenToSocket(context);

      

      webSocketChannel.stream.listen(onDone: () {
        print('disconnected');
        // context.read<SocketCubit>().goHome(context);
      }, (dynamic data) {
        _webSocketController.add(data);
      });

      sendWebSocketMessage('{"type":"login","userId":"$userId"}');
    } catch (e) {
      print(e);
    }
  }

  Future<String> getUsername(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/username/$id'));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final username = data['username'];
      return username;
    } else {
      return data['error'];
    }
  }

  void sendWebSocketMessage(dynamic message) {
    webSocketChannel.sink.add(message);
  }

  void disposeWebSocket() {
    webSocketChannel.sink.close();
  }
}
