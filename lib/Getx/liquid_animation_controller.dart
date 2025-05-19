import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiquidAnimationController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late AnimationController animationController;
  Animation<double>? pathAnimation;
  Animation<double>? liquidLevelAnimation;
  Animation<double>? selectionAnimation;
  Animation<double>? liquidFlowAnimation;
  Animation<double>? bubbleAnimation;

  final isAnimating = false.obs;
  final isSelected = false.obs;
  final fromTubeIndex = 0.obs;
  final toTubeIndex = 0.obs;
  final animatedColor = Rx<Color>(Colors.transparent);
  final animationPath = <Offset>[].obs;
  final segmentsToTransfer = 0.obs;

  // Drop properties for more realistic animation
  final dropSize = 20.0.obs;
  final dropStretch = 1.0.obs;
  final dropOpacity = 1.0.obs;

  // Bubble effects
  final List<Bubble> bubbles = <Bubble>[].obs;
  final Random random = Random();

  // Callback to be executed when animation completes
  Function? onAnimationComplete;

  @override
  void onInit() {
    super.onInit();
    animationController = AnimationController(
      duration: const Duration(
        milliseconds: 1200,
      ), // Slightly longer for more realistic effect
      vsync: this,
    );

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        isAnimating.value = false;
        if (onAnimationComplete != null) {
          onAnimationComplete!();
        }
      }
    });
  }

  void startSelectionAnimation() {
    if (isAnimating.value) return;

    selectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    isSelected.value = true;
    animationController.reset();
    animationController.forward();
  }

  void startPourAnimation({
    required int from,
    required int to,
    required Color color,
    required List<Offset> path,
    required int segments,
    required Function onComplete,
  }) {
    if (isAnimating.value) return;

    fromTubeIndex.value = from;
    toTubeIndex.value = to;
    animatedColor.value = color;
    animationPath.value = path;
    segmentsToTransfer.value = segments;
    onAnimationComplete = onComplete;

    // Create bubbles for animation
    bubbles.clear();
    for (int i = 0; i < 5 + random.nextInt(5); i++) {
      bubbles.add(
        Bubble(
          position: Offset(
            10 + random.nextDouble() * 10,
            5 + random.nextDouble() * 15,
          ),
          size: 1.0 + random.nextDouble() * 2.0,
          speed: 0.2 + random.nextDouble() * 0.3,
        ),
      );
    }

    // Path animation for the liquid drop
    pathAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.1, 0.7, curve: Curves.easeInOutCubic),
      ),
    );

    // Liquid stretching and flow animation
    liquidFlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Liquid level animation in the receiving tube
    liquidLevelAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.6, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Bubble animation
    bubbleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(0.7, 1.0, curve: Curves.linear),
      ),
    );

    isAnimating.value = true;
    animationController.reset();
    animationController.forward();
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}

class Bubble {
  Offset position;
  double size;
  double speed;

  Bubble({required this.position, required this.size, required this.speed});
}
