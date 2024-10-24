import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'wave_animation.dart';

class RecordAndUpload extends StatefulWidget {
  const RecordAndUpload({Key? key}) : super(key: key);

  @override
  _RecordAndUploadState createState() => _RecordAndUploadState();
}

class _RecordAndUploadState extends State<RecordAndUpload> {
  File? _image;
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  final SpeechToText _speechToText = SpeechToText();
  String _wordsSpoken = "";
  String _answer="";
  final FlutterTts flutterTts = FlutterTts();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
    initCamera();
  }

  Future<void> initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _cameraController.initialize();
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _openCamera();
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
      if (!_speechToText.isListening) {
        _stopListening();
      }
    });
  }
  void _speak(String message) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.5);
    await flutterTts.speak(message);
  }

  Future<void> _openCamera() async {
    await _initializeControllerFuture;

    try {
      final image = await _cameraController.takePicture();
      setState(() {
        _image = File(image.path);
      });
      _uploadImageAndQuestion();
    } catch (e) {
    }
  }

  Future<void> _uploadImageAndQuestion() async {
    if (_image == null || _wordsSpoken.isEmpty) {
      return;
    }

    await _uploadQuestion();
    await _uploadImage();
  }

  Future<void> _uploadQuestion() async {
    try {
      var uri = Uri.parse('http://192.168.1.4:5001/upload_text');//Uri.parse('http://192.168.29.9:5001/upload_text');
      var request = http.MultipartRequest('POST', uri)
        ..fields['text'] = _wordsSpoken;

      var response = await request.send();

      if (response.statusCode == 201) {

      } else {

      }
    } catch (e) {

    }
  }

  Future<void> _uploadImage() async {
    try {
      var uri = Uri.parse('http://192.168.1.4:5001/upload_image');//Uri.parse('http://192.168.29.9:5001/upload_image');
      var request = http.MultipartRequest('POST', uri)
        ..fields['text'] = _wordsSpoken;

      var file = await http.MultipartFile.fromPath(
        'file',
        _image!.path,
        filename: _image!.path.split('/').last,
      );
      request.files.add(file);

      var response = await request.send();

      if (response.statusCode == 201) {
        var responseBody = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseBody);
        setState(() {
          _answer = jsonResponse['answer'];
          _wordsSpoken = _answer;
        });
        _speak(_answer);
      } else {
      }
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          Center(
            child: Container(
              width: 320.0,
              height: 460.0,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2.0),
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: _image != null
                    ? Image.file(
                  _image!,
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  'images/sphere.jpg.avif',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _wordsSpoken.isNotEmpty
                  ? SizedBox(
                height: 20, // Set to half of the desired height
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      _wordsSpoken,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
                  : SizedBox(height: 5),
            ),
          ),
          // ElevatedButton(
          //   onPressed: _uploadImageAndQuestion,
          //   child: const Text('Upload Image and Question'),
          // ),
          Visibility(
            visible: _speechToText.isListening,
            child: Container(
              height: 200.0, // Example container height
              child: VoiceWaveAnimation(
                bars: [
                  BarParams(index: 0, heightMultiplier: 2.0, spacing: 10.0),
                  BarParams(index: 1, heightMultiplier: 3.0, spacing: 10.0),
                  BarParams(index: 2, heightMultiplier: 4.0, spacing: 15.0),
                  BarParams(index: 3, heightMultiplier: 3.0, spacing: 10.0),
                  BarParams(index: 4, heightMultiplier: 2.0, spacing: 10.0),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 60,
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 200.0,
        height: 100.0,
        child: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: _speechToText.isListening ? _stopListening : _startListening,
          tooltip: 'Listen',
          child: Icon(
            _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
            color: Colors.white,
            size: 45.0,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}


class SunsetClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height); // Start at bottom-left
    path.lineTo(size.width * 0.25, size.height * 0.75);// Curve to the left
    path.lineTo(size.width * 0.75, size.height * 0.75); // Curve to the right
    path.lineTo(size.width, size.height); // End at bottom-right
    path.lineTo(size.width, 0); // Top-right corner
    path.lineTo(0, 0); // Top-left corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}