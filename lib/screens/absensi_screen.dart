import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../services/api_service.dart';
import '../services/face_detector_service.dart';
import '../services/location_service.dart';

class AbsensiScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const AbsensiScreen({super.key, required this.cameras});

  @override
  State<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends State<AbsensiScreen> {
  CameraController? _cameraController;
  late FaceDetectorService _faceDetectorService;

  bool _isBusy = false;
  String _statusText = "Siap untuk absen";

  @override
  void initState() {
    super.initState();
    _faceDetectorService = FaceDetectorService();
    _initializeCamera();
  }

  void _initializeCamera() {
    if (widget.cameras.isEmpty) return;

    CameraDescription? frontCamera;
    for (var camera in widget.cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    _cameraController = CameraController(
      frontCamera ?? widget.cameras[0],
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
    _faceDetectorService.dispose();
    super.dispose();
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
      final faces = await _faceDetectorService.processImage(imageFile.path);

      if (faces.isEmpty) {
        _showResultDialog(
          "Gagal",
          "Wajah tidak terdeteksi. Pastikan wajah terlihat jelas di kamera.",
          false,
        );
        return;
      }

      setState(() => _statusText = "Mengambil lokasi GPS...");
      final position = await LocationService.determinePosition();

      setState(() => _statusText = "Mengirim data ke server...");
      final timestamp = await ApiService.submitAbsensi(
        nama: "Pekerja Lapangan (Demo)",
        lat: position.latitude,
        lng: position.longitude,
        faceStatus: "Terdeteksi (${faces.length} wajah)",
      );

      _showResultDialog(
        "Berhasil",
        "Absensi berhasil direkam pada $timestamp",
        true,
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
