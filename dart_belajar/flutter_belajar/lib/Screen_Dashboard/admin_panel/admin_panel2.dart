import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'EditAdmin.dart';

class UserDataPage extends StatefulWidget {
  @override
  _UserDataPageState createState() => _UserDataPageState();
}

class _UserDataPageState extends State<UserDataPage> {
  late DatabaseReference _userRef;
  List<Map<dynamic, dynamic>> _userList = [];
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _userRef = FirebaseDatabase.instance.ref().child('users');

    _userRef.onChildAdded.listen((event) {
      setState(() {
        _userList.add(Map<dynamic, dynamic>.from(event.snapshot.value as Map));
      });
    });
  }

  void _editUser(int index) {
    final user = _userList[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAdminPage(user: user),
      ),
    );
  }


  Future<void> _deleteUser(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                // Delete user from the database
                final user = _userList[index];
                final userRef = _userRef.child(user['user_uid']);
                await userRef.remove().then((_) async {
                  setState(() {
                    _userList.removeAt(index);
                  });

                  // Delete user from authentication
                  User? currentUser = _auth.currentUser;
                  if (currentUser != null) {
                    await currentUser.delete().then((_) {
                      print('User deleted from authentication.');
                    }).catchError((error) {
                      print('Failed to delete user from authentication: $error');
                    });
                  }

                  Navigator.of(context).pop(); // Close confirmation dialog
                }).catchError((error) {
                  // Error occurred while deleting user from the database
                  print('Failed to delete user: $error');
                });
              },
            ),
          ],
        );
      },
    );
  }

  bool _passwordVisible = false;

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Admin Panel'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: _userList.isNotEmpty
            ? ListView.builder(
                itemCount: _userList.length,
                itemBuilder: (context, index) {
                  var user = _userList[index];

                  return Card(
                    child: ListTile(
                      title: Text(user['email']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${user['name']}'),
                          TextFormField(
                            initialValue: user['password'],
                            readOnly: true,
                            obscureText: !_passwordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: _togglePasswordVisibility,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _editUser(index);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteUser(index);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text('No users found.'),
              ),
      ),
    );
  }
}
