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
