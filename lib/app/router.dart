import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/game_config.dart';
import '../screens/achievements_screen.dart';
import '../screens/game_screen.dart';
import '../screens/home_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/result_screen.dart';
import '../screens/topic_screen.dart';
import '../theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Application router — declarative, type-safe with GoRouter.
// ---------------------------------------------------------------------------

/// Top-level [GoRouter] instance consumed by [MaterialApp.router].
final goRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: '/topic',
      builder: (_, _) => const TopicScreen(),
    ),
    GoRoute(
      path: '/loading',
      builder: (_, state) => LoadingScreen(
        gameConfig: state.extra as GameConfig?,
      ),
    ),
    GoRoute(
      path: '/game',
      builder: (_, _) => const GameScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (_, _) => const ResultScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (_, _) => const AchievementsScreen(),
    ),
  ],
  errorBuilder: (_, state) => Scaffold(
    backgroundColor: AppColors.background,
    body: Center(
      child: Text(
        '404 — ${state.uri} not found',
        style: TextStyle(color: AppColors.red),
      ),
    ),
  ),
);
