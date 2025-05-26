import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:otpand/objs.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:otpand/utils/gnss.dart';

class ContactItem extends StatelessWidget {
  final Contact contact;
  final void Function(Location) onTap;
  final BuildContext rootContext;

  const ContactItem({
    super.key,
    required this.contact,
    required this.onTap,
    required this.rootContext,
  });

  @override
  Widget build(BuildContext context) {
    final address =
        contact.addresses.isNotEmpty ? contact.addresses.first : null;
    final addressString = address != null
        ? [
            address.street,
            address.city,
            address.postalCode,
            address.country,
          ].where((s) => s.isNotEmpty).join(', ')
        : '';

    return ListTile(
      leading: contact.thumbnail != null && contact.thumbnail!.isNotEmpty
          ? CircleAvatar(
              backgroundImage: MemoryImage(contact.thumbnail!),
              radius: 20,
            )
          : CircleAvatar(radius: 20, child: Icon(Icons.person)),
      title: Text(contact.displayName),
      subtitle: addressString.isNotEmpty
          ? Text(
              addressString,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () async {
        final v = await resolveAddress(addressString);
        if (v == null) return;
        double lat = v.$1;
        double lon = v.$2;

        onTap(
          Location(
            name: contact.displayName,
            displayName: contact.displayName,
            lat: lat,
            lon: lon,
            stop: null,
          ),
        );
      },
      visualDensity: VisualDensity(vertical: -4),
    );
  }
}
