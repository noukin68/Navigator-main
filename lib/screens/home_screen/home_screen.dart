import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../voice_assistant/voice_responces.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _assistantResponse = "";
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  YandexMapController? yandexMapController;
  PlacemarkMapObject? userPlacemark;

  @override
  void initState() {
    super.initState();
    _speechToText = SpeechToText();
    _flutterTts = FlutterTts();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _colorAnimation = ColorTween(
      begin: Color.fromRGBO(66, 56, 46, 1),
      end: Colors.red,
    ).animate(_animationController);
    _requestMicrophonePermission();
    Geolocator.requestPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      print("Разрешение на использование микрофона получено!");
    } else {
      print("Разрешение на использование микрофона не получено!");
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize(
        onError: (error) {},
      );

      if (available) {
        setState(() {
          _isListening = true;
          _assistantResponse = "Говорите...";
        });

        _startListening();
      }
    }
  }

  void _startListening() {
    _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
      localeId: "ru_RU",
    );
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await Future.delayed(const Duration(seconds: 1));
      _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      _speak(_assistantResponse);
    }
  }

  void _speak(String text) async {
    await _flutterTts.setVoice({
      "name": "ru-ru-x-rud-network",
      "locale": "ru-RU",
      "gender": "male",
    });
    await _flutterTts.speak(text);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    String command = result.recognizedWords;
    setState(() {
      _assistantResponse = VoiceResponses.getResponseForCommand(command);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(226, 192, 128, 1),
        title: const Text(
          'Карта',
          style: TextStyle(
            color: Color.fromRGBO(66, 56, 46, 1),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromRGBO(66, 56, 46, 1),
        ),
      ),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) {
              yandexMapController = controller;
              yandexMapController?.moveCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(
                    target: Point(
                      latitude: 53.97,
                      longitude: 38.33,
                    ),
                    zoom: 14.0,
                  ),
                ),
              );
            },
            mapObjects: [
              if (userPlacemark != null) userPlacemark!,
            ],
          ),
          Positioned(
            left: 16.0,
            bottom: 40.0,
            child: Container(
              width: 56.0,
              height: 56.0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromRGBO(226, 192, 128, 1),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  Position position = await Geolocator.getCurrentPosition();
                  setState(() {
                    userPlacemark = PlacemarkMapObject(
                      mapId: const MapObjectId('user_placemark'),
                      point: Point(
                        latitude: position.latitude,
                        longitude: position.longitude,
                      ),
                      opacity: 0.8,
                      icon: PlacemarkIcon.single(
                        PlacemarkIconStyle(
                          image: BitmapDescriptor.fromAssetImage(
                              'assets/images/location.png'),
                        ),
                      ),
                    );
                  });

                  yandexMapController?.moveCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: Point(
                          latitude: position.latitude,
                          longitude: position.longitude,
                        ),
                        zoom: 14.0,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(226, 192, 128, 1),
                  foregroundColor: const Color.fromRGBO(66, 56, 46, 1),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16.0),
                  elevation: 0,
                ),
                child: const Icon(Icons.location_pin),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color.fromRGBO(226, 192, 128, 1),
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.route),
              color: Color.fromRGBO(66, 56, 46, 1),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.search),
              color: Color.fromRGBO(66, 56, 46, 1),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (details) {
          if (!_isListening) {
            _animationController.forward();
            _listen();
          }
        },
        onTapUp: (details) {
          if (_isListening) {
            _animationController.reverse();
            _stopListening();
          }
        },
        onTapCancel: () {
          if (_isListening) {
            _animationController.reverse();
            _stopListening();
          }
        },
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.mic_rounded),
              backgroundColor: _colorAnimation.value,
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
