import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'dart:io';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

const Map<String, String> landmarkNames = {
  "0": "Head",
  "11": "Left Shoulder",
  "12": "Right Shoulder",
  "13": "Left Elbow",
  "14": "Right Elbow",
  "15": "Left Wrist",
  "16": "Right Wrist",
  "23": "Left Hip",
  "24": "Right Hip",
  "25": "Left Knee",
  "26": "Right Knee",
  "27": "Left Ankle",
  "28": "Right Ankle",
};

class CameraPage extends StatefulWidget {
  final CameraDescription camera;
  final String figureJsonFile;
  final String videoUrl;

  const CameraPage({
    Key? key,
    required this.camera,
    required this.figureJsonFile,
    required this.videoUrl,
  }) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  late VideoPlayerController _videoController;

  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _recordButtonController;
  late AnimationController _countdownController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _recordButtonAnimation;
  late Animation<double> _countdownScaleAnimation;
  late Animation<Color?> _recordButtonColorAnimation;

  bool _isRecording = false;
  late String _videoPath;
  late String _videoFileName;
  String _accuracy = 'No video uploaded yet';
  int _countdown = 0;
  bool _videoEnded = false;
  bool _isLoading = false;
  bool _showInitialModal = true;
  bool _danceCompleted = false; // Track if dance was completed

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeCamera();
    _setupVideoController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showInitialModal) {
        _showInitialInstructionModal();
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _recordButtonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _recordButtonAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _recordButtonController, curve: Curves.easeInOut),
    );
    _countdownScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.elasticOut),
    );
    _recordButtonColorAnimation = ColorTween(
      begin: Colors.red.shade600,
      end: Colors.red.shade800,
    ).animate(_recordButtonController);

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _setupVideoController() {
    _videoController = VideoPlayerController.asset(widget.videoUrl)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
    _videoController.addListener(() async {
      final isAtEnd = _videoController.value.position >=
          _videoController.value.duration - const Duration(milliseconds: 200);
      final isNotPlaying = !_videoController.value.isPlaying;
      if (_isRecording && isAtEnd && isNotPlaying) {
        if (mounted) {
          setState(() {
            _videoEnded = true;
          });
          await _stopVideoRecording();
        }
      }
    });
  }

  Future<void> _showInitialInstructionModal() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade700, Colors.amber.shade500],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Position Yourself',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Stand approximately 5 steps back from the camera and ensure your full body remains visible within the frame for optimal accuracy',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.amber.shade800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (mounted) {
                            setState(() {
                              _showInitialModal = false;
                            });
                          }
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Got it!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    // Find rear camera first, fall back to front camera if not available
    _currentCameraIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);
    if (_currentCameraIndex == -1) {
      _currentCameraIndex = 0; // Use first available camera if no rear camera
    }

    _controller =
        CameraController(_cameras[_currentCameraIndex], ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length <= 1) return; // No other camera to switch to

    // Don't allow switching while recording
    if (_isRecording) return;

    // Dispose current controller
    await _controller.dispose();

    // Find next camera (toggle between front and back)
    if (_cameras[_currentCameraIndex].lensDirection ==
        CameraLensDirection.back) {
      // Currently using back camera, switch to front
      _currentCameraIndex = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front);
    } else {
      // Currently using front camera, switch to back
      _currentCameraIndex = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back);
    }

    // Fall back to first camera if specific direction not found
    if (_currentCameraIndex == -1) {
      _currentCameraIndex = 0;
    }

    // Initialize new camera
    _controller =
        CameraController(_cameras[_currentCameraIndex], ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    await _initializeControllerFuture;

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    _controller.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _recordButtonController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  Future<bool> _handleWillPop() async {
    if (_accuracy != 'No video uploaded yet') {
      await _showFeedbackDialog(_accuracy, false);
    }
    if (_danceCompleted) {
      await _showRatingDialog();
    }
    return true;
  }

  Future<void> _startVideoRecording() async {
    if (!_controller.value.isInitialized ||
        _controller.value.isRecordingVideo) {
      return;
    }
    try {
      final Directory appDirectory = await getApplicationDocumentsDirectory();
      final String videoDirectory = '${appDirectory.path}/Videos';
      final videoDir = Directory(videoDirectory);
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }
      final String currentTime =
          DateTime.now().millisecondsSinceEpoch.toString();
      _videoFileName = '$currentTime.mp4';
      _videoPath = join(videoDirectory, _videoFileName);

      await _controller.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      // animate pulse while recording
      _recordButtonController.repeat(reverse: true);
      // ignore: avoid_print
      print('Recording started. Video will be saved to $_videoPath');
    } catch (e) {
      // ignore: avoid_print
      print('Error starting video recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return;
    }

    try {
      final XFile videoFile = await _controller.stopVideoRecording();
      _videoPath = videoFile.path;
      _videoFileName = videoFile.name;

      if (mounted) {
        setState(() {
          _isRecording = false;
        });
        _recordButtonController.stop();
        _recordButtonController.reset();
      }

      // ignore: avoid_print
      print("Video saved to: $_videoPath");

      await _uploadVideoToAPI();
    } catch (e) {
      // ignore: avoid_print
      print('Error stopping video recording: $e');
    }
  }

  Future<void> _uploadVideoToAPI() async {
    // ignore: avoid_print
    print('Uploading video from path: $_videoPath');
    final file = File(_videoPath);
    // ignore: avoid_print
    print('File exists: ${file.existsSync()}');
    // ignore: avoid_print
    print('File size: ${file.existsSync() ? file.lengthSync() : 'N/A'} bytes');

    if (_videoPath.isEmpty || !file.existsSync()) {
      setState(() {
        _accuracy = 'Error: Video file not found!';
      });
      await _showFeedbackDialog('Error: Video file not found!', false);
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      if (mounted) {
        _showNoInternetDialog();
      }
      return;
    }

    _showUploadingDialog();

    try {
      final uri = Uri.parse('https://flipino-be.onrender.com/upload');
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final request = http.MultipartRequest('POST', uri)
        ..fields['figure'] = widget.figureJsonFile
        ..fields['user_id'] = userId ?? ''
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final respJson =
          responseData.body.isNotEmpty ? jsonDecode(responseData.body) : {};

      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        setState(() {
          _danceCompleted = true; // Mark dance as completed
        });
        await _showFeedbackDialog(respJson, true);
        // Do NOT show rating dialog here; it will show on back or when you decide
      } else {
        await _showFeedbackDialog(
            {'message': 'Error: ${respJson['error'] ?? 'Unknown error'}'},
            false);
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        setState(() {
          _accuracy = 'Error uploading video: $e';
        });
      }
      await _showFeedbackDialog('Error uploading video: $e', false);
    }
  }

  Future<void> _showRatingDialog() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    int rating = 0;
    bool submitting = false;
    String textFeedback = '';
    int maxChars = 50;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.feedback_outlined,
                      color: Colors.amber, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    "How was your dance experience?",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        icon: Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => rating = i + 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Text feedback box
                  TextField(
                    maxLength: maxChars,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: "Optional",
                      counterText: "${textFeedback.length}/$maxChars",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (val) {
                      if (val.length <= maxChars) {
                        setState(() => textFeedback = val);
                      }
                    },
                  ),
                ],
              ),
            ),
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Skip"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.brown[800],
                  minimumSize: const Size(70, 36),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: submitting || rating == 0
                    ? null
                    : () async {
                        setState(() => submitting = true);
                        await http.post(
                          Uri.parse('https://flipino-be.onrender.com/feedback'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'user_id': userId,
                            'figure_name': widget.figureJsonFile,
                            'rating': rating,
                            'text_feedback': textFeedback,
                          }),
                        );
                        setState(() => submitting = false);
                        Navigator.of(context).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Thank you for your feedback!',
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Submit"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                "Analyzing Your Dance...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please wait while we compare your performance",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.brown.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.wifi_off, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'No Internet Connection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'You are disconnected. Please connect to WiFi or mobile data.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCountdownAndRecord() async {
    for (int i = 3; i > 0; i--) {
      if (mounted) {
        setState(() {
          _countdown = i;
        });
        _countdownController.reset();
        _countdownController.forward();
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    if (mounted) {
      setState(() {
        _countdown = 0;
      });
    }

    // Start both video and recording
    _videoController.seekTo(Duration.zero);
    _videoController.play();
    await _startVideoRecording();
  }

  Future<void> _showFeedbackDialog(dynamic response, bool isSuccess) async {
    // Handle both String (old format) and Map (new format)
    String message;
    String? color;
    double? accuracy;
    Map<String, dynamic>? feedback;

    if (response is String) {
      message = response;
    } else if (response is Map<String, dynamic>) {
      message = response['message'] ?? 'Analysis complete';
      color = response['color'];
      accuracy = response['accuracy']?.toDouble();
      feedback = response['feedback'];
    } else {
      message = 'Analysis complete';
    }

    // Get color based on score
    Color headerColor;
    if (isSuccess && color != null) {
      switch (color) {
        case 'green':
          headerColor = Colors.green.shade600;
          break;
        case 'orange':
          headerColor = Colors.orange.shade600;
          break;
        case 'red':
          headerColor = Colors.red.shade600;
          break;
        default:
          headerColor = Colors.green.shade600;
      }
    } else {
      headerColor = isSuccess ? Colors.green.shade600 : Colors.red.shade600;
    }

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSuccess ? Icons.analytics : Icons.error,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isSuccess
                            ? 'Dance Analysis Complete!'
                            : 'Analysis Error',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Early Access Disclaimer
                    if (isSuccess)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.science,
                                color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Early Access - AI Dance Analysis is currently in development and fine-tuning phase',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Main Score Display
                    if (accuracy != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: headerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star, color: headerColor, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '${accuracy.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: headerColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Main Message
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Feedback Section
                    if (isSuccess &&
                        feedback != null &&
                        _buildFeedbackContent(feedback).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Areas for Improvement:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildFeedbackContent(feedback),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: headerColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeedbackContent(Map<String, dynamic> feedback) {
    List<Widget> widgets = [];

    // Check for special conditions first
    if (feedback['no_body_detected'] == true) {
      widgets.add(
        _buildFeedbackItem(
          Icons.person_off,
          'No Body Detected',
          'Make sure you\'re fully visible in the camera frame and try again.',
          Colors.red,
        ),
      );
      return widgets;
    }

    if (feedback['no_movement_detected'] == true) {
      widgets.add(
        _buildFeedbackItem(
          Icons.directions_run,
          'More Movement Needed',
          'Perform the dance with larger, more expressive movements.',
          Colors.orange,
        ),
      );
      return widgets;
    }

    // Body part specific feedback (most user-friendly)
    if (feedback['body_part_feedback'] != null &&
        (feedback['body_part_feedback'] as List).isNotEmpty) {
      final bodyFeedback = feedback['body_part_feedback'] as List;
      for (String tip in bodyFeedback.take(2)) {
        // Limit to 2 tips
        widgets.add(
          _buildFeedbackItem(
            Icons.accessibility_new,
            'Movement Tip',
            tip,
            Colors.blue,
          ),
        );
      }
    }

    // Worst landmarks feedback (simplified)
    if (feedback['worst_landmarks'] != null &&
        (feedback['worst_landmarks'] as List).isNotEmpty) {
      final worstLandmarks = feedback['worst_landmarks'] as List;
      if (worstLandmarks.isNotEmpty && widgets.length < 2) {
        String landmarkName = worstLandmarks[0][0];
        widgets.add(
          _buildFeedbackItem(
            Icons.adjust,
            'Focus Area',
            'Pay attention to your ${landmarkName.toLowerCase()} positioning and movement.',
            Colors.purple,
          ),
        );
      }
    }

    return widgets;
  }

  Widget _buildFeedbackItem(
      IconData icon, String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // iPhone-style floating button
  // ==============================
  Widget _buildRecordButton() {
    if (!_videoController.value.isInitialized) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade400,
        ),
        child: const Icon(Icons.videocam_off, color: Colors.white, size: 36),
      );
    }

    return AnimatedBuilder(
      animation: _recordButtonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRecording ? _recordButtonAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isRecording
                    ? [Colors.red.shade700, Colors.red.shade500]
                    : [Colors.red.shade600, Colors.red.shade400],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(40),
                onTap: () async {
                  if (_isRecording) {
                    await _stopVideoRecording();
                  } else {
                    await _showCountdownAndRecord();
                  }
                },
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF5D4037),
                    Color(0xFFD7A86E),
                    Color(0xFF263238),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Background pattern overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset('assets/indakbg2.jpg', fit: BoxFit.cover),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Back button:
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 28),
                            onPressed: () async {
                              if (_accuracy != 'No video uploaded yet') {
                                await _showFeedbackDialog(_accuracy, false);
                              }
                              if (_danceCompleted) {
                                await _showRatingDialog();
                              }
                              Navigator.pop(context);
                            },
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.shade700,
                                    Colors.amber.shade500
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.videocam,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Dance Recording',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Balance for back button
                        ],
                      ),
                    ),
                    // Reference video
                    if (_videoController.value.isInitialized)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 180,
                            child: Stack(
                              children: [
                                // Centered video player
                                Center(
                                  child: AspectRatio(
                                    aspectRatio:
                                        _videoController.value.aspectRatio,
                                    child: VideoPlayer(_videoController),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Reference Video',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Camera preview
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              FutureBuilder<void>(
                                future: _initializeControllerFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    return Stack(
                                      children: [
                                        // Camera preview with proper aspect ratio to avoid face distortion
                                        Positioned.fill(
                                          child: FittedBox(
                                            fit: BoxFit.cover,
                                            child: SizedBox(
                                              width: _controller.value
                                                      .previewSize?.height ??
                                                  1,
                                              height: _controller.value
                                                      .previewSize?.width ??
                                                  1,
                                              child: CameraPreview(_controller),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: SizedBox(
                                            width: 210,
                                            height: 400,
                                            child: CustomPaint(
                                              painter:
                                                  _EnhancedPictureFramePainter(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return Container(
                                      color: Colors.black12,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              color: Colors.amber.shade600,
                                            ),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Initializing camera...',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),

                              // Instruction overlay
                              if (_accuracy == 'No video uploaded yet' &&
                                  _countdown == 0 &&
                                  !_isRecording)
                                Center(
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          width: 280,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 20),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withOpacity(0.8),
                                                Colors.black.withOpacity(0.6),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.videocam,
                                                color: Colors.amber.shade400,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Ready to Dance?',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Tap the record button to start!',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // Countdown overlay
                              if (_countdown > 0)
                                Container(
                                  color: Colors.black.withOpacity(0.8),
                                  child: Center(
                                    child: AnimatedBuilder(
                                      animation: _countdownScaleAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _countdownScaleAnimation.value,
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.amber.shade600,
                                                  Colors.amber.shade400,
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.amber
                                                      .withOpacity(0.5),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 0),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '$_countdown',
                                                style: const TextStyle(
                                                  fontSize: 48,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                              // Progress indicator during recording (moved up to avoid overlap)
                              if (_isRecording)
                                Positioned(
                                  bottom: 110, // was 20
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Follow the reference video',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        StreamBuilder(
                                          stream: Stream.periodic(
                                              const Duration(
                                                  milliseconds: 100)),
                                          builder: (context, snapshot) {
                                            if (!_videoController
                                                .value.isInitialized) {
                                              return LinearProgressIndicator(
                                                value: 0,
                                                backgroundColor:
                                                    Colors.grey.shade600,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Colors.amber.shade400),
                                              );
                                            }
                                            final progress = _videoController
                                                    .value
                                                    .position
                                                    .inMilliseconds /
                                                _videoController.value.duration
                                                    .inMilliseconds;
                                            return LinearProgressIndicator(
                                              value: progress.clamp(0.0, 1.0),
                                              backgroundColor:
                                                  Colors.grey.shade600,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.amber.shade400),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Camera switch button (top-left)
                              if (_cameras.length > 1 && !_isRecording)
                                Positioned(
                                  top: 20,
                                  left: 20,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(25),
                                      onTap: _switchCamera,
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.cameraswitch,
                                          color: Colors.amber.shade400,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // REC pill top-right while recording
                              if (_isRecording)
                                Positioned(
                                  top: 20,
                                  right: 20,
                                  child: AnimatedBuilder(
                                    animation: _recordButtonAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _recordButtonAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade600,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.red.withOpacity(0.4),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'REC',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              // ==========================
                              // FLOATING RECORD BUTTON
                              // ==========================
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: MediaQuery.of(context).padding.bottom,
                                child: Transform.translate(
                                  offset: const Offset(0, 3), // try 2–4
                                  child: Center(child: _buildRecordButton()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ⛔️ REMOVED: old bottom Container with record button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedPictureFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    double lineLength = size.shortestSide * 0.18;

    // Draw shadow first
    _drawCornerLines(canvas, shadowPaint, size, lineLength, 1);

    // Draw main lines
    _drawCornerLines(canvas, paint, size, lineLength, 0);

    // Add center dot
    final centerDot = Paint()
      ..color = Colors.amber.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      centerDot,
    );
  }

  void _drawCornerLines(
      Canvas canvas, Paint paint, Size size, double lineLength, double offset) {
    // Top-left
    canvas.drawLine(
      Offset(0 + offset, 0 + offset),
      Offset(lineLength + offset, 0 + offset),
      paint,
    );
    canvas.drawLine(
      Offset(0 + offset, 0 + offset),
      Offset(0 + offset, lineLength + offset),
      paint,
    );

    // Top-right
    canvas.drawLine(
      Offset(size.width - offset, 0 + offset),
      Offset(size.width - lineLength - offset, 0 + offset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - offset, 0 + offset),
      Offset(size.width - offset, lineLength + offset),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0 + offset, size.height - offset),
      Offset(lineLength + offset, size.height - offset),
      paint,
    );
    canvas.drawLine(
      Offset(0 + offset, size.height - offset),
      Offset(0 + offset, size.height - lineLength - offset),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - lineLength - offset, size.height - offset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - offset, size.height - offset),
      Offset(size.width - offset, size.height - lineLength - offset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
