import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/game_config.dart';
import '../providers/game_state_notifier.dart';
import '../services/question_service.dart';
import '../theme/app_colors.dart';

/// Loading screen — pulsing wordmark, question fetch, error retry (UI-003).
class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ─────────────────────────────────────────────────────────────

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseOpacity;
  late final Animation<double> _pulseScale;

  // ── HTTP client (owned, closed on dispose) ───────────────────────────────

  final http.Client _client = http.Client();

  // ── State ─────────────────────────────────────────────────────────────────

  bool _fetching = false;
  bool _cancelled = false;
  String? _error;

  // ── Entry fade ────────────────────────────────────────────────────────────

  double _entryOpacity = 0;

  @override
  void initState() {
    super.initState();

    // Pulse: opacity 1→0.6→1, scale 1→0.98→1, 2s loop.
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseOpacity = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Fade in.
    Future.microtask(() {
      if (mounted) setState(() => _entryOpacity = 1);
    });

    _fetchQuestions();
  }

  @override
  void dispose() {
    _cancelled = true;
    _client.close();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> _fetchQuestions() async {
    if (_fetching) return;
    setState(() {
      _fetching = true;
      _error = null;
    });

    final config = _gameConfig;
    if (config == null) {
      setState(() {
        _fetching = false;
        _error = 'Missing game configuration.';
      });
      return;
    }

    try {
      final questions =
          await QuestionService(client: _client).fetchQuestions(config);

      if (_cancelled || !mounted) return;

      // Initialise game state before navigating.
      ref.read(gameStateProvider.notifier).initGame(
            questions,
            topic: config.topic,
            difficulty: config.difficulty,
          );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/game', arguments: questions);
    } catch (e) {
      if (_cancelled || !mounted) return;
      _pulseCtrl.stop();
      setState(() {
        _fetching = false;
        _error = e.toString();
      });
    }
  }

  GameConfig? get _gameConfig {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is GameConfig) return args;
    return null;
  }

  void _cancel() {
    _cancelled = true;
    Navigator.pop(context);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: AnimatedOpacity(
          opacity: _entryOpacity,
          duration: const Duration(milliseconds: 300),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _error != null ? _buildError() : _buildLoading(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsing wordmark.
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            return Opacity(
              opacity: _pulseOpacity.value,
              child: Transform.scale(
                scale: _pulseScale.value,
                child: child,
              ),
            );
          },
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Triv',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'ex',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Subtitle.
        const Text(
          'Generating questions…',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 48),

        // Cancel.
        GestureDetector(
          onTap: _cancel,
          child: const SizedBox(
            height: 48,
            child: Center(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wordmark (static).
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Triv',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: 'ex',
                style: TextStyle(
                  color: AppColors.teal,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Error message.
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.red,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 32),

        // Try Again.
        GestureDetector(
          onTap: () {
            _cancelled = false;
            _pulseCtrl.repeat(reverse: true);
            _fetchQuestions();
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'Try Again',
              style: TextStyle(
                color: AppColors.foreground,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cancel.
        GestureDetector(
          onTap: _cancel,
          child: const SizedBox(
            height: 48,
            child: Center(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
