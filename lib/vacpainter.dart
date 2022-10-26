import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VacPainter {
  VacPainter(
      {this.isZoning = false,
      this.isSpotting = false,
      this.isMapping = false,
      this.isInit = false,
      this.isDrawing = true,
      this.data = "0%%0",
      this.baseSpeed = 0.207,
      this.e,
      this.c,
      this.b}) {
    initMap();
    initCleanMap();
  }
  Offset c, b, e;

  dynamic data;
  double baseSpeed;
  List<List<int>> avcMap = List<List<int>>.filled(40, List<int>.filled(40, 1)),
      avcCleanMap = List<List<int>>.filled(40, List<int>.filled(40, 1)),
      avcSpotMap = List<List<int>>.filled(40, List<int>.filled(40, 0));
  bool isInit, isDrawing, isSpotting, isZoning, isMapping;
  final double maxSpeed = 18.1125;

  void toggleSketch() {
    isDrawing = !isDrawing;
  }

  void setSwitch(bool b) {
    isDrawing = b;
  }

  void setSpeed(int a) {
    baseSpeed = 9.05625 + ((a / 100) * 9.05625);
  }

  void saveMap() async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString("AVCMAP", avcMap.toString());
    });
  }

  void removeMap() async {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove("AVCMAP");
    });
  }

  void resetSpotMap() {
    this.avcSpotMap = List.from(avcMap);
  }

  void spottest() {
    for (int i = 0; i < this.avcSpotMap.length; i++) {
      if (i > 10 && i < 30) {
        List<int> m = List.generate(40, (j) => j > 10 && j < 30 ? 1 : 0);
        this.avcSpotMap[i] = m;
      }
    }
  }

  void initMap() async {
    SharedPreferences.getInstance().then((prefs) {
      List<List<int>> vmap = <List<int>>[];
      if (!prefs.containsKey("AVCMAP")) {
        vmap = List<List<int>>.filled(40, List<int>.filled(40, 0));
      } else {
        String a = prefs.getString("AVCMAP");
        a = a.substring(2, a.length - 2);
        List<String> b = a.split("], [");
        for (int i = 0; i < b.length; i++) {
          List<int> vm =
              b[i].split(", ").map((e) => int.parse(e.trim())).toList();
          vmap.add(vm);
        }
      }
      this.avcMap = vmap;
    });
  }

  void saveCleanMap() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString("AVCCLEANMAP", avcCleanMap.toString());
    });
  }

  void initCleanMap() {
    SharedPreferences.getInstance().then((prefs) {
      List<List<int>> vmap = <List<int>>[];
      if (!prefs.containsKey("AVCCLEANMAP")) {
        vmap = List<List<int>>.filled(40, List<int>.filled(40, 1));
      } else {
        String a = prefs.getString("AVCCLEANMAP");
        a = a.substring(2, a.length - 2);
        List<String> b = a.split("], [");
        for (int i = 0; i < b.length; i++) {
          List<int> vm =
              b[i].split(", ").map((e) => int.parse(e.trim())).toList();
          vmap.add(vm);
        }
      }
      this.avcCleanMap = vmap;
    });
  }

  double getPercentClean() {
    int a = 0;
    int b = 0;
    for (int i = 0; i < 40; i++) {
      for (int j = 0; j < 40; j++) {
        if (avcMap[i][j] == 0) {
          if (avcCleanMap[i][j] == 2) {
            b++;
          }
          a++;
        }
      }
    }
    if (a == 0) a = 1;
    return (b / a) * 100;
  }
}
