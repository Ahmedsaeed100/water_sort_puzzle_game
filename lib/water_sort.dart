import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water_sort_puzzle_game/Getx/animatedwater_sort_controller.dart';
import 'package:water_sort_puzzle_game/Getx/liquid_animation_controller.dart';
import 'package:water_sort_puzzle_game/Getx/water_sort_controller.dart';

// Animated version of the water sort game
class AnimatedWaterSortGame extends StatelessWidget {
  const AnimatedWaterSortGame({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    final controller = Get.put(WaterSortController());
    // Initialize animation extension
    controller.initializeAnimation();
    final animController = Get.find<LiquidAnimationController>();

    // Use MediaQuery to make sizing responsive
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen =
        screenSize.width < 360 || screenSize.height < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Sort Puzzle'),
        elevation: 4,
        backgroundColor: Colors.deepPurple,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade800,
                Colors.deepPurple.shade600,
                Colors.blue.shade900,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              children: [
                // Score panel with fancy styling
                Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.swipe, color: Colors.white),
                      const SizedBox(width: 8),
                      Obx(
                        () => Text(
                          'Moves: ${controller.moves.value}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Obx(
                      () =>
                          controller.gameWon.value
                              ? _buildWinScreen(controller, isSmallScreen)
                              : Stack(
                                children: [
                                  _buildGameBoard(
                                    controller,
                                    isSmallScreen,
                                    animController,
                                  ),
                                  if (animController.isAnimating.value)
                                    AnimatedBuilder(
                                      animation:
                                          animController.animationController,
                                      builder: (context, child) {
                                        return _buildAnimatedLiquid(
                                          animController,
                                          isSmallScreen,
                                        );
                                      },
                                    ),
                                ],
                              ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.initializeGame(),
        backgroundColor: Colors.amber,
        child: const Icon(Icons.refresh, color: Colors.deepPurple),
      ),
    );
  }

  Widget _buildWinScreen(WaterSortController controller, bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Trophy icon with animation
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Icon(
                  Icons.emoji_events,
                  size: isSmallScreen ? 60 : 80,
                  color: Colors.amber,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Puzzle Solved!',
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 30,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              'You solved it in ${controller.moves.value} moves',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => controller.initializeGame(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 30,
                vertical: isSmallScreen ? 12 : 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_arrow, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Play Again',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameBoard(
    WaterSortController controller,
    bool isSmallScreen,
    LiquidAnimationController animController,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate tube dimensions based on available space
        double maxWidth = constraints.maxWidth;
        double maxHeight = constraints.maxHeight;
        double availableWidth = maxWidth - 20; // Account for some padding

        // Reduce segment height based on screen size
        double segmentHeight = isSmallScreen ? 20.0 : 25.0;
        double tubeHeight = controller.maxSegments * segmentHeight;
        double baseHeight = isSmallScreen ? 8.0 : 10.0;

        // Calculate maximum tube width to ensure it fits vertically
        double totalVerticalSpace = maxHeight - 20; // Account for some padding
        double maxAllowedTubeHeight =
            totalVerticalSpace / 1.1; // Add some margin

        // If tubes won't fit vertically, further reduce the size
        if (tubeHeight + baseHeight > maxAllowedTubeHeight) {
          double scale = maxAllowedTubeHeight / (tubeHeight + baseHeight);
          segmentHeight *= scale;
          tubeHeight = controller.maxSegments * segmentHeight;
          baseHeight *= scale;
        }

        return Obx(() {
          // Store positions of tubes for animation
          List<Offset> tubePositions = List.filled(
            controller.tubes.length,
            Offset.zero,
          );

          // If we have too many tubes, use a wrapped layout
          if (controller.tubes.length > 4) {
            // Calculate how many tubes can fit in a row
            int tubesPerRow =
                (availableWidth / (isSmallScreen ? 60 : 70)).floor();
            tubesPerRow = max(1, min(tubesPerRow, controller.tubes.length));

            // Calculate number of rows needed
            int numRows = (controller.tubes.length / tubesPerRow).ceil();

            // Calculate tube width based on tubes per row
            double tubeWidth = (availableWidth / tubesPerRow) - 8;
            tubeWidth = min(
              tubeWidth,
              isSmallScreen ? 50.0 : 60.0,
            ); // Cap the max width

            // Create rows of tubes
            List<Widget> rows = [];
            for (int row = 0; row < numRows; row++) {
              int startIndex = row * tubesPerRow;
              int endIndex = min(
                (row + 1) * tubesPerRow,
                controller.tubes.length,
              );

              List<Widget> rowTubes = [];
              for (int i = startIndex; i < endIndex; i++) {
                rowTubes.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Record the position for animation purposes
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          RenderBox? box =
                              context.findRenderObject() as RenderBox?;
                          if (box != null) {
                            Offset position = box.localToGlobal(
                              Offset(tubeWidth / 2, 0),
                            );
                            tubePositions[i] = position;
                          }
                        });

                        return _buildTube(
                          controller,
                          i,
                          tubeWidth,
                          segmentHeight,
                          baseHeight,
                          () {
                            _onTubeTapped(
                              controller,
                              i,
                              tubePositions,
                              animController,
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              }

              rows.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: rowTubes,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(mainAxisSize: MainAxisSize.min, children: rows),
              ),
            );
          } else {
            // Original layout for few tubes
            double tubeWidth = (availableWidth / controller.tubes.length) - 8;
            tubeWidth = min(
              tubeWidth,
              isSmallScreen ? 50.0 : 60.0,
            ); // Cap the max width

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(controller.tubes.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Record the position for animation purposes
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            RenderBox? box =
                                context.findRenderObject() as RenderBox?;
                            if (box != null) {
                              Offset position = box.localToGlobal(
                                Offset(tubeWidth / 2, 0),
                              );
                              tubePositions[index] = position;
                            }
                          });

                          return _buildTube(
                            controller,
                            index,
                            tubeWidth,
                            segmentHeight,
                            baseHeight,
                            () {
                              _onTubeTapped(
                                controller,
                                index,
                                tubePositions,
                                animController,
                              );
                            },
                          );
                        },
                      ),
                    );
                  }),
                ),
              ),
            );
          }
        });
      },
    );
  }

  void _onTubeTapped(
    WaterSortController controller,
    int index,
    List<Offset> tubePositions,
    LiquidAnimationController animController,
  ) {
    if (controller.gameWon.value || animController.isAnimating.value) return;

    if (controller.selectedTubeIndex.value == null) {
      // If no tube is selected, select this one if it's not empty
      if (controller.tubes[index].isNotEmpty) {
        controller.selectedTubeIndex.value = index;

        // Add selection animation
        _playSelectionAnimation(index);
      }
    } else {
      // If this is the already selected tube, deselect it
      if (controller.selectedTubeIndex.value == index) {
        controller.selectedTubeIndex.value = null;
      } else {
        // Try to pour from selected tube to this one
        controller.animatedPourWater(
          controller.selectedTubeIndex.value!,
          index,
          tubePositions,
        );
      }
    }
  }

  void _playSelectionAnimation(int index) {
    // You could add a more elaborate selection animation here
  }

  Widget _buildTube(
    WaterSortController controller,
    int tubeIndex,
    double width,
    double segmentHeight,
    double baseHeight,
    VoidCallback onTap,
  ) {
    // Calculate the exact height needed
    double tubeHeight = controller.maxSegments * segmentHeight;
    double totalHeight = tubeHeight + baseHeight + 4.0;

    return Obx(() {
      bool isSelected = controller.selectedTubeIndex.value == tubeIndex;

      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              isSelected
                  ? Matrix4.translationValues(0, -4, 0)
                  : Matrix4.identity(),
          width: width + 14,
          height: totalHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Glass tube effect with reflection
              Stack(
                children: [
                  // Main tube
                  Container(
                    width: width,
                    height: tubeHeight,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color:
                            isSelected
                                ? Colors.amber
                                : Colors.white.withOpacity(0.7),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ]
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: List.generate(
                        controller.tubes[tubeIndex].length,
                        (segmentIndex) {
                          return _buildLiquidSegment(
                            controller.tubes[tubeIndex][segmentIndex],
                            width,
                            segmentHeight,
                            segmentIndex ==
                                controller.tubes[tubeIndex].length - 1,
                          );
                        },
                      ),
                    ),
                  ),

                  // Glass reflection effect
                  Positioned(
                    left: width * 0.1,
                    top: 0,
                    bottom: 0,
                    width: width * 0.15,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Tube base with shadow effect
              Container(
                height: baseHeight,
                width: width + 14,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade600, Colors.grey.shade800],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: width * 0.7,
                    height: 2,
                    color: Colors.grey.shade900.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLiquidSegment(
    Color color,
    double width,
    double height,
    bool isTopSegment,
  ) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            isTopSegment
                ? const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                )
                : null,
        boxShadow:
            isTopSegment
                ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ]
                : null,
      ),
      child: Stack(
        children: [
          // Bubble effect for liquid
          if (isTopSegment)
            Positioned.fill(
              child: CustomPaint(painter: BubblePainter(color: color)),
            ),

          // Highlight/reflection effect
          Positioned(
            top: 0,
            left: width * 0.3,
            right: width * 0.3,
            height: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLiquid(
    LiquidAnimationController controller,
    bool isSmallScreen,
  ) {
    if (controller.pathAnimation == null) return const SizedBox.shrink();

    // Calculate the current position on the path
    final double pathValue = controller.pathAnimation!.value;
    final double liquidValue = controller.liquidLevelAnimation?.value ?? 0.0;

    // Get the current position based on the animation value
    Offset currentPosition = Offset.zero;
    if (controller.animationPath.isNotEmpty) {
      int index = (pathValue * (controller.animationPath.length - 1)).floor();
      int nextIndex = min(index + 1, controller.animationPath.length - 1);
      double localValue =
          pathValue * (controller.animationPath.length - 1) - index;

      currentPosition =
          Offset.lerp(
            controller.animationPath[index],
            controller.animationPath[nextIndex],
            localValue,
          ) ??
          Offset.zero;
    }

    // Size of the animated liquid drop
    double dropSize = isSmallScreen ? 15.0 : 20.0;

    return Positioned(
      left: currentPosition.dx - (dropSize / 2),
      top: currentPosition.dy - (dropSize / 2),
      child: Container(
        width: dropSize,
        height: dropSize * (1.0 + liquidValue * 0.5), // Stretch as it moves
        decoration: BoxDecoration(
          color: controller.animatedColor.value,
          borderRadius: BorderRadius.circular(dropSize / 2),
          boxShadow: [
            BoxShadow(
              color: controller.animatedColor.value.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        // Add a shine effect
        child: Stack(
          children: [
            Positioned(
              top: dropSize * 0.2,
              left: dropSize * 0.3,
              width: dropSize * 0.4,
              height: dropSize * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for bubble effect
class BubblePainter extends CustomPainter {
  final Color color;
  final random = Random();

  BubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Create a few small bubbles
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.2)
          ..style = PaintingStyle.fill;

    // Draw 1-3 random bubbles
    int bubbleCount = 1 + random.nextInt(2);
    for (int i = 0; i < bubbleCount; i++) {
      double bubbleSize = 1.0 + random.nextDouble() * 1.5;
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * (size.height / 2);
      canvas.drawCircle(Offset(x, y), bubbleSize, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Usage:
// Replace WaterSortGame with AnimatedWaterSortGame in your app
