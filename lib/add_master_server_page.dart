import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_hub_client/main.dart';

import 'bottom-sheet/custom_bottom_sheet.dart';
import 'choose_notification_page.dart';
import 'input_bottom_sheet.dart';

import 'package:dart_ping/dart_ping.dart';

import 'notification_center_page.dart';

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

class AddMasterServerPage extends StatefulWidget {
  const AddMasterServerPage({super.key});

  @override
  _AddMasterServerPageState createState() => _AddMasterServerPageState();
}

class _AddMasterServerPageState extends State<AddMasterServerPage> {
  String localIp = '';

  @override
  initState() {
    super.initState();

    getLocalIP();
  }

  getLocalIP() async {
    var result = await getMyLocalIp();
    if (result != null) {
      setState(() {
        localIp = result.address;
      });
    }
  }

  void navigatoNotificationCenterPage(String masterAddress) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ChooseNotificationPage(
        masterAddress: masterAddress,
      ),
    ));
  }

  Future<void> isNotificationServerOnline(String address) async {
    final pingData = await Ping(address, count: 1, timeout: 1).stream.first;

    if (pingData.response != null) {
      serverIsOnlineSheet(address);
      navigatoNotificationCenterPage(address);
    } else {
      serverIsOfflineSheet(address);
    }

    print(pingData);
  }

  void serverIsOfflineSheet(String address) {
    showCustomBottomSheet(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(Icons.stop_circle),
            title: Text(
              'Notification center offline ($address)',
              style: const TextStyle(fontSize: 22),
            ),
            subtitle: const Text(
              'The notification center seems to offline.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1. Make sure that the device is on and app is running.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                '2. Make sure you are in same network. This device is in network: $address',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                '3. Check that the ip address $address is the actual notification center ip address',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }

  void serverIsOnlineSheet(String address) {
    showCustomBottomSheet(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(
              Icons.abc,
              color: Colors.green,
            ),
            title: Text(
              'Yey! Notification center online ($address)',
              style: const TextStyle(fontSize: 22),
            ),
            // subtitle: const Text(
            //   'The notification center seems to offline.',
            //   style: TextStyle(fontSize: 16, color: Colors.grey),
            // ),
          ),
          ElevatedButton(
              onPressed: () => Navigator.pop(context), child: Text('Continue')),
          SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }

  Future<void> promptServerAddress() async {
    final result = await showInputBottomSheet(context,
        label: 'Ip Address', initialText: localIp);

    print(result);
    if (result != null) {
      await isNotificationServerOnline(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 650,
          child: ListTile(
            title: const Text(
              'Lets connect your device to your notification center!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25),
            ),
            subtitle: ElevatedButton(
              onPressed: () async {
                await promptServerAddress();
              },
              child: Text(
                'Connect',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
