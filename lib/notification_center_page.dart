import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key, required this.masterAddress});

  final String masterAddress;

  @override
  _NotificationCenterPageState createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  final TextEditingController _titleController =
      TextEditingController(text: 'Hello');
  final TextEditingController _contentController =
      TextEditingController(text: 'World');
  final TextEditingController _recipientController =
      TextEditingController(text: SERVER_IP);
  final TextEditingController _idController = TextEditingController(text: '2');
  List<ClientInfo> _clients = [];
  List<LanNotificationRequest> receivedNotificationList = [];
  final NotificationClient notifClient = NotificationClient(
      channel: IOWebSocketChannel.connect('ws://$SERVER_IP:53123'),
      masterAddress: InternetAddress(SERVER_IP),
      onNewNotification: (value) {
        print('New notif: $value');
      });
  InternetAddress? localIP;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _notificationsEnabled = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    askServerUrl();

    init();
    notifClient.sendInitialMessage();
  }

  Future<void> init() async {
    await initNotification();

    localIP = await getMyLocalIp();
    setState(() {});
  }

  Future<void> askServerUrl() async {}

  Future<void> initNotification() async {
    var initializationSettings = const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        linux: LinuxInitializationSettings(defaultActionName: 'test'));

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        print(details);
      },
    );

    // Create notification channel
    await _createNotificationChannel();

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotificationPermission =
          await androidImplementation?.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = grantedNotificationPermission ?? false;
      });
    }
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'your_channel_id', // id
      'your_channel_name', // name
      description: 'your channel description', // description
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Future<void> _showNotificationWithTextAction() async {
  //   const AndroidNotificationDetails androidNotificationDetails =
  //       AndroidNotificationDetails(
  //     'your channel id',
  //     'your channel name',
  //     channelDescription: 'your channel description',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     ticker: 'ticker',
  //     actions: <AndroidNotificationAction>[
  //       AndroidNotificationAction(
  //         'text_id_1',
  //         'Enter Text',
  //         icon: DrawableResourceAndroidBitmap('food'),
  //         inputs: <AndroidNotificationActionInput>[
  //           AndroidNotificationActionInput(
  //             label: 'Enter a message',
  //           ),
  //         ],
  //       ),
  //     ],
  //   );

  //   const NotificationDetails notificationDetails = NotificationDetails(
  //     android: androidNotificationDetails,
  //   );

  //   await flutterLocalNotificationsPlugin.show(2, 'Text Input Notification',
  //       'Expand to see input action', notificationDetails,
  //       payload: 'item x');
  // }
  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            fullScreenIntent: true,
            ticker: 'ticker');
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      linux: LinuxNotificationDetails(
        defaultActionName: 'test',
      ),
    );

    await flutterLocalNotificationsPlugin
        .show(12, title, body, notificationDetails, payload: 'item x');
  }

  Future<void> addNotification(LanNotificationRequest notification) async {
    receivedNotificationList.add(notification);

    await _showNotification(
        title: notification.title, body: notification.content);
  }

  Widget myNotifications(LanNotificationRequest notification) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: receivedNotificationList.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: const Text(
              'Notification',
              style: TextStyle(fontSize: 16),
            ),
            subtitle: Text(
              'Received Notification:\nTitle: ${notification.title}\nContent: ${notification.content}\nRecipient: ${notification.recipientAddress}\nID: ${notification.id}',
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    notifClient.channel.sink.close();
    _titleController.dispose();
    _contentController.dispose();
    _recipientController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Client'),
      ),
      floatingActionButton: IconButton.filled(
          onPressed: () async {
            // await _showNotification();
          },
          icon: Icon(Icons.abc)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'My IP:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Card(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${localIP?.address}'),
                  )),
                ],
              ),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Content',
                ),
              ),
              TextField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient (IP Address)',
                ),
              ),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'ID',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final notification = LanNotificationRequest(
                    title: _titleController.text,
                    content: _contentController.text,
                    recipientAddress: ['*'],
                    id: int.parse(_idController.text),
                  );

                  notifClient.sendNotification(notification);
                },
                child: Text('Send Notification'),
              ),
              // SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: () async => await fetchClients(),
              //   child: Text('Fetch Connected Clients'),
              // ),
              SizedBox(height: 20),
              Column(
                children: [
                  ExpansionTile(
                    title: const Text(
                      'Connected Clients',
                      style: TextStyle(fontSize: 22),
                    ),
                    subtitle: const Text(
                      'Click to view connected clients',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    trailing: Text(
                      '${_clients.length}',
                      style: TextStyle(fontSize: 25),
                    ),
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: _clients.length,
                        itemBuilder: (context, index) {
                          final client = _clients[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListTile(
                                title: Text(client.name),
                                subtitle: Text(client.ip),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  StreamBuilder(
                    stream: notifClient.channel.stream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final notification = LanNotificationRequest.fromJson(
                            json.decode(snapshot.data));

                        addNotification(notification);

                        print('Rec not!');
                        return ExpansionTile(
                          title: Text(
                            'Received Notifications',
                            style: TextStyle(fontSize: 22),
                          ),
                          subtitle: const Text(
                            'Click to view my notifications',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          trailing: Text(
                            '${receivedNotificationList.length}',
                            style: TextStyle(fontSize: 25),
                          ),
                          children: [
                            myNotifications(notification),
                          ],
                        );
                      } else {
                        return Text(
                          snapshot.hasError
                              ? 'Error: ${snapshot.error}'
                              : 'No notifications yet',
                          style: TextStyle(fontSize: 16),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
