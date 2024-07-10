import 'package:flutter/material.dart';
import 'dart:io';

/// Modify this function to customize your bottom sheet input.
Future<String?> showCustomBottomSheet(BuildContext context,
    {required Widget child}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(padding: MediaQuery.of(context).viewInsets, child: child);
    },
  );
}
