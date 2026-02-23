import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  late final FaceDetector _faceDetector;

  FaceDetectorService() {
    final options = FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<List<Face>> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _faceDetector.processImage(inputImage);
  }

  void dispose() {
    _faceDetector.close();
  }
}
