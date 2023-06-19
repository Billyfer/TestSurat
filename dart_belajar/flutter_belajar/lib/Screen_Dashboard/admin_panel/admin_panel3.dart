import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ActivityUserPage extends StatefulWidget {
  @override
  _ActivityUserPageState createState() => _ActivityUserPageState();
}

class _ActivityUserPageState extends State<ActivityUserPage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('surat');
  final DatabaseReference _databaseSuratKadaluwarsa =
      FirebaseDatabase.instance.ref().child('SuratKadaluwarsa');
  List<Map<dynamic, dynamic>> _suratList = [];
  List<Map<dynamic, dynamic>> _suratKadaluwarsaList = [];

  @override
  void initState() {
    super.initState();
    _databaseReference.onChildAdded.listen((event) {
      setState(() {
        DataSnapshot snapshot = event.snapshot;
        _suratList.add(Map<dynamic, dynamic>.from(snapshot.value as Map));
      });
    });

    _databaseSuratKadaluwarsa.onChildAdded.listen((event) {
      setState(() {
        DataSnapshot snapshot = event.snapshot;
        _suratKadaluwarsaList
            .add(Map<dynamic, dynamic>.from(snapshot.value as Map));
      });
    });

    _databaseSuratKadaluwarsa.onChildRemoved.listen((event) {
      setState(() {
        DataSnapshot snapshot = event.snapshot;
        var surat =
            Map<dynamic, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        _suratKadaluwarsaList.removeWhere((item) => item['key'] == surat['key']);
      });
    });
  }

  void _hapusSuratKadaluwarsa(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus Surat Kadaluwarsa'),
          content: Text('Apakah Anda yakin ingin menghapus surat kadaluwarsa ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog konfirmasi
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final surat = _suratKadaluwarsaList[index];
                final suratKey = surat['SuratKadaluwarsa_uid'];
                final downloadURL = surat['download_url'];

                // Hapus file dari Firebase Storage
                firebase_storage.FirebaseStorage.instance
                    .refFromURL(downloadURL)
                    .delete()
                    .then((_) {
                  // Hapus dari database SuratKadaluwarsa
                  _databaseSuratKadaluwarsa.child(suratKey).remove().then((_) {
                    if (mounted) {
                      setState(() {
                        _suratKadaluwarsaList.removeAt(index);
                      });
                    }
                  }).catchError((error) {
                    print('Gagal menghapus surat kadaluwarsa: $error');
                  });
                }).catchError((error) {
                  print('Gagal menghapus file dari Firebase Storage: $error');
                });

                Navigator.of(context).pop(); // Tutup dialog konfirmasi
              },
              child: Text('Hapus'),
            ),
          ],
        );
      },
    ).then((value) {
      if (mounted) {
        setState(() {});
      }
    });
  }





  void _viewFile(String? downloadURL) {
    if (downloadURL != null) {
      launch(downloadURL);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Activity User'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Surat Kadaluwarsa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _suratKadaluwarsaList.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suratKadaluwarsaList.length,
                    itemBuilder: (context, index) {
                      var surat = _suratKadaluwarsaList[index];

                      return Card(
                        child: ListTile(
                          title: Text(surat['nama_surat']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nomor Surat: ${surat['nomor_surat']}'),
                              Text('File Name: ${surat['file_name']}'),
                              Text(
                                'Tanggal Surat Kadaluwarsa: ${surat['tanggal_surat']}',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () =>
                                _hapusSuratKadaluwarsa(index), // Memanggil fungsi dengan parameter index
                          ),
                          // Tombol Download
                          leading: IconButton(
                            icon: Icon(Icons.file_download),
                            onPressed: () =>
                                _viewFile(surat['download_url']),
                          ),
                        ),
                      );
                    },
                  )
                : Text('Tidak ada surat kadaluwarsa.'),
            SizedBox(height: 16),
            Text(
              'Semua Surat',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _suratList.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suratList.length,
                    itemBuilder: (context, index) {
                      var surat = _suratList[index];

                      return Card(
                        child: ListTile(
                          title: Text(surat['nama_surat']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nomor Surat: ${surat['nomor_surat']}'),
                              Text('Jenis Surat: ${surat['jenis_surat']}'),
                              Text('Tanggal Surat: ${surat['tanggal_surat']}'),
                              Text('File Name: ${surat['file_name']}'),
                              Text('Nama Yang Menginput: ${surat['username']}')
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Text('Tidak ada surat.'),
          ],
        ),
      ),
    );
  }
}
