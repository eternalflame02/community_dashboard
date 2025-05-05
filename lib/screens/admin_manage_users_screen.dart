import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  List<AppUser> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/users'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _users = data.map((u) => AppUser.fromMap(u)).toList();
        });
      } else {
        setState(() { _error = 'Failed to fetch users'; });
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _changeRole(AppUser user, String newRole) async {
    final oldRole = user.role;
    setState(() {
      _users = _users.map((u) => u.id == user.id ? AppUser(
        id: u.id,
        firebaseId: u.firebaseId,
        email: u.email,
        displayName: u.displayName,
        photoURL: u.photoURL,
        role: newRole,
      ) : u).toList();
    });
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/users/${user.id}/role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': newRole}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update role');
      }
    } catch (e) {
      setState(() {
        _users = _users.map((u) => u.id == user.id ? AppUser(
          id: u.id,
          firebaseId: u.firebaseId,
          email: u.email,
          displayName: u.displayName,
          photoURL: u.photoURL,
          role: oldRole,
        ) : u).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: user.photoURL != null
                            ? CircleAvatar(backgroundImage: NetworkImage(user.photoURL!))
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user.displayName ?? user.email),
                        subtitle: Text(user.email),
                        trailing: DropdownButton<String>(
                          value: user.role,
                          items: const [
                            DropdownMenuItem(value: 'user', child: Text('User')),
                            DropdownMenuItem(value: 'officer', child: Text('Officer')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          ],
                          onChanged: (val) {
                            if (val != null && val != user.role) {
                              _changeRole(user, val);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
