import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:eye_see_mobile/scanner_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_text_to_speech/flutter_text_to_speech.dart';
import 'package:image/image.dart' as i;
import 'package:mlkit/mlkit.dart';

import 'image_converter.dart';

class ScanningPage extends StatefulWidget {
  @override
  _ScanningPageState createState() => _ScanningPageState();
}

class _ScanningPageState extends State<ScanningPage> {
  CameraController _camera;
  List<String> labels;
  List<int> compressed;

  bool _isDetecting = false;
  VoiceController controller = FlutterTextToSpeech.instance.voiceController();

  FirebaseModelInterpreter interpreter = FirebaseModelInterpreter.instance;
  FirebaseModelManager manager = FirebaseModelManager.instance;

  FirebaseModelInputOutputOptions ioOptions = FirebaseModelInputOutputOptions([
    FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 256, 256, 3])
  ], [
    FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 93])
  ]);

  @override
  void initState() {
    super.initState();
    controller.init().then((success) {
      if (success) controller.speak('Welcome to Eye See Mobile');

      manager.registerRemoteModelSource(
          FirebaseRemoteModelSource(modelName: 'custom-model'));

      rootBundle.loadString('assets/labels.txt').then((string) {
        var _l = string.split('\n');
        labels = _l;
      });

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
              onDoubleTap: () async {},
              child: _camera != null
                  ? Stack(
                      children: <Widget>[
                        InkWell(
                          child: CameraPreview(_camera),
                          onDoubleTap: () {
                            _isDetecting = true;
                          },
                        ),
                        compressed != null
                            ? Image.memory(
                                Uint8List.fromList(compressed),
                                alignment: AlignmentDirectional.bottomEnd,
                              )
                            : Text("None"),
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
    final CameraDescription description =
        await ScannerUtils.getCamera(CameraLensDirection.back);

    _camera = CameraController(
      description,
      ResolutionPreset.medium,
    );

    await _camera.initialize();

    _camera.startImageStream((image) async {
      if (!_isDetecting) return;
      _isDetecting = false;

      var convertedImageBytes = await ImageConverter.convertImagetoPng(image);

      compressed = await FlutterImageCompress.compressWithList(
          image.planes[0].bytes.toList(),
          minHeight: 256,
          minWidth: 256,
          rotate: -90,
          format: CompressFormat.png);

      setState(() {});

      var imageByteList = await imageToByteListFloat(compressed, 256);

      var results = await interpreter.run(
          remoteModelName: "custom-model",
          inputOutputOptions: ioOptions,
          inputBytes: Uint8List.fromList(imageByteList));

      List<ObjectLabel> labelConfidenceList = [];

      results[0][0].forEach((result) {
        int index = results[0][0]?.indexOf(result);
        if (index != -1) {
          labelConfidenceList.add(ObjectLabel(labels.elementAt(index), result));
        }
      });

      labelConfidenceList.sort((l1, l2) {
        return (l2.confidence.compareTo(l1.confidence));
      });
      print(labelConfidenceList.toString());

      controller.speak('This is a ${labelConfidenceList.elementAt(0).label}');
    });
    setState(() {});
  }

  Future<Uint8List> imageToByteListFloat(
      List<int> bytes, int _inputSize) async {
    var decoder = i.findDecoderForData(bytes);
    i.Image image = decoder.decodeImage(bytes);

    var convertedBytes = Float32List(1 * _inputSize * _inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);

    int pixelIndex = 0;
    for (var i = 0; i < _inputSize; i++) {
      for (var j = 0; j < _inputSize; j++) {
        var pixel = image.getPixel(i, j);
        buffer[pixelIndex] = ((pixel >> 16) & 0xFF) / 255;
        pixelIndex += 1;
        buffer[pixelIndex] = ((pixel >> 8) & 0xFF) / 255;
        pixelIndex += 1;
        buffer[pixelIndex] = ((pixel) & 0xFF) / 255;
        pixelIndex += 1;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Uint8List imageToByteList(i.Image image) {
    var _inputSize = 256;
    var convertedBytes = Float32List(1 * _inputSize * _inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < _inputSize; i++) {
      for (var j = 0; j < _inputSize; j++) {
        var pixel = image.getPixel(i, j);
        buffer[pixelIndex] = ((pixel >> 16) & 0xFF) / 255;
        pixelIndex += 1;
        buffer[pixelIndex] = ((pixel >> 8) & 0xFF) / 255;
        pixelIndex += 1;
        buffer[pixelIndex] = ((pixel) & 0xFF) / 255;
        pixelIndex += 1;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  @override
  void dispose() {
    _camera.dispose().then((_) {});
    super.dispose();
  }
}

class ObjectLabel {
  String label;
  double confidence;

  ObjectLabel([this.label, this.confidence]);

  @override
  String toString() {
    return 'ObjectLabel{label: $label, confidence: $confidence}';
  }
}
