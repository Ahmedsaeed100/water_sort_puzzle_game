import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water_sort_puzzle_game/Getx/liquid_animation_controller.dart';
import 'package:water_sort_puzzle_game/Getx/water_sort_controller.dart';

extension AnimatedWaterSortController on WaterSortController {
  void initializeAnimation() {
    // Get instance of the animation controller (create if doesn't exist)
    Get.put(LiquidAnimationController());
  }

  void animatedPourWater(int fromTube, int toTube, List<Offset> tubePositions) {
    if (!canPour(fromTube, toTube)) return;

    // Get animation controller
    final animController = Get.find<LiquidAnimationController>();
    if (animController.isAnimating.value) return;

    // Find how many segments of the same color can be poured
    Color topColor = tubes[fromTube].last;
    int count = 0;
    for (int i = tubes[fromTube].length - 1; i >= 0; i--) {
      if (tubes[fromTube][i] == topColor) {
        count++;
      } else {
        break;
      }
    }

    // Calculate how many can actually fit in the target tube
    int spaceInTarget = maxSegments - tubes[toTube].length;
    int toTransfer = min(count, spaceInTarget);

    // Create animation path with advanced curve
    // Get positions for the tubes (top center of each tube)
    final Offset fromPosition = tubePositions[fromTube];
    final Offset toPosition = tubePositions[toTube];

    // Calculate control points for a natural looking curved path
    // The liquid should arc up and then down in a natural way
    final double arcHeight = min(
      60.0,
      (fromPosition - toPosition).distance * 0.4,
    );
    final Offset middlePoint = Offset(
      (fromPosition.dx + toPosition.dx) / 2,
      min(fromPosition.dy, toPosition.dy) - arcHeight,
    );

    // Add some randomness to make it look more natural
    final random = Random();
    final double randomOffset = random.nextDouble() * 5.0;

    // Generate a smooth bezier curve path with more points
    List<Offset> path = [];

    // Initial lifting path (from tube up to start of pour)
    for (double t = 0; t <= 0.3; t += 0.02) {
      double normalizedT = t / 0.3;
      double x = fromPosition.dx;
      double y = fromPosition.dy - (normalizedT * 15); // Move upward slightly
      path.add(Offset(x, y));
    }

    // Main pouring path (curved arc from source to destination)
    for (double t = 0.0; t <= 1.0; t += 0.02) {
      // Quadratic bezier curve
      double x = _bezier(
        fromPosition.dx,
        middlePoint.dx + randomOffset,
        toPosition.dx,
        t,
      );
      double y = _bezier(
        fromPosition.dy - 15,
        middlePoint.dy - randomOffset,
        toPosition.dy,
        t,
      );

      // Add slight oscillation for more realism
      if (t > 0.3 && t < 0.7) {
        y += sin(t * 10) * 2.0;
      }

      path.add(Offset(x, y));
    }

    // Start animation
    animController.startPourAnimation(
      from: fromTube,
      to: toTube,
      color: topColor,
      path: path,
      segments: toTransfer,
      onComplete: () {
        // After animation completes, update the actual game state
        _completePour(fromTube, toTube, toTransfer);
      },
    );
  }

  // Helper for quadratic bezier curve calculation
  double _bezier(double p0, double p1, double p2, double t) {
    return (1 - t) * ((1 - t) * p0 + t * p1) + t * ((1 - t) * p1 + t * p2);
  }

  // Helper for cubic bezier curve calculation for more complex paths
  double _cubicBezier(double p0, double p1, double p2, double p3, double t) {
    double t2 = t * t;
    double t3 = t2 * t;
    return p0 * (1 - 3 * t + 3 * t2 - t3) +
        p1 * (3 * t - 6 * t2 + 3 * t3) +
        p2 * (3 * t2 - 3 * t3) +
        p3 * t3;
  }

  // Actual state update after animation
  void _completePour(int fromTube, int toTube, int toTransfer) {
    // Make copy of the tubes to modify
    final List<List<Color>> newTubes =
        tubes.map((tube) => List<Color>.from(tube)).toList();

    // Transfer the colors
    for (int i = 0; i < toTransfer; i++) {
      newTubes[toTube].add(newTubes[fromTube].removeLast());
    }

    // Update tubes with the new state
    for (int i = 0; i < tubes.length; i++) {
      tubes[i] = newTubes[i];
    }

    // Ensure GetX knows the tubes list has changed
    tubes.refresh();

    moves.value++;
    selectedTubeIndex.value = null;

    // Check if game is won
    checkForWin();
  }

  void playSelectionAnimation(int index) {
    final animController = Get.find<LiquidAnimationController>();
    if (!animController.isAnimating.value) {
      animController.startSelectionAnimation();
    }
  }
}
