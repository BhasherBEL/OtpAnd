import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactInfo {
  static final currentContacts = ValueNotifier<List<Contact>>([]);

  static Future<bool> loadAll() async {
    if (!await Permission.contacts.isGranted) return false;

    currentContacts.value = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: true,
    );
    return true;
  }
}
