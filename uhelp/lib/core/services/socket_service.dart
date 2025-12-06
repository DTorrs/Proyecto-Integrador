import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../config/constants.dart';
import 'storage_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StorageService _storageService = StorageService();

  // Initialize socket connection
  Future<void> init(String serverUrl) async {
    try {
      final token = await _storageService.getToken();
      
      _socket = IO.io(serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setQuery({'token': token})
        .build());

      _socket!.connect();
      
      _socket!.onConnect((_) {
        print('Socket connected');
      });
      
      _socket!.onDisconnect((_) {
        print('Socket disconnected');
      });
      
      _socket!.onError((error) {
        print('Socket error: $error');
      });
      
      _socket!.onConnectError((error) {
        print('Socket connection error: $error');
      });
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  // Join a specific room for the current user
  Future<void> joinUserRoom(int userId) async {
    if (_socket != null && _socket!.connected) {
      print('Joining user room for user ID: $userId');
      _socket!.emit('joinRoom', userId);
    } else {
      print('Cannot join room: socket is null or not connected');
    }
  }

  // Listen for notifications
  void listenForNotifications(Function(dynamic) onNotification) {
    if (_socket != null) {
      _socket!.on(AppConstants.socketEventNotification, (data) {
        print('Notification received: $data');
        onNotification(data);
      });
    } else {
      print('Cannot listen for notifications: socket is null');
    }
  }

  // Listen for announcements
  void listenForAnnouncements(Function(dynamic) onAnnouncement) {
    if (_socket != null) {
      _socket!.on(AppConstants.socketEventAnnouncement, (data) {
        print('Announcement received: $data');
        onAnnouncement(data);
      });
    } else {
      print('Cannot listen for announcements: socket is null');
    }
  }

  // Disconnect socket
  void disconnect() {
    try {
      if (_socket != null) {
        _socket!.disconnect();
        print('Socket disconnected');
      }
    } catch (e) {
      print('Error disconnecting socket: $e');
    }
  }

  // Reconnect socket if disconnected
  void reconnect() {
    try {
      if (_socket != null && !_socket!.connected) {
        _socket!.connect();
        print('Socket reconnection attempted');
      }
    } catch (e) {
      print('Error reconnecting socket: $e');
    }
  }

  // Check if socket is connected
  bool get isConnected => _socket?.connected ?? false;
}