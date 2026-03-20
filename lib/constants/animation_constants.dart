import 'package:flutter/animation.dart';

/// Named animation constants — replaces all Duration / Curve literals in UI.

/// Standard entry-animation duration (fade + slide).
const Duration kEntryDuration = Duration(milliseconds: 500);

/// Stagger delay between consecutive entry animations.
const Duration kEntryStagger = Duration(milliseconds: 100);

/// Quick reveal / slide transition.
const Duration kRevealSlide = Duration(milliseconds: 300);

/// Wordmark pulse loop period.
const Duration kWordmarkPulse = Duration(seconds: 2);

/// Game-timer countdown duration.
const Duration kTimerDuration = Duration(seconds: 15);

/// Pill / button state-change transition.
const Duration kButtonTransition = Duration(milliseconds: 200);

/// Tap-scale animation duration.
const Duration kTapScale = Duration(milliseconds: 80);

/// Topic-screen entry animation duration.
const Duration kTopicEntryDuration = Duration(milliseconds: 400);

/// Standard entry curve — smooth deceleration.
const Curve kEntryCurve = Curves.easeOut;

/// Spring-like curve for the reveal bottom sheet.
const Curve kSpringCurve = Curves.easeOutBack;

/// Symmetric ease for looping pulse animations.
const Curve kPulseCurve = Curves.easeInOut;
