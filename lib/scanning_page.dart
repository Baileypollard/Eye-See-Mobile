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

  bool _isDetecting = false;
  VoiceController controller = FlutterTextToSpeech.instance.voiceController();

  FirebaseModelInterpreter interpreter = FirebaseModelInterpreter.instance;
  FirebaseModelManager manager = FirebaseModelManager.instance;

  FirebaseModelInputOutputOptions ioOptions = FirebaseModelInputOutputOptions([
    FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 256, 256, 3])
  ], [
    FirebaseModelIOOption(FirebaseModelDataType.FLOAT32, [1, 88])
  ]);

  @override
  void initState() {
    super.initState();
    controller.init().then((success) {
      if (success) controller.speak('Welcome to Eye See Mobile');

      manager.registerRemoteModelSource(FirebaseRemoteModelSource(
        modelName: 'test-custom-new-new-model',
        enableModelUpdates: true,
      ));

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
                      fit: StackFit.expand,
                      children: <Widget>[
                        InkWell(
                          child: CameraPreview(_camera),
                          onDoubleTap: () {
                            _isDetecting = true;
                          },
                        )
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

      var compressed = await FlutterImageCompress.compressWithList(
          convertedImageBytes,
          minHeight: 256,
          minWidth: 256,
          format: CompressFormat.png);

      var ty = await imageToByteListFloat(compressed, 256);

      var results = await interpreter.run(
          remoteModelName: "test-custom-new-new-model",
          inputOutputOptions: ioOptions,
          inputBytes: ty);

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

      print(labelConfidenceList.elementAt(0));
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

  @override
  void dispose() {
    _camera.dispose().then((_) {});
    super.dispose();
  }

  var shift = (0xFF << 24);
  Future<i.Image> convertYUV420toImageColor(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel;

      print("uvRowStride: " + uvRowStride.toString());
      print("uvPixelStride: " + uvPixelStride.toString());

      // imgLib -> Image package from https://pub.dartlang.org/packages/image
      var img = i.Image(width, height); // Create Image buffer

      // Fill image buffer with plane[0] from YUV420_888
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex =
              uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;

          final yp = image.planes[0].bytes[index];
          final up = image.planes[1].bytes[uvIndex];
          final vp = image.planes[2].bytes[uvIndex];
          // Calculate pixel color
          int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
          int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
              .round()
              .clamp(0, 255);
          int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
          // color: 0x FF  FF  FF  FF
          //           A   B   G   R
          img.data[index] = shift | (b << 16) | (g << 8) | r;
        }
      }

      i.PngEncoder pngEncoder = new i.PngEncoder(level: 0, filter: 0);
      List<int> png = pngEncoder.encodeImage(img);
      print(png);
      return i.Image.fromBytes(width, height, png);
    } catch (e) {
      print(">>>>>>>>>>>> ERROR:" + e.toString());
    }
    return null;
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
