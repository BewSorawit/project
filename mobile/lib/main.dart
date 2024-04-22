import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RecorderScreen(),
    );
  }
}

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  _RecorderScreenState createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  late String _audioFilePath;
  late TextEditingController _fileNameController;

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _initAudioFilePath();
    _fileNameController = TextEditingController();
  }

  Future<void> _initAudioFilePath() async {
    setState(() {
      _audioFilePath = '/storage/emulated/0/Download/';
    });
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _fileNameController.dispose();
    super.dispose();
  }

  // void _startRecording() async {
  //   try {
  //     await _recorder?.openRecorder();
  //     await _recorder?.startRecorder(
  //       toFile: 'path_to_your_audio_file.aac',
  //       codec: Codec.aacADTS,
  //     );
  //     setState(() {
  //       _isRecording = true;
  //     });
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error starting recording: $e');
  //     }
  //   }
  // }
  void _startRecording() async {
    // ตรวจสอบสถานะการอนุญาตการเข้าถึงไมค์
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      // ถ้ายังไม่ได้รับอนุญาต ขออนุญาตการเข้าถึงไมค์
      await Permission.microphone.request();
      // ตรวจสอบอีกครั้งหลังจากขออนุญาต
      status = await Permission.microphone.status;
      if (!status.isGranted) {
        // ถ้ายังไม่ได้รับอนุญาตให้ใช้ไมค์ แสดงข้อความแจ้งเตือน
        if (kDebugMode) {
          print('ไม่ได้รับอนุญาตให้ใช้ไมค์');
        }
        return;
      }
    }

    try {
      await _recorder?.openRecorder();
      await _recorder?.startRecorder(
        toFile: '$_audioFilePath${_fileNameController.text}.wav',
        codec: Codec.pcm16WAV,
      );
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error starting recording: $e');
      }
    }
  }

  void _stopRecording() async {
    try {
      await _recorder?.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      // Prepare to send the recorded audio file to the server
      String fileName = _fileNameController.text;
      String filePath = '$_audioFilePath$fileName.wav';
      var url = Uri.parse('http://192.168.9.38:3000/upload');

      var request = http.MultipartRequest('POST', url)
        ..files.add(await http.MultipartFile.fromPath('audio', filePath));

      var response = await request.send();
      if (response.statusCode == 200) {
        print('File uploaded successfully');
      } else {
        print('File upload failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping recording: $e');
      }
    }
  }

  // void _stopRecording() async {
  //   try {
  //     await _recorder?.stopRecorder();
  //     setState(() {
  //       _isRecording = false;
  //     });
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error stopping recording: $e');
  //     }
  //   }
  // }

  // void _playRecording() async {
  //   try {
  //     await _player?.openPlayer();
  //     await _player?.startPlayer(
  //       fromURI: 'path_to_your_audio_file.aac',
  //       codec: Codec.aacADTS,
  //     );
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Error playing recording: $e');
  //     }
  //   }
  // }
  void _playRecording() async {
    // ตรวจสอบสถานะการอนุญาตการเข้าถึงไฟล์เสียง
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // ถ้ายังไม่ได้รับอนุญาต ขออนุญาตการเข้าถึงไฟล์เสียง
      await Permission.storage.request();
      // ตรวจสอบอีกครั้งหลังจากขออนุญาต
      status = await Permission.storage.status;
      if (!status.isGranted) {
        // ถ้ายังไม่ได้รับอนุญาตให้เข้าถึงไฟล์เสียง แสดงข้อความแจ้งเตือน
        if (kDebugMode) {
          print('ไม่ได้รับอนุญาตให้เข้าถึงไฟล์เสียง');
        }
        return;
      }
    }

    try {
      await _player?.openPlayer();
      await _player?.startPlayer(
        fromURI: '$_audioFilePath${_fileNameController.text}.wav',
        codec: Codec.pcm16WAV,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error playing recording: $e');
      }
    }
  }

  void _stopPlaying() async {
    try {
      await _player?.stopPlayer();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping playback: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 220, // กำหนดความยาว
              height: 50, // กำหนดความสูง
              child: TextField(
                controller: _fileNameController,
                decoration: InputDecoration(
                  hintText: 'Enter file name',
                  labelText: 'File Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _isRecording
                ? const Text('Recording...')
                : ElevatedButton(
                    onPressed: _startRecording,
                    child: const Text('Start Recording'),
                  ),
            const SizedBox(height: 20),
            _isRecording
                ? ElevatedButton(
                    onPressed: _stopRecording,
                    child: const Text('Stop Recording'),
                  )
                : ElevatedButton(
                    onPressed: _playRecording,
                    child: const Text('Play Recording'),
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopPlaying,
              child: const Text('Stop Playback'),
            ),
            const SizedBox(height: 20),
            Text(
              _audioFilePath,
            ),
          ],
        ),
      ),
    );
  }
}
