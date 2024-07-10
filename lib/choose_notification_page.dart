import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'bottom-sheet/custom_bottom_sheet.dart';
import 'input_bottom_sheet.dart';
import 'lan_notification.dart';
import 'notification_client.dart';

class ChooseNotificationPage extends StatefulWidget {
  const ChooseNotificationPage({super.key, required this.masterAddress});

  final String masterAddress;

  @override
  _ChooseNotificationPageState createState() => _ChooseNotificationPageState();
}

class _ChooseNotificationPageState extends State<ChooseNotificationPage> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late final NotificationClient notifClient;

  LanNotificationRequest testNotif = LanNotificationRequest(
      title: '☕', content: 'Coffee is Ready!', recipientAddress: ['*'], id: 2);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    init();
  }

  Future<void> init() async {
    await initNotification();
    initNotifClient();
  }

  void initNotifClient() {
    notifClient = NotificationClient(
      channel: IOWebSocketChannel.connect('ws://${widget.masterAddress}:53123'),
      masterAddress: InternetAddress(widget.masterAddress),
      onNewNotification: (notif) {
        print('RECEIVED NOTIF: $notif');
        _showNotification(title: notif.title, body: notif.content);
      },
    );

    notifClient.sendInitialMessage();
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

  void sendNotif(LanNotificationRequest notif) {
    notifClient.sendNotification(notif);
  }

  // void listenNotifications() {
  //   notifClient.channel.stream.listen(onData);
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

  Widget titleWidget() {
    return ListTile(
      title: Text(
        'Notifications',
        style: TextStyle(fontSize: 22),
      ),
      subtitle: Text(
        'What notifs are we sending?',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget foodNotifWidget() {
    return ListTile(
      onTap: () {
        foodSheet();
      },
      title: Text('Food'),
      subtitle: Text('Ready made food related notifications.'),
    );
  }

  void foodSheet() {
    showCustomBottomSheet(
      context,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Food Notifications',
              style: TextStyle(fontSize: 20),
            ),
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(15),
              child: ListTile(
                onTap: () {
                  previewNotifSheet(testNotif);
                },
                leading: Text(
                  testNotif.title,
                  style: TextStyle(fontSize: 20),
                ),
                title: Text(testNotif.content),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 300,
              child: Material(
                surfaceTintColor: Colors.green,
                elevation: 2,
                borderRadius: BorderRadius.circular(15),
                child: ListTile(
                  onTap: () {
                    print('New food');
                  },
                  leading: Icon(Icons.new_label),
                  title: Text('Add New'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void previewNotifSheet(LanNotificationRequest notif) {
    showCustomBottomSheet(
      context,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Notification to Send',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22),
              ),
            ),
            SizedBox(
              width: 400,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(15),
                child: const ListTile(
                  title: Text('☕'),
                  subtitle: Text('Coffee is Ready!'),
                  trailing: Tooltip(
                    message: 'Who should receive this notification?',
                    child: Card(
                        child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20.0, vertical: 4),
                      child: Text('All'),
                    )),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ButtonStyle(
                  surfaceTintColor: WidgetStateProperty.all<Color>(
                      Colors.green), // Change the color as needed
                ),
                onPressed: () {
                  sendNotif(testNotif);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Send',
                  style: TextStyle(fontSize: 25),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: IconButton.filled(
          onPressed: () async {
            // await _showNotification();
          },
          icon: Icon(Icons.abc)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleWidget(),
              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    foodNotifWidget(),
                  ],
                ),
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
