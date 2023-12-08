part of 'socket_cubit.dart';

class SocketState extends Equatable {
  const SocketState();

  @override
  List<Object> get props => [];
}

class SocketInitial extends SocketState {}

class SocketLoading extends SocketState {}

class SocketConnected extends SocketState {
  final User user;
  const SocketConnected({required this.user});

  @override
  List<Object> get props => [user];
}

class SocketDataReceived extends SocketState {
  final dynamic data;
  const SocketDataReceived({required this.data});

  @override
  List<Object> get props => [data];
}

class SocketError extends SocketState {}
