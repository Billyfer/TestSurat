import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EditAdminPage extends StatefulWidget {
  final Map<dynamic, dynamic> user;

  EditAdminPage({required this.user});

  @override
  _EditAdminPageState createState() => _EditAdminPageState();
}

class _EditAdminPageState extends State<EditAdminPage> {
  late TextEditingController emailController;
  late TextEditingController nameController;
  late TextEditingController passwordController;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.user['email']);
    nameController = TextEditingController(text: widget.user['name']);
    passwordController = TextEditingController(text: widget.user['password']);
    _passwordVisible = false;
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  void _updateAdmin() async {
  try {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Update email and display name
      await currentUser.updateEmail(emailController.text);
      await currentUser.updateDisplayName(nameController.text);

      if (passwordController.text.isNotEmpty) {
        // Update password
        await currentUser.updatePassword(passwordController.text);

        // Update the user data in the Realtime Database, including the new password
        DatabaseReference databaseRef =
            FirebaseDatabase.instance.reference();
        await databaseRef
            .child('users')
            .child(currentUser.uid)
            .update({
          'email': emailController.text,
          'name': nameController.text,
          'password': passwordController.text,
        });

        // Reset the password field
        passwordController.text = '';
      } else {
        // Update the user data in the Realtime Database without changing the password
        DatabaseReference databaseRef =
            FirebaseDatabase.instance.reference();
        await databaseRef
            .child('users')
            .child(currentUser.uid)
            .update({
          'email': emailController.text,
          'name': nameController.text,
        });
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text('Admin data updated successfully.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  } catch (error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('Failed to update admin data: $error'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Admin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updateAdmin,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
