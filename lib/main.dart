import 'package:chatapp/Logic/cubit/socket_cubit.dart';
import 'package:chatapp/Screens/login.dart';
import 'package:chatapp/Screens/network_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  NetworkService networkService = NetworkService();
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SocketCubit(networkService),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WebSocket Chat',
        home: LoginScreen(
          networkService: networkService,
        ),
      ),
    );
  }
}
