import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EditSuratPage extends StatefulWidget {
  final Map<dynamic, dynamic> surat;

  EditSuratPage({required this.surat});

  @override
  _EditSuratPageState createState() => _EditSuratPageState();
}

class _EditSuratPageState extends State<EditSuratPage> {
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
    Firebase.initializeApp(); // Initialize Firebase
    namaSuratController = TextEditingController(text: widget.surat['nama_surat']);
    nomorSuratController = TextEditingController(text: widget.surat['nomor_surat']);
    jenisSuratController = TextEditingController(text: widget.surat['jenis_surat']);
    selectedDate = DateTime.parse(widget.surat['tanggal_surat']);
    _fileName = widget.surat['file_name'];
    _fileType = widget.surat['file_type'];
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

      // Menghapus file lama dari Firebase Storage
      if (widget.surat['file_name'] != null) {
        final oldStorageRef = firebase_storage.FirebaseStorage.instance.ref().child('files/${widget.surat['file_name']}');
        try {
          await oldStorageRef.delete();
        } catch (e) {
          print('Gagal menghapus file lama dari Firebase Storage: $e');
        }
      }
    }
  }

    void _deleteFile() {
    setState(() {
      _selectedFile = null;
      _fileName = widget.surat['file_name'];
      _fileType = widget.surat['file_type'];
    });
  }

  void _updateSurat() async {
    final suratRef = FirebaseDatabase.instance.reference().child('surat').child(widget.surat['key']);

    await suratRef.update({
      'nama_surat': namaSuratController.text,
      'nomor_surat': nomorSuratController.text,
      'jenis_surat': jenisSuratController.text,
      'tanggal_surat': selectedDate.toString(),
    });

    if (_selectedFile != null) {
      final fileBytes = _selectedFile!.bytes;
      final fileName = _selectedFile!.name;
      final storageRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('files/$fileName');
      final uploadTask = storageRef.putData(fileBytes!);

      await uploadTask.whenComplete(() {});

      if (uploadTask.snapshot.state == firebase_storage.TaskState.success) {
        final downloadURL = await storageRef.getDownloadURL();

        await suratRef.update({
          'file_name': fileName,
          'file_type': _selectedFile?.extension,
          'download_url': downloadURL,
        });

        // Menghapus file lama dari Firebase Storage
        if (widget.surat['file_name'] != null && widget.surat['file_name'] != fileName) {
          final oldStorageRef = firebase_storage.FirebaseStorage.instance.ref().child('files/${widget.surat['file_name']}');
          try {
            await oldStorageRef.delete();
          } catch (e) {
            print('Gagal menghapus file lama dari Firebase Storage: $e');
          }
        }
      }
    }

    Fluttertoast.showToast(
      msg: 'Surat berhasil diperbarui',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    final updatedSurat = {
      ...widget.surat,
      'nama_surat': namaSuratController.text,
      'nomor_surat': nomorSuratController.text,
      'jenis_surat': jenisSuratController.text,
      'tanggal_surat': selectedDate.toString(),
      'file_name': _fileName,
      'file_type': _fileType,
      'download_url': widget.surat['download_url'],
    };

    Navigator.pop(context, updatedSurat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Surat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: namaSuratController,
              decoration: InputDecoration(labelText: 'Nama Surat'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: nomorSuratController,
              decoration: InputDecoration(labelText: 'Nomor Surat'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: jenisSuratController,
              decoration: InputDecoration(labelText: 'Jenis Surat'),
            ),
            SizedBox(height: 16.0),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                    text: selectedDate.toString().split(' ')[0],
                  ),
                  decoration: InputDecoration(
                    labelText: 'Tanggal Surat',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Choose File'),
            ),
            SizedBox(height: 16.0),
            if (_selectedFile != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('File Name: $_fileName'),
                            Text('File Type: $_fileType'),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _deleteFile,
                        icon: Icon(Icons.delete),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _updateSurat,
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
