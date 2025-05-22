import 'package:flutter/material.dart';
import 'package:otpand/db/crud/profiles.dart';
import 'package:otpand/objects/profile.dart';
import 'package:otpand/pages/profile.dart';

class ProfilesPage extends StatefulWidget {
  const ProfilesPage({super.key});

  @override
  State<ProfilesPage> createState() => _ProfilesPageState();
}

class _ProfilesPageState extends State<ProfilesPage> {
  late Future<List<Profile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  void _loadProfiles() {
    setState(() {
      _profilesFuture = ProfileDao.getAll();
    });
  }

  Future<void> _openProfile(Profile profile) async {
    final updatedProfile = await Navigator.of(context).push<Profile>(
      MaterialPageRoute(builder: (context) => ProfilePage(profile: profile)),
    );
    if (updatedProfile != null) {
      _loadProfiles();
    }
  }

  Future<void> _addProfile() async {
    final newProfile = await ProfileDao.newProfile();
    _loadProfiles();
    _openProfile(newProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Profile',
            onPressed: _addProfile,
          ),
        ],
      ),
      body: FutureBuilder<List<Profile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final profiles = snapshot.data ?? [];
          if (profiles.isEmpty) {
            return const Center(child: Text('No profiles found.'));
          }
          return ListView.separated(
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: profile.color,
                  child: Text(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(profile.name),
                onTap: () => _openProfile(profile),
              );
            },
          );
        },
      ),
    );
  }
}
