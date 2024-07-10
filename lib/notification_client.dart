import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_hub_client/lan_notification.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'main.dart';

class NotificationClient {
  NotificationClient({
    required this.channel,
    required this.masterAddress,
    required this.onNewNotification,
  }) {
    _listenToMessages();
  }

  final WebSocketChannel channel;
  final InternetAddress masterAddress;
  final Function(LanNotification) onNewNotification;

  /// Send initial message to notification center.
  /// Like sign up you tell who you are so the server knows you.
  Future<void> sendInitialMessage() async {
    Map<String, String> metadata;
    var localip = await getMyLocalIp();

    if (localip == null) {
      Exception('Could not get local ip.');
    } else {
      metadata = {
        'type': 'initial',
        'clientIp': localip.address, // Replace with actual client IP
        'identifier': 'Meppo Servu', // Replace with actual identifier
      };
      channel.sink.add(json.encode(metadata));
    }
  }

  /// Sends notification request to notif center to be distibuted to other clients.
  /// According to options in [LanNotificationRequest].
  void sendNotification(LanNotificationRequest notification) {
    channel.sink.add(json.encode(notification.toJson()));

    if (kDebugMode) {
      print('---sendNotification()---');
      print('Send: $notification');

      print('---sendNotification()---');
    }
  }

  /// Get other devices that are connected to notif center.
  Future<List<ClientInfo>> fetchClients() async {
    final response = await http.get(Uri.parse(
        'http://${masterAddress.address}:53123/clients')); // Update with your server IP
    if (response.statusCode == 200) {
      final List<dynamic> clientListJson = json.decode(response.body);
      return clientListJson.map((json) => ClientInfo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load clients');
    }
  }

  void _listenToMessages() {
    channel.stream.listen((message) {
      try {
        var result = jsonDecode(message);

        onNewNotification(LanNotification.fromJson(result));
      } catch (e) {
        print('Received message: $message');
        print(e);
      }
    }, onError: (error) {
      print('Error occurred: $error');
    });

    if (kDebugMode) {
      print('---_listenToMessages()---');

      print('Listening websocket...');

      print('---_listenToMessages()---');
    }
  }

  void dispose() {
    channel.sink.close();
  }
}

Future<InternetAddress?> getMyLocalIp() async {
  final interfaceList = await NetworkInterface.list();
  final netInterface = interfaceList.first;

  for (var address in netInterface.addresses) {
    if (address.type == InternetAddressType.IPv4) {
      return address;
    }
  }

  return null;
}
