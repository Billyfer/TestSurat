import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _username = '';
  bool _isAdmin = false;
  List<Map<dynamic, dynamic>> _suratList = [];
  List<Map<dynamic, dynamic>> _notifikasiList = [];
  List<Map<dynamic, dynamic>> _kadaluwarsaList = [];
  DateTime? _selectedDate; // Tambahkan variabel untuk menampung tanggal yang dipilih

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _loadSuratList();
    _loadNotifikasiList();
    _listenNotifikasiRemoved();
  }

  void _checkUserStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String userUID = currentUser.uid;
      DatabaseReference adminRef =
          FirebaseDatabase.instance.ref().child('admin').child(userUID);
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref().child('users').child(userUID);

      DataSnapshot adminSnapshot = await adminRef.get();
      DataSnapshot userSnapshot = await userRef.get();

      setState(() {
        if (adminSnapshot.value != null) {
          _isAdmin = true;
          _username = adminSnapshot.child('name').value?.toString() ?? '';
        } else if (userSnapshot.value != null) {
          _isAdmin = false;
          _username = userSnapshot.child('name').value?.toString() ?? '';
        }
      });
    }
  }

  void _loadSuratList() {
    DatabaseReference suratRef = FirebaseDatabase.instance.ref().child('surat');

    suratRef.onChildAdded.listen((event) {
      setState(() {
        final surat = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        _suratList.add(surat);

        // Hitung selisih tanggal
        final currentDate = DateTime.now();
        final suratDate = DateTime.parse(surat['tanggal_surat'] ?? '');
        final difference = suratDate.difference(currentDate).inDays;

        // Tambahkan surat yang telah kadaluwarsa ke dalam list kadaluwarsa
        if (difference > 30 || difference < 0) {
          _kadaluwarsaList.add(surat);
        }
      });
    });
  }


  void _loadNotifikasiList() {
  DatabaseReference notifikasiRef = FirebaseDatabase.instance.ref().child('notifikasi_uid');

  notifikasiRef.onChildAdded.listen((event) {
    setState(() {
      final notifikasi = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      final notifikasiId = notifikasi['Notifikasi_id'];
      final isDeleted = notifikasi['isDeleted'] == true;

      if (!isDeleted) {
        _notifikasiList.add(notifikasi);
      } else {
        // Hapus notifikasi dari daftar jika sudah dihapus
        _notifikasiList.removeWhere((notifikasi) => notifikasi['Notifikasi_id'] == notifikasiId);
      }
    });
  });
}


   void _listenNotifikasiRemoved() {
    DatabaseReference notifikasiRef =
        FirebaseDatabase.instance.ref().child('notifikasi_uid');

    notifikasiRef.onChildRemoved.listen((event) {
      setState(() {
        final notifikasiId = event.snapshot.key;
        if (_notifikasiList.any((notifikasi) => notifikasi['Notifikasi_id'] == notifikasiId)) {
          _notifikasiList.removeWhere(
              (notifikasi) => notifikasi['Notifikasi_id'] == notifikasiId);
        }
      });
    });
  }


  Future<void> _showNotification(String suratName) async {
    if (html.Notification.supported) {
      await html.Notification.requestPermission();
      html.Notification(suratName, body: 'Surat akan kadaluwarsa');
    }
  }

  void _extendSurat(Map<dynamic, dynamic> surat) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Perpanjang Surat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pilih tanggal baru untuk memperpanjang surat:'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate; // Tampung tanggal yang dipilih
                    });
                  }
                },
                child: Text('Pilih Tanggal'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                if (_selectedDate != null) {
                  // Simpan perubahan tanggal_surat ke database
                  DatabaseReference suratRef = FirebaseDatabase.instance
                      .reference()
                      .child('surat')
                      .child(surat['key']);
                  suratRef.update({'tanggal_surat': _selectedDate!.toIso8601String()}).then((_) {
                    // Update langsung dalam tampilan setelah perubahan berhasil disimpan
                    setState(() {
                      if (mounted) {
                        surat['tanggal_surat'] = _selectedDate!.toIso8601String();
                      }
                    });
                  });

                  // Buat log notifikasi
                  DatabaseReference logRef = FirebaseDatabase.instance
                      .ref()
                      .child('notifikasi_uid')
                      .push(); // Membuat entri baru dengan kunci acak
                  String notifikasiId = logRef.key ?? '';
                  logRef.set({
                    'nama_surat': surat['nama_surat'],
                    'nomor_surat': surat['nomor_surat'],
                    'tanggal_surat_pembaruan': _selectedDate!.toIso8601String(),
                    'nama_user': _username,
                    'Notifikasi_id': notifikasiId,
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showNotifikasiLog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log Notifikasi'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: _notifikasiList.length,
              itemBuilder: (context, index) {
                final notifikasi = _notifikasiList[index];
                final namaSurat = notifikasi['nama_surat'] ?? '';
                final nomorSurat = notifikasi['nomor_surat'] ?? '';
                final tanggalSuratPembaruan = notifikasi['tanggal_surat_pembaruan'] ?? '';
                final namaUser = notifikasi['nama_user'] ?? '';
                final notifikasiId = notifikasi['Notifikasi_id'] ?? '';
                final isDeleted = notifikasi['isDeleted'] == true;

                if (isDeleted) {
                  _notifikasiList.removeWhere((notifikasi) => notifikasi['Notifikasi_id'] == notifikasiId);
                  return SizedBox.shrink(); // Menyembunyikan notifikasi yang telah dihapus
                }

                return AnimatedCrossFade(
                  firstChild: Card(
                    child: ListTile(
                      title: Text(namaSurat),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nomor Surat: $nomorSurat'),
                          Text('Tanggal Surat Pembaruan: $tanggalSuratPembaruan'),
                          Text('Nama User: $namaUser'),
                        ],
                      ),
                      trailing: _isAdmin
                          ? IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteNotifikasi(notifikasiId);
                              },
                            )
                          : null,
                    ),
                  ),
                  secondChild: SizedBox.shrink(),
                  crossFadeState:
                      notifikasi['isDeleted'] == true ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: Duration(milliseconds: 300),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Tutup'),
            ),
          ],
        );
      },
    ).then((_) {
      _notifikasiList.removeWhere((notifikasi) => notifikasi['isDeleted'] == true);
    });
  }


  void _deleteNotifikasi(String notifikasiId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Anda yakin ingin menghapus notifikasi ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog konfirmasi
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                // Hapus notifikasi dari database dan daftar notifikasi
                DatabaseReference notifikasiRef = FirebaseDatabase.instance
                    .ref()
                    .child('notifikasi_uid')
                    .child(notifikasiId);
                notifikasiRef.remove().then((_) {
                  setState(() {
                    _notifikasiList.removeWhere((notifikasi) => notifikasi['Notifikasi_id'] == notifikasiId);
                  });
                }).catchError((error) {
                  print('Failed to delete notification: $error');
                });

                Navigator.of(context).pop(); // Tutup dialog konfirmasi
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _confirmSuratKadaluwarsa(Map<dynamic, dynamic> surat) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Surat Kadaluwarsa'),
          content: Text('Apakah Anda ingin menambahkan surat ini ke dalam Surat Kadaluwarsa?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog konfirmasi
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                // Tambahkan surat ke database SuratKadaluwarsa
                DatabaseReference suratKadaluwarsaRef = FirebaseDatabase.instance
                    .reference()
                    .child('SuratKadaluwarsa')
                    .push(); // Membuat entri baru dengan kunci acak
                String suratKadaluwarsaId = suratKadaluwarsaRef.key ?? '';

                // Tambahkan key ke dalam data surat
                surat['SuratKadaluwarsa_uid'] = suratKadaluwarsaId;

                suratKadaluwarsaRef.set(surat);

                // Hapus surat dari database Surat
                DatabaseReference suratRef =
                    FirebaseDatabase.instance.ref().child('surat').child(surat['key']);
                suratRef.remove().then((_) {
                  // Hapus surat dari daftar surat
                  setState(() {
                    _suratList.removeWhere((s) => s['key'] == surat['key']);
                  });
                }).catchError((error) {
                  print('Failed to delete surat: $error');
                });

                Navigator.of(context).pop(); // Tutup dialog konfirmasi
              },
              child: Text('Konfirmasi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Selamat datang, ${_username}',
          style: TextStyle(fontSize: 24),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Surat:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _suratList.length,
                itemBuilder: (context, index) {
                  final surat = _suratList[index];
                  final suratName = surat['nama_surat'] ?? '';
                  final tanggalSurat = surat['tanggal_surat'] ?? '';

                  // Hitung selisih tanggal
                  final currentDate = DateTime.now();
                  final suratDate = DateTime.parse(tanggalSurat);
                  final difference = suratDate.difference(currentDate).inDays;

                  // Periksa jika selisih kurang dari 7 hari dan hanya pada tampilan web
                  if (difference <= 7 && difference >= 0 && html.window.navigator.userAgent.contains('Chrome')) {
                    _showNotification(suratName);
                  }

                  // Filter surat yang kadaluwarsa dalam 1 bulan (30 hari)
                  if (difference > 30 || difference < 0) {
                    return SizedBox.shrink(); // Menyembunyikan widget jika surat masih memiliki waktu 1 bulan lebih atau sudah kadaluwarsa
                  }

                  return Card(
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            suratName,
                            style: TextStyle(
                              color: difference <= 7 ? Colors.red : Colors.black,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.date_range),
                            onPressed: () {
                              _extendSurat(surat);
                            },
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nomor Surat: ${surat['nomor_surat'] ?? ''}'),
                          Text('Tanggal Surat: $tanggalSurat'),
                          if (difference <= 7)
                            Text(
                              'Waktu Tersisa: ${difference.abs()} hari',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Text(
              'Data Surat Kadaluwarsa:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _kadaluwarsaList.length,
                itemBuilder: (context, index) {
                  final surat = _kadaluwarsaList[index];
                  final suratName = surat['nama_surat'] ?? '';
                  final tanggalSurat = surat['tanggal_surat'] ?? '';

                  return Card(
                    child: ListTile(
                      title: Text(
                        suratName,
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nomor Surat: ${surat['nomor_surat'] ?? ''}'),
                          Text('Tanggal Surat: $tanggalSurat'),
                          Text(
                            'Surat telah kadaluwarsa',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () {
                          _confirmSuratKadaluwarsa(surat);
                        },
                      ),
                    ),
                  );
                },
              )
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showNotifikasiLog,
              child: Text('Log Notifikasi'),
            ),
          ],
        ),
      ),
    );
  }
}