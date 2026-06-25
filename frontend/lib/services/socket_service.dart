import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/api_config.dart';

typedef SocketCallback = void Function(dynamic data);

class SocketService {
  io.Socket? _socket;
  String? _token;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect(String accessToken) async {
    if (_socket?.connected == true && _token == accessToken) return;
    disconnect();
    _token = accessToken;

    _socket = io.io(
      ApiConfig.wsUrl,
      io.OptionBuilder()
          .setPath('/ws')
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': accessToken})
          .build(),
    );

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void joinRoom(String roomId) => _socket?.emit('room:join', roomId);
  void leaveRoom(String roomId) => _socket?.emit('room:leave', roomId);
  void sendProgress(String roomId, int progress) =>
      _socket?.emit('room:progress', {'roomId': roomId, 'progress': progress});
  void submitScore(String roomId, int score) =>
      _socket?.emit('room:submit', {'roomId': roomId, 'score': score});
  void setReady(String roomId, bool ready) =>
      _socket?.emit('room:ready', {'roomId': roomId, 'ready': ready});

  void on(String event, SocketCallback handler) => _socket?.on(event, handler);
  void off(String event) => _socket?.off(event);
}
