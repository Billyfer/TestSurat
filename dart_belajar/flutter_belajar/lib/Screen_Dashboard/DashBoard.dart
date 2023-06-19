import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'home.dart';
import 'input_surat.dart';
import 'data_surat.dart';
import 'admin_panel/admin_panel.dart';
import 'admin_panel/admin_panel2.dart';
import 'admin_panel/admin_panel3.dart';
import 'Screen_Login/Login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Surat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirebaseAuth.instance.currentUser == null ? LoginPage() : DashboardPage(), // Tambahkan pengecekan user saat ini
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;
  bool isAdmin = false;
  bool showAdminPanelMenu = false;

  void selectMenu(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void toggleAdminPanelMenu() {
    setState(() {
      showAdminPanelMenu = !showAdminPanelMenu;
    });
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  void initState() {
    super.initState();
    checkAdminStatus();
  }

  void checkAdminStatus() async {
    String userUID = FirebaseAuth.instance.currentUser!.uid;
    DatabaseReference adminRef = FirebaseDatabase.instance.ref().child('admin').child(userUID);
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(userUID);

    DataSnapshot adminSnapshot = await adminRef.get();
    if (adminSnapshot.exists) {
      setState(() {
        isAdmin = true;
      });
    } else {
      DataSnapshot userSnapshot = await userRef.get();
      Map<dynamic, dynamic>? userData = userSnapshot.value as Map<dynamic, dynamic>?;
      if (userData != null && userData['role'] == 'admin') {
        setState(() {
          isAdmin = true;
        });
      } else {
        setState(() {
          isAdmin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PT.ONI Palembang',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton( // Tambahkan ikon logout
          icon: Icon(Icons.logout),
          onPressed: logout,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue,
              Colors.purple,
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey[200],
                child: ListView(
                  children: [
                    DashboardMenuItem(
                      icon: Icons.home,
                      title: 'Home',
                      index: 0,
                      selectedIndex: selectedIndex,
                      onTap: selectMenu,
                    ),
                    DashboardMenuItem(
                      icon: Icons.add,
                      title: 'Input Surat',
                      index: 1,
                      selectedIndex: selectedIndex,
                      onTap: selectMenu,
                    ),
                    DashboardMenuItem(
                      icon: Icons.list,
                      title: 'Data Surat',
                      index: 2,
                      selectedIndex: selectedIndex,
                      onTap: selectMenu,
                    ),
                    if (isAdmin)
                      ExpansionPanelList(
                        expandedHeaderPadding: EdgeInsets.zero,
                        elevation: 1,
                        animationDuration: Duration(milliseconds: 500),
                        children: [
                          ExpansionPanel(
                            headerBuilder: (BuildContext context, bool isExpanded) {
                              return Container(
                                color: Colors.grey[300],
                                child: ListTile(
                                  leading: Icon(Icons.dashboard),
                                  title: Text('Admin Panel'),
                                ),
                              );
                            },
                            body: Column(
                              children: [
                                DashboardChildMenuItem(
                                  icon: Icons.person_add,
                                  title: 'Register User',
                                  index: 4,
                                  selectedIndex: selectedIndex,
                                  onTap: selectMenu,
                                ),
                                DashboardChildMenuItem(
                                  icon: Icons.supervised_user_circle,
                                  title: 'User Data',
                                  index: 5,
                                  selectedIndex: selectedIndex,
                                  onTap: selectMenu,
                                ),
                                DashboardChildMenuItem(
                                  icon: Icons.history,
                                  title: 'Activity User',
                                  index: 6,
                                  selectedIndex: selectedIndex,
                                  onTap: selectMenu,
                                ),
                              ],
                            ),
                            isExpanded: showAdminPanelMenu,
                          ),
                        ],
                        expansionCallback: (int panelIndex, bool isExpanded) {
                          toggleAdminPanelMenu();
                        },
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 8,
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: getSelectedPage(selectedIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getSelectedPage(int index) {
    switch (index) {
      case 0:
        return HomePage();
      case 1:
        return InputSuratPage();
      case 2:
        return DataSuratPage();
      case 4:
        return RegisterUserPage();
      case 5:
        return UserDataPage();
      case 6:
        return ActivityUserPage();
      default:
        return Container();
    }
  }
}

class DashboardMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  DashboardMenuItem({
    required this.icon,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: index == selectedIndex,
      onTap: () {
        onTap(index);
      },
    );
  }
}

class DashboardChildMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  DashboardChildMenuItem({
    required this.icon,
    required this.title,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: index == selectedIndex,
      onTap: () {
        onTap(index);
      },
    );
  }
}