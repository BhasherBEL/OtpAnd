import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactInfo {
  static final currentContacts = ValueNotifier<List<Contact>>([]);

  static Future<void> loadAll() async {
    currentContacts.value = await FlutterContacts.getContacts(
      withProperties: true,
      withThumbnail: true,
    );
  }
}
