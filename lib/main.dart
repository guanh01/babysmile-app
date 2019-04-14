import 'package:flutter/material.dart';
import 'package:speech_recognition/speech_recognition.dart';
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';


Future<void> main() async {
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras
//  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MyApp(
        // Pass the appropriate camera to the TakePictureScreen Widget
        cameras: cameras,
      ),
    ),
  );
}

//void main() {
//
//  runApp(new MyApp());
//}

const languages = const [
  const Language('Francais', 'fr_FR'),
  const Language('English', 'en_US'),
  const Language('Pусский', 'ru_RU'),
  const Language('Italiano', 'it_IT'),
  const Language('Español', 'es_ES'),
];

class Language {
  final String name;
  final String code;

  const Language(this.name, this.code);
}

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MyApp({
    Key key,
    @required this.cameras,
  }) : super(key: key);

  @override
  _MyAppState createState() => new _MyAppState();
}


// A Widget that displays the picture taken by the user
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image
      body: Image.file(File(imagePath)),
    );
  }
}


class _MyAppState extends State<MyApp> {
//  CameraController _controller_back;
//  CameraController _controller_front;
//  Future<void> _initializeControllerFuture_back;
//  Future<void> _initializeControllerFuture_front;
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  bool _isFront = false;

  SpeechRecognition _speech;

  bool isListening = false;
  String transcription = '';

  //String _currentLocale = 'en_US';
  Language selectedLang = languages.first;



  @override
  initState() {
    super.initState();

    _controller = CameraController(
      // Get a specific camera from the list of available cameras
      widget.cameras.first,
      // Define the resolution to use
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller.initialize();
//
//    // front camera
//    _controller_front = CameraController(
//      // Get a specific camera from the list of available cameras
//      widget.cameras.elementAt(1),
//      // Define the resolution to use
//      ResolutionPreset.medium,
//    );
//    _initializeControllerFuture_front = _controller_front.initialize();

    activateSpeechRecognizer();
  }

  @override
  void dispose() {
    // Make sure to dispose of the controller when the Widget is disposed
//    _controller_back.dispose();
//    _controller_front.dispose();
    _controller.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  void activateSpeechRecognizer() {
    print('activateSpeechRecognizer called...');
    _speech = new SpeechRecognition();
    _speech.setAvailabilityHandler(onSpeechAvailability);
    _speech.setCurrentLocaleHandler(onCurrentLocale);
    _speech.setRecognitionStartedHandler(onRecognitionStarted);
    _speech.setRecognitionResultHandler(onRecognitionResult);
    _speech.setRecognitionCompleteHandler(onRecognitionComplete);
    _speech.setErrorHandler(errorHandler);
    _speech
        .activate()
        .then((res) => setState(() => res?
        print('successfully activated!'): print('bad activate!')));
  }

  void changeCamera() async {
    _isFront = !_isFront;

    if (_controller != null){
      await _controller.dispose();
    }
    if (!_isFront){
      _controller = CameraController(
        // Get a specific camera from the list of available cameras
        widget.cameras.first,
        // Define the resolution to use
        ResolutionPreset.high,
      );
    }else{
      _controller = CameraController(
        // Get a specific camera from the list of available cameras
        widget.cameras.elementAt(1),
        // Define the resolution to use
        ResolutionPreset.high,
      );

    }
    _initializeControllerFuture = _controller.initialize();

    if(mounted){
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {


    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('SayCheese'),
          actions: [
            new IconButton(icon: new Icon(_isFront? Icons.camera_rear: Icons.camera_front),
              onPressed: () => changeCamera()),
            ]
        ),
        body: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    // If the Future is complete, display the preview
                    return new Transform.scale(
                        scale: 1 / _controller.value.aspectRatio,
                        child: new Center(
                          child: new AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: new CameraPreview(_controller)),
                        ));
                  } else {
                    // Otherwise, display a loading indicator
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
        floatingActionButton: FloatingActionButton(
            child:
              isListening? Icon(Icons.record_voice_over) : Icon(Icons.keyboard_voice),
            // Provide an onPressed callback
            onPressed: () => start(),
        )

        ),
    );
  }


  void takePicture() async {

    // Take the Picture in a try / catch block. If anything goes wrong,
    // catch the error.
    try {
      // Ensure the camera is initialized
      await _initializeControllerFuture;

      // Construct the path where the image should be saved using the path
      // package.
      final path = join(
        // In this example, store the picture in the temp directory. Find
        // the temp directory using the `path_provider` plugin.
        (await getTemporaryDirectory()).path,
        '${DateTime.now()}.png',
      );

      // Attempt to take a picture and log where it's been saved
      await _controller.takePicture(path);

      // If the picture was taken, display it on a new screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imagePath: path),
        ),
      );
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }


  List<CheckedPopupMenuItem<Language>> get _buildLanguagesWidgets => languages
      .map((l) => new CheckedPopupMenuItem<Language>(
    value: l,
    checked: selectedLang == l,
    child: new Text(l.name),
  ))
      .toList();


  void start() => _speech
      .listen(locale: selectedLang.code)
      .then((result) => print('_MyAppState.start => result $result'));


  void stop() => _speech.stop().then((result) {
    setState(() => isListening = result);
  });


  void onSpeechAvailability(bool result) =>
      setState(() => isListening = result);


  void onCurrentLocale(String locale) {
    print('onCurrentLocale called, input: $locale');
    setState(
            () => selectedLang = languages.firstWhere((l) => l.code == locale));
  }

  void onRecognitionStarted(){
    print('onRecognitionStarted called ...');
  }


  void onRecognitionResult(String text){
    print("onRecognitionResult called, input: $text");
  }

  void onRecognitionComplete(String text) {
    print("onRecognitionComplete called, input: $text");
    isListening = false;
    if (text.contains('cheese')){
      takePicture();
    }
  }

  void errorHandler(){
    print("errorHandler called ...");
    setState(() => isListening = false);
    activateSpeechRecognizer();
  }
}

