import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'EditSurat.dart';

class DataSuratPage extends StatefulWidget {
  @override
  _DataSuratPageState createState() => _DataSuratPageState();
}

class _DataSuratPageState extends State<DataSuratPage> {
  late DatabaseReference _databaseReference;
  List<Map<dynamic, dynamic>> _suratList = [];
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _databaseReference = FirebaseDatabase.instance.ref().child('surat');

    _databaseReference.onChildAdded.listen((event) {
      if (_searchQuery == null || _searchQuery!.isEmpty) {
        setState(() {
          _suratList.add(Map<dynamic, dynamic>.from(event.snapshot.value as Map));
        });
      } else {
        final surat = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        if (surat['nomor_surat'].contains(_searchQuery!)) {
          setState(() {
            _suratList.add(surat);
          });
        }
      }
    });
  }

  void _editSurat(int index) async {
    final surat = _suratList[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSuratPage(surat: surat),
      ),
    );
    if (result != null) {
      setState(() {
        _suratList[index] = result;
      });
    }
  }

  void _deleteSurat(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Apakah Anda yakin ingin menghapus surat ini?'),
          actions: [
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () {
                // Hapus surat dari database
                final surat = _suratList[index];
                final suratRef = _databaseReference.child(surat['key']);
                suratRef.remove().then((_) {
                  // Hapus file dari Firebase Storage
                  final fileName = surat['file_name'];
                  final storageRef = firebase_storage.FirebaseStorage.instance.ref().child('files/$fileName');
                  storageRef.delete().then((_) {
                    setState(() {
                      _suratList.removeAt(index);
                    });
                    Navigator.of(context).pop(); // Tutup dialog konfirmasi
                  }).catchError((error) {
                    // Terjadi kesalahan saat menghapus file
                    print('Failed to delete file: $error');
                  });
                }).catchError((error) {
                  // Terjadi kesalahan saat menghapus surat dari database
                  print('Failed to delete surat: $error');
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _viewFile(String? downloadURL) {
    if (downloadURL != null) {
      launch(downloadURL);
    }
  }

  void _searchSurat(String query) {
    setState(() {
      _searchQuery = query;
      _suratList.clear();

      if (_searchQuery == null || _searchQuery!.isEmpty) {
        // Tampilkan semua surat jika query kosong
        _databaseReference.get().then((DataSnapshot snapshot) {
          if (snapshot.value != null) {
            Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
            values.forEach((key, value) {
              setState(() {
                _suratList.add(Map<dynamic, dynamic>.from(value));
              });
            });
          }
        }).catchError((error) {
          print('Failed to fetch surat: $error');
        });
      } else {
        // Cari surat dengan nomor surat yang cocok dengan query
        _databaseReference.get().then((DataSnapshot snapshot) {
          if (snapshot.value != null) {
            Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
            values.forEach((key, value) {
              final surat = Map<dynamic, dynamic>.from(value);
              if (surat['nomor_surat'].contains(_searchQuery!)) {
                setState(() {
                  _suratList.add(surat);
                });
              }
            });
          }
        }).catchError((error) {
          print('Failed to fetch surat: $error');
        });
      }
    });
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Data Surat'),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Cari Nomor Surat',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchSurat,
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: _suratList.isNotEmpty
                  ? ListView.builder(
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
                                Text('File Name: ${surat['file_name']}')
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editSurat(index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteSurat(index),
                                ),
                                IconButton(
                                  icon: Icon(Icons.visibility),
                                  onPressed: () => _viewFile(surat['download_url']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text('Tidak ada data surat.'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
