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
              onDoubleTap: () {
                _isDetecting = true;
              },
              child: _vision != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        InkWell(
                          child: FirebaseCameraPreview(_vision),
                          onDoubleTap: () => setState(() {
                                _isDetecting = true;
                              }),
                        ),
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

    _vision.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _vision
          .addVisionEdgeImageLabeler('newmodel', ModelLocation.Remote)
          .then((onValue) {
        onValue.listen((onData) {
          print((onData as List<VisionEdgeImageLabel>).elementAt(0).text);
        });
      });
      setState(() {});
    });

//    _camera.startImageStream((CameraImage image) async {
//      if (!_isDetecting) return;
//
//      _isDetecting = false;
//
//      var results = await interpreter.run(
//        remoteModelName: 'newmodel',
//        inputBytes: image.planes[0].bytes,
//        inputOutputOptions: FirebaseModelInputOutputOptions([
//          FirebaseModelIOOption(FirebaseModelDataType.BYTE, [1, 640, 640, 3])
//        ], [
//          FirebaseModelIOOption(FirebaseModelDataType.BYTE, [1, 3])
//        ]),
//      );
//      print('RESULTS: ${results}');
//    });

    setState(() {});
  }

//  Widget _buildResults() {
//    const Text noResultsText = Text('No results!');
//
//    if (_scanResults == null ||
//        _camera == null ||
//        !_camera.value.isInitialized) {
//      return noResultsText;
//    }
//
//    CustomPainter painter;
//
//    final Size imageSize = Size(
//      _camera.value.previewSize.height,
//      _camera.value.previewSize.width,
//    );
//
//    painter = LabelDetectorPainter(imageSize, _scanResults);
//
//    return CustomPaint(
//      painter: painter,
//    );
//  }

  @override
  void dispose() {
    _camera.dispose().then((_) {});

    super.dispose();
  }
}
