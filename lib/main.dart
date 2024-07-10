import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'add_master_server_page.dart';
import 'input_bottom_sheet.dart';
import 'lan_notification.dart';
import 'notification_client.dart';

class ClientInfo {
  ClientInfo({
    required this.name,
    required this.ip,
  });

  final String name;
  final String ip;

  factory ClientInfo.fromJson(Map<String, dynamic> json) => ClientInfo(
        name: json['name'] as String,
        ip: json['ip'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'ip': ip,
      };
}

String SERVER_IP = '192.168.100.32';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        /* light theme settings */
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.system,
      /* ThemeMode.system to follow system theme, 
         ThemeMode.light for light theme, 
         ThemeMode.dark for dark theme
      */
      debugShowCheckedModeBanner: false,
      home: AddMasterServerPage(),
    );
  }
}
