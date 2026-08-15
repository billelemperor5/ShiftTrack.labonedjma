import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';

class FaceCheckinScreen extends StatefulWidget {
  final String mode; // 'checkin' or 'checkout'
  const FaceCheckinScreen({super.key, required this.mode});

  @override
  State<FaceCheckinScreen> createState() => _FaceCheckinScreenState();
}

class _FaceCheckinScreenState extends State<FaceCheckinScreen>
    with TickerProviderStateMixin {
  CameraController? _camCtrl;
  FaceDetector? _faceDetector;

  bool _isDetecting = false;
  bool _faceDetected = false;
  bool _confirmed = false;
  String _recordedTime = '';
  int _faceFrames = 0;
  static const _requiredFrames = 8;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    if (!kIsWeb) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.3,
        ),
      );
    }

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _camCtrl = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: kIsWeb ? null : ImageFormatGroup.nv21,
      );
      await _camCtrl!.initialize();
      if (!mounted) return;
      setState(() {});

      if (kIsWeb) {
        // Web simulation auto check-in after 1.5 seconds
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && !_confirmed) {
            _faceDetected = true;
            _autoConfirm();
          }
        });
      } else {
        _camCtrl!.startImageStream(_processFrame);
      }
    } catch (_) {}
  }

  void _processFrame(CameraImage image) async {
    if (kIsWeb || _isDetecting || _confirmed || _faceDetected) return;
    if (_faceDetector == null) return;
    _isDetecting = true;

    try {
      final inputImage = _convertImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector!.processImage(inputImage);

      if (_confirmed) {
        _isDetecting = false;
        return;
      }

      if (faces.isNotEmpty) {
        final face = faces.first;
        final leftEye = face.leftEyeOpenProbability ?? 1.0;
        final rightEye = face.rightEyeOpenProbability ?? 1.0;
        final eyesOpen = leftEye > 0.4 && rightEye > 0.4;

        if (eyesOpen) {
          _faceFrames++;
          if (_faceFrames >= _requiredFrames && !_faceDetected && !_confirmed) {
            _faceDetected = true;
            _autoConfirm();
          }
        } else {
          _faceFrames = (_faceFrames - 1).clamp(0, _requiredFrames);
        }
      } else {
        _faceFrames = (_faceFrames - 2).clamp(0, _requiredFrames);
      }
    } catch (_) {}

    _isDetecting = false;
  }

  InputImage? _convertImage(CameraImage image) {
    if (_camCtrl == null) return null;
    final camera = _camCtrl!.description;
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  void _autoConfirm() {
    if (_confirmed) return;
    _confirmed = true;

    try {
      if (!kIsWeb) {
        _camCtrl?.stopImageStream();
      }
    } catch (_) {}

    final now = TimeOfDay.now();
    _recordedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
    }
    setState(() {});

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.pop(context, _recordedTime);
      }
    });
  }

  @override
  void dispose() {
    _camCtrl?.dispose();
    _faceDetector?.close();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCheckIn = widget.mode == 'checkin';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_camCtrl != null && _camCtrl!.value.isInitialized)
            Positioned.fill(child: CameraPreview(_camCtrl!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.25, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Face frame circle
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _faceDetected && !_confirmed ? 1.0 : _pulseAnim.value,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _confirmed
                            ? const Color(0xFF10B981)
                            : _faceDetected
                            ? const Color(0xFF10B981).withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.4),
                        width: _faceDetected ? 4 : 2,
                      ),
                      boxShadow: _faceDetected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: _confirmed
                        ? const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: Color(0xFF10B981),
                              size: 80,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isCheckIn
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444))
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCheckIn ? 'Arrivée' : 'Départ',
                      style: TextStyle(
                        color: isCheckIn
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom section
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_confirmed) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isCheckIn
                            ? 'Arrivée enregistrée !'
                            : 'Départ enregistré !',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _recordedTime,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ] else if (_faceDetected) ...[
                      Text(
                        kIsWeb ? 'Détection réussie ✓' : 'Visage détecté ✓',
                        style: TextStyle(
                          color: const Color(0xFF10B981).withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFF10B981),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ] else ...[
                      Text(
                        kIsWeb ? 'Simulation de détection de visage (Web)' : 'Placez votre visage dans le cercle',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: kIsWeb ? 0.8 : _faceFrames / _requiredFrames,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF0F766E),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
