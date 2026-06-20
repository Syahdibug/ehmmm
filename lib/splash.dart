import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'loader_page.dart';

class SplashPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const SplashPage({super.key, required this.data});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/videos/load.mp4')
      ..initialize().then((_) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        setState(() => _isInitialized = true);
        _controller.play();
        _controller.setVolume(1.0);
        _fadeController.forward();
      }).catchError((error) {
        debugPrint("Video error: $error");
        setState(() => _isInitialized = true);
        _fadeController.forward();
        Future.delayed(const Duration(seconds: 3), _navigateToDashboard);
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    _controller.pause();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            username: widget.data['username'] ?? '',
            password: widget.data['password'] ?? '',
            role: widget.data['role'] ?? 'user',
            expiredDate: widget.data['expiredDate'] ?? '-',
            sessionKey: widget.data['key'] ?? '',
            listBug: List<Map<String, dynamic>>.from(widget.data['listBug'] ?? []),
            listPayload: List<Map<String, dynamic>>.from(widget.data['listPayload'] ?? []),
            listDDoS: List<Map<String, dynamic>>.from(widget.data['listDDoS'] ?? []),
            news: List<Map<String, dynamic>>.from(widget.data['news'] ?? []),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. VIDEO BACKGROUND
          if (_isInitialized && _controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const SizedBox.expand(),

          // 2. SUBTLE DARK OVERLAY
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 3. SYAHID ALLCRASH TEXT — slightly below center
          FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: const Alignment(0, 0.35),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thin red accent line above
                  Container(
                    width: 40,
                    height: 1.5,
                    color: const Color(0xFFE53935),
                    margin: const EdgeInsets.only(bottom: 14),
                  ),
                  // Main title
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "SYAHID ",
                          style: TextStyle(
                            fontFamily: 'MADEEvolveSansEVO',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 6,
                          ),
                        ),
                        TextSpan(
                          text: "ALLCRASH",
                          style: TextStyle(
                            fontFamily: 'MADEEvolveSansEVO',
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE53935),
                            letterSpacing: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Subtitle
                  Text(
                    "ADVANCED SECURITY PLATFORM",
                    style: TextStyle(
                      fontFamily: 'ShareTechMono',
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.35),
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Thin red accent line below
                  Container(
                    width: 40,
                    height: 1.5,
                    color: const Color(0xFFE53935),
                  ),
                ],
              ),
            ),
          ),

          // 4. SKIP BUTTON — top right
          Positioned(
            top: 50,
            right: 24,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GestureDetector(
                onTap: _navigateToDashboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFE53935).withOpacity(0.7),
                      width: 1,
                    ),
                    color: Colors.black.withOpacity(0.55),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "SKIP",
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'MADEEvolveSansEVO',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFE53935),
                        size: 11,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}