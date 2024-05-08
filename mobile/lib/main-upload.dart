import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class FileUploader extends StatelessWidget {
  final File file;
  final String uploadUrl;

  const FileUploader({required this.file, required this.uploadUrl});

  Future<void> _uploadFile() async {
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    request.files.add(await http.MultipartFile.fromPath('audio', file.path));

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        print('File uploaded successfully');
        var responseBody = await response.stream.bytesToString();
        print('Response from server: $responseBody');
      } else {
        print('File upload failed');
      }
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _uploadFile,
      child: Text('Upload File'),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text('File Uploader'),
      ),
      body: Center(
        child: FileUploader(
          file: File('assets/audio_sample.wav'),
          uploadUrl: 'http://127.0.0.1:8000/predict/', // แก้ URL ตามต้องการ
        ),
      ),
    ),
  ));
}
