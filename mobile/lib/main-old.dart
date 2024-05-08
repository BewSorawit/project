import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
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
  late String recordingTimeStamp;
  String _selectedType = '1';

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();
    _fileNameController = TextEditingController();
    _initAudioFilePath();
  }

  Future<void> _initAudioFilePath() async {
    final directory = await getExternalStorageDirectory();
    setState(() {
      // _audioFilePath = '${directory!.path}/Download/';
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

  void _startRecording() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
      status = await Permission.microphone.status;
      if (!status.isGranted) {
        if (kDebugMode) {
          print('ไม่ได้รับอนุญาตให้ใช้ไมค์');
        }
        return;
      }
    }

    await _initAudioFilePath();
    try {
      recordingTimeStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      await _recorder?.openRecorder();
      await _recorder?.startRecorder(
        toFile: '$_audioFilePath${recordingTimeStamp}_$_selectedType.wav',
        // toFile:
        //     '$_audioFilePath${DateFormat('yyyyMMdd_HHmm_').format(DateTime.now())}.wav',
        // toFile: '$_audioFilePath$timeStamp.wav',
        codec: Codec.pcm16WAV,
      );
      setState(() {
        _isRecording = true;
      });

      // เริ่มนับเวลาและหยุดการอัดเสียงหลังจากผ่านไป 20 วินาที
      _stopRecordingAfter20Seconds();
    } catch (e) {
      if (kDebugMode) {
        print('Error starting recording: $e');
      }
    }
  }

  void _stopRecordingAfter20Seconds() {
    Timer(const Duration(seconds: 5), () async {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() async {
    try {
      await _recorder?.stopRecorder();
      setState(() {
        _isRecording = false;
      });

      if (kDebugMode) {
        print('Recording time stamp: $recordingTimeStamp');
      }
      String fileName = '$recordingTimeStamp' + '_$_selectedType.wav';

      if (kDebugMode) {
        print(fileName);
      }
      String filePath =
          '$_audioFilePath$fileName'; // รวม _audioFilePath กับชื่อไฟล์
      var url = Uri.parse('http://192.168.9.47:3000/predict');
      var request = http.MultipartRequest('POST', url)
        ..files.add(http.MultipartFile.fromBytes(
            'audio', File(filePath).readAsBytesSync(),
            filename: fileName))
        ..fields['type'] = _selectedType; // เพิ่มฟิลด์ type ในข้อมูลที่ส่ง

      var response = await request.send();
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('File uploaded successfully');
        }
      } else {
        if (kDebugMode) {
          print('File upload failed');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping recording: $e');
      }
    }
  }

  void _playRecording() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
      status = await Permission.storage.status;
      if (!status.isGranted) {
        if (kDebugMode) {
          print('ไม่ได้รับอนุญาตให้เข้าถึงไฟล์เสียง');
        }
        return;
      }
    }

    try {
      await _player?.openPlayer();
      await _player?.startPlayer(
        // fromURI: '${_audioFilePath}_$now.wav',
        // fromURI: '${_audioFilePath}_${now.toString()}.wav',
        fromURI: '$_audioFilePath${recordingTimeStamp}_$_selectedType.wav',
        codec: Codec.pcm16WAV,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error playing recording: $e');
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
              height: 70, // กำหนดความสูง
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                items: <String>['1', '2', '3', '4', '5', '6']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: const InputDecoration(labelText: 'Type'),
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
            !_isRecording
                ? ElevatedButton(
                    onPressed: _playRecording,
                    child: const Text('Play Recording'),
                  )
                : Container(),
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
