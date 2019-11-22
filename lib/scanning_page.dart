import 'package:camera/camera.dart';
import 'package:firebase_livestream_ml_vision/firebase_livestream_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_text_to_speech/flutter_text_to_speech.dart';
//import 'package:mlkit/mlkit.dart';

class ScanningPage extends StatefulWidget {
  @override
  _ScanningPageState createState() => _ScanningPageState();
}

class _ScanningPageState extends State<ScanningPage> {
  CameraController _camera;
  bool _isDetecting = false;
  VoiceController controller = FlutterTextToSpeech.instance.voiceController();
  FirebaseVision _vision;

//  FirebaseModelInterpreter interpreter = FirebaseModelInterpreter.instance;
//  FirebaseModelManager manager = FirebaseModelManager.instance;

  @override
  void initState() {
    super.initState();
    controller.init().then((success) {
      if (success) controller.speak('Welcome to Eye See Mobile');

//      manager.registerRemoteModelSource(FirebaseRemoteModelSource(
//        modelName: 'newmodel',
//        enableModelUpdates: true,
//      ));

      _startCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Eye See Mobile'),
        ),
        body: Container(
            constraints: const BoxConstraints.expand(),
            child: GestureDetector(
              onDoubleTap: () async {
                _isDetecting = true;
              },
              child: _vision != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        InkWell(
                            child: FirebaseCameraPreview(_vision),
                            onDoubleTap: () async =>
                                await controller.speak("This is a prototype")),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          CircularProgressIndicator(),
                          SizedBox(
                            height: 10,
                          ),
                          Text('Initializing Camera...',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 30.0,
                              ))
                        ],
                      ),
                    ),
            )));
  }

  void _startCamera() async {
    final FirebaseCameraDescription description =
        (await camerasAvailable()).elementAt(0);

    _vision = FirebaseVision(description, ResolutionSetting.high);

    _vision.initialize().then((_) async {
      if (!mounted) {
        return;
      }
      _vision
          .addVisionEdgeImageLabeler('test-custom-model', ModelLocation.Remote)
          .then((model) {
//        model.listen((onData) async {
//          if (_isDetecting) {
//          }
//        });
      });
      setState(() {});
    });

    setState(() {});
  }

  @override
  void dispose() {
    _camera.dispose().then((_) {});
    super.dispose();
  }
}
