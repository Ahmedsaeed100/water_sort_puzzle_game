
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:water_sort_puzzle_game/water_sort.dart';

void main() {
  runApp(
    GetMaterialApp(
      title: 'Water Sort Puzzle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AnimatedWaterSortGame(),
    ),
  );
}
