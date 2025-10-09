import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../services/story_service.dart';
import 'game_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  String _displayedText = '';
  bool _isTyping = false;
  bool _canSkip = false;
  bool _showSkipButton = false;
  int _currentStoryIndex = 0;

  // Typing speed in milliseconds per character
  static const int _typingSpeed = 30;

  final List<String> _storyParts = [];

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      // Load intro story and split into parts (no ASCII art)
      final introText =
          await StoryService.loadAssetText('assets/zombie_intro.txt');
      final storyParts = StoryService.parseIntroStory(introText);

      setState(() {
        _storyParts
          ..clear()
          ..addAll(storyParts);
      });

      _startTyping();
    } catch (e) {
      print('Error loading story: $e');
      // Fallback to game screen if story loading fails
      _navigateToGame();
    }
  }

  void _startTyping() {
    if (_currentStoryIndex >= _storyParts.length) {
      _navigateToGame();
      return;
    }

    setState(() {
      _isTyping = true;
      _canSkip = true;
      _showSkipButton = true;
      _displayedText = '';
    });

    _typeText(_storyParts[_currentStoryIndex]);
  }

  void _typeText(String text) async {
    for (int i = 0; i <= text.length; i++) {
      if (!mounted || !_isTyping) break;

      setState(() {
        _displayedText = text.substring(0, i);
      });

      await Future.delayed(const Duration(milliseconds: _typingSpeed));
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
      });

      // Auto-advance after a pause, or wait for user input
      await Future.delayed(const Duration(seconds: 2));

      if (mounted && !_isTyping) {
        _nextStoryPart();
      }
    }
  }

  void _skipTyping() {
    if (_isTyping && _canSkip) {
      setState(() {
        _isTyping = false;
        _displayedText = _storyParts[_currentStoryIndex];
      });
    } else {
      _nextStoryPart();
    }
  }

  void _nextStoryPart() {
    setState(() {
      _currentStoryIndex++;
    });

    if (_currentStoryIndex < _storyParts.length) {
      _startTyping();
    } else {
      _navigateToGame();
    }
  }

  void _navigateToGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundColor,
              AppTheme.surfaceColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Title hero (styled text)
                    Column(
                      children: [
                        Text(
                          'Zombie Survival Game',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                  color: AppTheme.borderColor,
                                  blurRadius: 4,
                                  offset: Offset(1, 1)),
                            ],
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'created by skolez',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            height: 1.1,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    // Story text area
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color:
                                AppTheme.backgroundColor.withValues(alpha: 0.8),
                            border: Border.all(
                              color:
                                  AppTheme.borderColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _displayedText,
                            style: TextStyle(
                              color: AppTheme.textColor,
                              fontSize: 16,
                              fontFamily: 'monospace',
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Progress indicator
                    if (_storyParts.isNotEmpty)
                      LinearProgressIndicator(
                        value: (_currentStoryIndex + 1) / _storyParts.length,
                        backgroundColor: AppTheme.surfaceColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                  ],
                ),
              ),

              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
              ),
              // Skip button
              if (_showSkipButton)
                Positioned(
                  top: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    onPressed: _skipTyping,
                    icon: Icon(
                      _isTyping ? Icons.fast_forward : Icons.skip_next,
                      color: AppTheme.textColor,
                    ),
                    label: Text(
                      _isTyping ? 'SKIP' : 'NEXT',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.backgroundColor,
                      foregroundColor: AppTheme.textColor,
                      side: BorderSide(
                        color: AppTheme.borderColor,
                        width: AppTheme.borderWidth,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadius),
                      ),
                    ),
                  ),
                ),

              // Tap anywhere to continue hint
              if (!_isTyping && _currentStoryIndex < _storyParts.length - 1)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Tap anywhere to continue...',
                      style: TextStyle(
                        color: AppTheme.textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
