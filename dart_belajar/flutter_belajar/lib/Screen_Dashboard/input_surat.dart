import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InputSuratPage extends StatefulWidget {
  @override
  _InputSuratPageState createState() => _InputSuratPageState();
}

class _InputSuratPageState extends State<InputSuratPage> {
  late String _username;
  late TextEditingController namaSuratController;
  late TextEditingController nomorSuratController;
  late TextEditingController jenisSuratController;
  late DateTime selectedDate;

  String? _fileName;
  String? _fileType;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(); // Inisialisasi Firebase
    namaSuratController = TextEditingController();
    nomorSuratController = TextEditingController();
    jenisSuratController = TextEditingController();
    selectedDate = DateTime.now();
    _checkUserStatus(); // Pemanggilan _checkUserStatus()
  }

  @override
  void dispose() {
    namaSuratController.dispose();
    nomorSuratController.dispose();
    jenisSuratController.dispose();
    super.dispose();
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _fileName = _selectedFile?.name;
        _fileType = _selectedFile?.extension;
      });
    }
  }

  void _deleteFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileType = null;
    });
  }

  Future<void> _uploadFile() async {
    if (_selectedFile != null) {
      final fileBytes = _selectedFile!.bytes;
      final fileName = _selectedFile!.name;
      final storageRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('files/$fileName');
      final uploadTask = storageRef.putData(fileBytes!);

      await uploadTask.whenComplete(() {
        setState(() {
          // File upload completed
        });
      });

      if (uploadTask.snapshot.state == firebase_storage.TaskState.success) {
        final downloadURL = await storageRef.getDownloadURL();

        // Simpan URL download ke Realtime Database atau lakukan operasi lain yang diperlukan
        final database = FirebaseDatabase.instance.ref();
        final newSuratRef = database.child('surat').push();

        final newSuratKey = newSuratRef.key; // Dapatkan kunci unik untuk entri surat baru

        newSuratRef.set({
          'key': newSuratKey, // Simpan kunci unik ke dalam entri surat
          'nama_surat': namaSuratController.text,
          'nomor_surat': nomorSuratController.text,
          'jenis_surat': jenisSuratController.text,
          'tanggal_surat': selectedDate.toString(),
          'file_name': _fileName,
          'file_type': _fileType,
          'download_url': downloadURL,
          'username': _username, // Tambahkan _username ke database
        }).then((_) {
          // Berhasil menyimpan data
          Fluttertoast.showToast(
            msg: 'Surat berhasil ditambahkan',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );

          // Menghapus input dan file yang dipilih
          setState(() {
            namaSuratController.clear();
            nomorSuratController.clear();
            jenisSuratController.clear();
            _selectedFile = null;
            _fileName = null;
            _fileType = null;
          });
        }).catchError((error) {
          // Terjadi kesalahan saat menyimpan data
          print('Failed to save data: $error');
        });
      }
    }
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
          _username = adminSnapshot.child('name').value?.toString() ?? '';
        } else if (userSnapshot.value != null) {
          _username = userSnapshot.child('name').value?.toString() ?? '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Input Surat'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: namaSuratController,
                decoration: InputDecoration(
                  labelText: 'Nama Surat',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: nomorSuratController,
                decoration: InputDecoration(
                  labelText: 'Nomor Surat',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: jenisSuratController,
                decoration: InputDecoration(
                  labelText: 'Jenis Surat',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: Icon(Icons.calendar_today),
                label: Text('Pilih Tanggal Surat'),
              ),
              SizedBox(height: 8.0),
              Text(selectedDate.toString()),
              SizedBox(height: 16.0),
              _selectedFile != null
                  ? Column(
                      children: [
                        Text('File: $_fileName'),
                        SizedBox(height: 8.0),
                        ElevatedButton.icon(
                          onPressed: _deleteFile,
                          icon: Icon(Icons.delete),
                          label: Text('Hapus File'),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: Icon(Icons.attach_file),
                      label: Text('Pilih File'),
                    ),
              SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _uploadFile,
                icon: Icon(Icons.cloud_upload),
                label: Text('Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}