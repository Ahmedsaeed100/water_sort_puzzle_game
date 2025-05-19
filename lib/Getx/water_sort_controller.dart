import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controller to manage game state
class WaterSortController extends GetxController {
  // Each tube is an array of colors
  final tubes = <List<Color>>[].obs;
  final selectedTubeIndex = Rx<int?>(null);
  final maxSegments = 4; // Maximum segments per tube
  final moves = 0.obs;
  final gameWon = false.obs;

  // Available colors for the water segments
  final List<Color> availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
  ];

  @override
  void onInit() {
    super.onInit();
    initializeGame();
  }

  void initializeGame() {
    // Let's create a level with 5 tubes filled with color segments
    // and 2 empty tubes
    int numColors = 4; // Using 4 colors
    int numTubes = numColors + 2; // Add 2 empty tubes

    // Clear any existing tubes
    tubes.clear();
    for (int i = 0; i < numTubes; i++) {
      tubes.add(<Color>[]);
    }

    // Create segments for each color
    List<Color> allSegments = [];
    for (int i = 0; i < numColors; i++) {
      for (int j = 0; j < maxSegments; j++) {
        allSegments.add(availableColors[i]);
      }
    }

    // Shuffle the segments
    allSegments.shuffle();

    // Distribute segments to the first numColors tubes
    for (int i = 0; i < allSegments.length; i++) {
      int tubeIndex = i ~/ maxSegments;
      tubes[tubeIndex].add(allSegments[i]);
    }

    // Use update to ensure the tubes list gets refreshed
    tubes.refresh();
    selectedTubeIndex.value = null;
    moves.value = 0;
    gameWon.value = false;
  }

  bool canPour(int fromTube, int toTube) {
    // Check if we can pour from one tube to another
    if (tubes[fromTube].isEmpty) return false;
    if (tubes[toTube].length >= maxSegments) return false;

    Color topColor = tubes[fromTube].last;
    return tubes[toTube].isEmpty || tubes[toTube].last == topColor;
  }

  void pourWater(int fromTube, int toTube) {
    if (!canPour(fromTube, toTube)) return;

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

  void checkForWin() {
    bool won = true;
    for (var tube in tubes) {
      if (tube.isEmpty) continue;
      if (tube.length != maxSegments) {
        won = false;
        break;
      }

      Color firstColor = tube.first;
      for (var color in tube) {
        if (color != firstColor) {
          won = false;
          break;
        }
      }

      if (!won) break;
    }

    gameWon.value = won;
  }

  void tubeTapped(int index) {
    if (gameWon.value) return;

    if (selectedTubeIndex.value == null) {
      // If no tube is selected, select this one if it's not empty
      if (tubes[index].isNotEmpty) {
        selectedTubeIndex.value = index;
      }
    } else {
      // If this is the already selected tube, deselect it
      if (selectedTubeIndex.value == index) {
        selectedTubeIndex.value = null;
      } else {
        // Try to pour from selected tube to this one
        pourWater(selectedTubeIndex.value!, index);
      }
    }
  }
}
