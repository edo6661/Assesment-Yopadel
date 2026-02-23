import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

List<CameraDescription> cameras = [];
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error in fetching the cameras: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi Lapangan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AbsensiScreen(),
    );
  }
}

class AbsensiScreen extends StatefulWidget {
  const AbsensiScreen({super.key});
  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  bool _isBusy = false;
  String _statusText = "Siap untuk absen";
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    final options = FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
    );
    _faceDetector = FaceDetector(options: options);
  }

  void _initializeCamera() {
    if (cameras.isEmpty) return;
    CameraDescription? frontCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }
    _cameraController = CameraController(
      frontCamera ?? cameras[0],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    _cameraController?.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _prosesAbsensi() async {
    if (_isBusy ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }
    setState(() {
      _isBusy = true;
      _statusText = "Mendeteksi wajah...";
    });
    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        _showResultDialog(
          "Gagal",
          "Wajah tidak terdeteksi. Pastikan wajah terlihat jelas di kamera.",
          false,
        );
        return;
      }
      setState(() => _statusText = "Mengambil lokasi GPS...");
      Position position = await _determinePosition();
      setState(() => _statusText = "Mengirim data ke server...");
      await _submitAbsensi(
        nama: "Pekerja Lapangan (Demo)",
        lat: position.latitude,
        lng: position.longitude,
        faceStatus: "Terdeteksi (${faces.length} wajah)",
      );
      File(imageFile.path).deleteSync();
    } catch (e) {
      _showResultDialog("Error", e.toString(), false);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _statusText = "Siap untuk absen";
        });
      }
    }
  }

  Future<void> _submitAbsensi({
    required String nama,
    required double lat,
    required double lng,
    required String faceStatus,
  }) async {
    const String scriptUrl =
        "https://script.google.com/macros/s/AKfycbyvTQ1sLJr-ZzANGPq5h_ktXk-T4Uo6dFzJLoK-nMFh-j1tqmktQ-6L1LUEfR_rJqq9/exec";
    String currentTime = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());
    Map<String, dynamic> body = {
      "timestamp": currentTime,
      "nama": nama,
      "latitude": lat,
      "longitude": lng,
      "face_status": faceStatus,
      "foto_url": "-",
    };
    try {
      var request = http.Request('POST', Uri.parse(scriptUrl))
        ..followRedirects = false
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 302) {
        String? redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          response = await http.get(Uri.parse(redirectUrl));
        }
      }
      if (response.statusCode == 200) {
        _showResultDialog(
          "Berhasil",
          "Absensi berhasil direkam pada $currentTime",
          true,
        );
      } else {
        _showResultDialog(
          "Gagal",
          "Gagal mengirim data. Status: ${response.statusCode}",
          false,
        );
      }
    } catch (e) {
      _showResultDialog("Error", "Gagal terhubung ke server: $e", false);
    }
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(color: isSuccess ? Colors.green : Colors.red),
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Absensi Lapangan"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _statusText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _prosesAbsensi,
                      icon: _isBusy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint),
                      label: Text(_isBusy ? "Memproses..." : "Absen Sekarang"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
