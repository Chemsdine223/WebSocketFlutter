import 'package:bloc/bloc.dart';
import 'package:chatapp/Screens/login.dart';
import 'package:equatable/equatable.dart';

import 'package:chatapp/Screens/network_services.dart';
import 'package:flutter/material.dart';

import '../../Models/models.dart';

part 'socket_state.dart';

class SocketCubit extends Cubit<SocketState> {
  NetworkService networkService;

  SocketCubit(this.networkService) : super(SocketInitial());

  // networkService.webSocketChannel.stream.listen((event) {

  //   }).onDone(() {
  //     // print('done');
  //     emit(SocketError());
  //   });

  void listenToSocket(BuildContext context) {
    print('Listening ...');
    networkService.webSocketMessageStream.listen(onDone: () {
      print('Done');
      emit(SocketError());
    }, (event) {
      print('event $event');
    });
  }

  // Future<void> login(
  //     String username, String password, BuildContext context) async {
  //   emit(SocketLoading());
  //   try {

  //     // emit(SocketConnected(user: user));
  //   } catch (e) {
  //     emit(SocketError());
  //   }
  // }

  goHome(BuildContext context) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LoginScreen(networkService: networkService)));
  }

  // getOnlineUsers() {
  //   sendMessage(jsonEncode({'type': 'getOnlineStatus'}));
  // }

  // sendMessage(dynamic message) {
  //   networkService.webSocketChannel.sink.add(message);
  // }
}
