import 'dart:math';

import 'package:flutter/material.dart';
import 'package:roborock/vacpainter.dart';

class Vacmap extends CustomPainter {
  double videoScale = 10;
  double dia = 30, centerX = 200, centerY = 75;
  Canvas myCanvas;

  int usF, usR, usL, usB, usDir, pusF, pusR, pusL, pusB;
  int angMove, angTurn;

// Number of columns and rows in our system
  int cols, rows;
  double vh, vw;

  Paint vacPaint = Paint();
  Paint mapPaint = Paint();
  Paint gridPaint = Paint();
  Paint spotPaint = Paint();
  Paint cleanPaint = Paint();
  Paint zonePaint = Paint();
  Paint spotPointPaint = Paint();

  VacPainter vp;

  Vacmap(VacPainter vp) {
    vacPaint..color = Colors.green;
    gridPaint
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    mapPaint
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    spotPaint
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    spotPointPaint
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    cleanPaint
      ..color = Colors.green
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    zonePaint..color = Colors.black;
    this.vp = vp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    myCanvas = canvas;
    vh = size.height;
    vw = size.width;
    if (!vp.isInit) {
      videoScale = vh / 40;
      cols = 40;
      rows = 40;
      dia = 3 * videoScale;
      setBackground();
    }

    draw();
  }

  @override
  bool shouldRepaint(Vacmap oldDelegate) {
    return true;
  }

  void draw() {
    if (vp.isDrawing) {
      setDirection();
      setMapBackground();
      myCanvas.drawCircle(Offset(centerX, centerY), dia / 2, vacPaint);
    } else {
      if (vp.isSpotting) {
        // vp.spottest();
        setSpotDirections();
        setSpotBackground();
        myCanvas.drawCircle(Offset(centerX, centerY), dia / 2, vacPaint);
        // setSpotDirection();
        // setSpotBackground();
        // spotMap = spotInitMap;
        // myCanvas.drawCircle(Offset(centerX, centerY), dia / 2, vacPaint);
        myCanvas.drawCircle(vp.c, dia / 2, spotPointPaint);
      }
      if (vp.isMapping) {
        setMapdirection();
        setMapBackground();
        myCanvas.drawCircle(Offset(centerX, centerY), dia / 2, vacPaint);
      }
    }
    if (vp.isZoning) {
      //myCanvas.drawRect(Rect.fromPoints(vp.b, vp.e), zonePaint);
      setZoneDirection();
      setZoneBackground();
    }
  }

  void setBackground() {
    for (int i = 0; i < cols; i++) {
      // Begin loop for rows
      for (int j = 0; j < rows; j++) {
        // Scaling up to draw a rectangle at (x,y)
        double x = i * videoScale;
        double y = j * videoScale;
        Rect myrect = Offset(x, y) & Size(videoScale, videoScale);
        myCanvas.drawRect(myrect, gridPaint);
      }
    }
  }

  void setMapBackground() {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        double x = i * videoScale;
        double y = j * videoScale;
        Rect myrect = Offset(x, y) & Size(videoScale, videoScale);
        myCanvas.drawRect(myrect, vp.avcMap[i][j] != 1 ? gridPaint : mapPaint);
      }
    }
  }

  void setCleanBackground() {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        double x = i * videoScale;
        double y = j * videoScale;
        Rect myrect = Offset(x, y) & Size(videoScale, videoScale);
        switch (vp.avcCleanMap[i][j]) {
          case 0:
            myCanvas.drawRect(myrect, gridPaint);
            break;
          case 1:
            myCanvas.drawRect(myrect, mapPaint);
            break;
          case 2:
            myCanvas.drawRect(myrect, cleanPaint);
            break;
          default:
        }
      }
    }
  }

  void setSpotBackground() {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        double x = i * videoScale;
        double y = j * videoScale;
        Rect myrect = Offset(x, y) & Size(videoScale, videoScale);
        switch (vp.avcSpotMap[i][j]) {
          case 0:
            myCanvas.drawRect(myrect, gridPaint);
            break;
          case 1:
            myCanvas.drawRect(myrect, mapPaint);
            break;
          case 3:
            myCanvas.drawRect(myrect, spotPaint);
            break;
          default:
        }
      }
    }
  }

  void setZoneDirection() {
    List<int> rcs = blockPosOffset(vp.b);
    List<int> rce = blockPosOffset(vp.e);
    int cx = rcs[0], cy = rcs[1], sx = rce[0], sy = rce[1];

    for (var j = min(cy, sy); j < max(cy, sy); j++) {
      for (int i = min(cx, sx); i <= max(cx, sx); i++) {
        setMap(i, j);
      }
    }
  }

  void setZoneBackground() {
    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        double x = i * videoScale;
        double y = j * videoScale;
        Rect myrect = Offset(x, y) & Size(videoScale, videoScale);
        switch (vp.avcMap[i][j]) {
          case 0:
            myCanvas.drawRect(myrect, gridPaint);
            break;
          case 1:
            myCanvas.drawRect(myrect, mapPaint);
            break;
          default:
        }
      }
    }
  }

  void resetSketch() {
    setBackground();
  }

  void setDirection() {
    List<String> myl = vp.data.split("%%");
    if (myl.length < 4 || vp.getPercentClean() > 99) {
      vp.saveCleanMap();
      return;
    }
    if (usF != null) {
      pusF = usF;
      pusL = usL;
      pusR = usR;
      pusB = usB;
    }
    usF = int.parse(myl[0]);
    usL = int.parse(myl[1]);
    usR = int.parse(myl[2]);
    usB = int.parse(myl[3]);

    angMove = int.parse(myl[4]);
    angTurn = int.parse(myl[5]);

    List<int> rc = blockPosUSS();
    List<double> xy = blockRPos(rc[0], rc[1]);
    centerX = xy[0];
    centerY = xy[1];

    if (isMoving()) {
      centerY = centerY - (vp.baseSpeed * -cos(rads(angTurn)));
      centerX = centerX - (vp.baseSpeed * -sin(rads(angTurn)));
      rc = blockPos(centerX, centerY);
    }
    vp.avcCleanMap[rc[0]][rc[1]] = 2;
  }

  void setMapdirection() {
    List<String> myl = vp.data.split("%%");
    if (myl.length < 4) {
      //mapping has finished
      vp.saveMap();
      // vp.isMapping = false;
    } else {
      usF = int.parse(myl[0]);
      usL = int.parse(myl[1]);
      usR = int.parse(myl[2]);
      usB = int.parse(myl[3]);

      angMove = int.parse(myl[4]);
      angTurn = int.parse(myl[5]);

      if (isMoving()) {
        centerY = centerY - (vp.baseSpeed * -cos(rads(angTurn)));
        centerX = centerX - (vp.baseSpeed * -sin(rads(angTurn)));
        List<int> rc = blockPos(centerX, centerY);
        delSpace(rc[0], rc[1], -2, usF);
        delSpace(rc[0], rc[1], usL, -2);
        delSpace(rc[0], rc[1], usR, -1);
        delSpace(rc[0], rc[1], -1, usB);
      }
    }
  }

  void setSpotDirections() {
    // List<String> myl = vp.data.split("%%");
    // usF = int.parse(myl[0]);
    // usL = int.parse(myl[1]);
    // usR = int.parse(myl[2]);
    // usB = int.parse(myl[3]);
    int cx, cy, sx, sy, maxX, minX, maxY, minY;
    List<int> rc = blockPos(centerX, centerY);
    cx = rc[0];
    cy = rc[1];
    List<int> src = blockPosOffset(vp.c);
    sx = src[0];
    sy = src[1];
    minX = min(cx, sx);
    maxX = max(cx, sx);
    minY = min(cy, sy);
    maxY = max(cy, sy);
    List<Loc> locs = [];
    Loc cs = Loc(cx, cy, sx, sy);
    List<List<int>> fastlocs = [];
    int fastcnt = 1600;
    int md = getMaxDistance(cs);
    // Loc(cx, 10, sx, 10);
    for (int i = 0; i < 40; i++) {
      if (vp.avcSpotMap[i][cy] != 1 && vp.avcSpotMap[i][sy] != 1) {
        if (isSpaceBtwPos(i, minY, maxY)) {
          locs.add(Loc(i, cy, i, sy));
        }
      }
    }
    if (locs.length != 0) {
      for (int i = 0; i < locs.length; i++) {
        Loc loc = locs[i];
        int minsx = min(sx, loc.a);
        int minsxx = max(sx, loc.a);
        int mincx = min(cx, loc.a);
        int mincxx = max(cx, loc.a);
        if (isSpaceBtwPosC(sy, minsx, minsxx) &&
            isSpaceBtwPosC(cy, mincx, mincxx)) {
          //finalLoc = loc;
          List<List<int>> g = checkFastestRoute(cs, loc);
          if (g.length >= md && g.length < fastcnt) {
            fastcnt = g.length;
            fastlocs = g;
          }
        }
      }
    }
    for (int i = 0; i < 40; i++) {
      if (vp.avcSpotMap[cx][i] != 1 && vp.avcSpotMap[sx][i] != 1) {
        if (isSpaceBtwPosC(i, minX, maxX)) {
          locs.add(Loc(cx, i, sx, i));
        }
      }
    }
    for (int i = 0; i < locs.length; i++) {
      Loc loc = locs[i];
      int minsy = min(sy, loc.b);
      int minsyy = max(sy, loc.b);
      int mincy = min(cy, loc.b);
      int mincyy = max(cy, loc.b);
      if (isSpaceBtwPos(sx, minsy, minsyy) &&
          isSpaceBtwPos(cx, mincy, mincyy)) {
        List<List<int>> g = checkFastestRoute(cs, loc);
        if (g.length >= md && g.length < fastcnt) {
          fastcnt = g.length;
          fastlocs = g;
        }
      }
    }
    // if (!isSpaceBtwPosC(cy, minX, maxX)) {
    //   locs.clear();
    //   fastcnt = 1600;

    // }
    if (fastlocs == []) return;
    setSpotList(fastlocs);
  }

  List<List<int>> checkFastestRoute(Loc locc, Loc locs) {
    List<List<int>> m = [];
    if (locs.y == locs.b && locs.a != locs.x) {
      int mincx = min(locs.a, locs.x);
      int maxcx = max(locs.a, locs.x);
      for (int j = mincx; j <= maxcx; j++) {
        m.add([j, locs.y]);
      }

      for (int i = min(locs.y, locc.y); i <= max(locs.y, locc.y); i++) {
        m.add([locs.x, i]);
      }

      for (int i = min(locs.y, locc.b); i <= max(locs.y, locc.b); i++) {
        m.add([locs.a, i]);
      }
    } else {
      //init mov VHV
      int mincy = min(locs.b, locs.y);
      int maxcy = max(locs.b, locs.y);

      for (int j = mincy; j <= maxcy; j++) {
        m.add([locs.x, j]);
      }

      for (int i = min(locs.x, locc.x); i <= max(locs.x, locc.x); i++) {
        m.add([i, locs.y]);
      }

      for (int i = min(locs.x, locc.a); i <= max(locs.x, locc.a); i++) {
        m.add([i, locs.b]);
      }
    }
    return m;
  }

  void setSpotList(List<List<int>> m) {
    for (int i = 0; i < m.length; i++) {
      setSpot(m[i][0], m[i][1]);
    }
  }

  int getMaxDistance(Loc locc) {
    return max((locc.x - locc.a).abs(), (locc.y - locc.b).abs());
  }

  String getPath(Loc locc, Loc locs) {
    String bm = "";
    //from start to start find
    bm += pHelper(locc.x, locc.y, locs.x, locs.y) + ',';

    //from start find to end find
    bm += pHelper(locs.x, locs.y, locs.a, locs.b) + ',';

    //from end find to end
    bm += pHelper(locs.a, locs.b, locc.a, locc.b);
    return bm;
  }

  String pHelper(int x, int y, int a, int b) {
    if (x == a && y != b) {
      return getPathDir(y, b, false);
    } else if (y == b && x != a) {
      return getPathDir(x, a, true);
    } else {
      return "-";
    }
  }

  String getPathDir(int start, int end, [bool isHoriz = true]) {
    int pathNum = (start - end).abs();
    if (isHoriz) {
      if (start < end) {
        return 'r$pathNum';
      } else if (start == end) {
        return '-';
      } else {
        return 'l$pathNum';
      }
    } else {
      if (start < end) {
        return 'b$pathNum';
      } else if (start == end) {
        return '-';
      } else {
        return 'f$pathNum';
      }
    }
  }

  void _setSpotBackgroundProps(Loc locc, Loc locs) {
    //init mov HVH
    if (locs.y == locs.b && locs.a != locs.x) {
      int mincx = min(locs.a, locs.x);
      int maxcx = max(locs.a, locs.x);
      for (int j = mincx; j <= maxcx; j++) {
        setSpot(j, locs.y);
      }

      for (int i = min(locs.y, locc.y); i <= max(locs.y, locc.y); i++) {
        setSpot(locs.x, i);
      }

      for (int i = min(locs.y, locc.b); i <= max(locs.y, locc.b); i++) {
        setSpot(locs.a, i);
      }
    } else {
      //init mov VHV
      int mincy = min(locs.b, locs.y);
      int maxcy = max(locs.b, locs.y);

      for (int j = mincy; j <= maxcy; j++) {
        setSpot(locs.x, j);
      }

      for (int i = min(locs.x, locc.x); i <= max(locs.x, locc.x); i++) {
        setSpot(i, locs.y);
      }

      for (int i = min(locs.x, locc.a); i <= max(locs.x, locc.a); i++) {
        setSpot(i, locs.b);
      }
    }
  }

  bool isSpaceBtwPos(int x, int a, int b) {
    List<int> myrow = List.from(getColSpot(x));
    return !myrow.sublist(a, b + 1).contains(1);
  }

  bool isSpaceBtwPosC(int y, int a, int b) {
    List<int> myrow = List.from(vp.avcSpotMap[y]);
    return !myrow.sublist(a, b + 1).contains(1);
  }

  // void setSpotDirection() {
  //   List<int> rc = blockPosOffset(vp.c);
  //   if (rc[0] - 1 > 0 && rc[0] + 1 < 40 && rc[1] - 1 > 0 && rc[1] + 1 < 40) {
  //     spotMap[rc[0]][rc[1] - 1] = 1;
  //     spotMap[rc[0]][rc[1]] = 1;
  //     spotMap[rc[0]][rc[1] + 1] = 1;
  //     spotMap[rc[0] - 1][rc[1]] = 1;
  //     spotMap[rc[0] + 1][rc[1]] = 1;
  //     spotMap[rc[0] - 1][rc[1] - 1] = 1;
  //     spotMap[rc[0] + 1][rc[1] + 1] = 1;
  //     spotMap[rc[0] - 1][rc[1] + 1] = 1;
  //     spotMap[rc[0] + 1][rc[1] - 1] = 1;
  //   }
  // }

  bool isMoving() {
    return angMove == 1;
  }

  double rads(int a) {
    return a * 0.0174533;
  }

  void delSpace(int r, int c, int rr, int cc) {
    if (rr < 0 && cc != c) {
      List<int> newmap = List.from(vp.avcMap[r]);
      if (rr == -1) {
        int x = c + cc;
        if (x > 39) {
          x = 39;
        }
        for (int i = c; i <= x; i++) {
          newmap[i] = 1;
        }
      } else if (rr == -2) {
        int x = c - cc;
        if (x < 0) {
          x = 0;
        }
        for (int i = c; i >= x; i--) {
          newmap[i] = 1;
        }
      }
      vp.avcMap[r] = newmap;
    } else if (cc < 0 && rr != r) {
      if (cc == -1) {
        int x = r + rr;
        if (x > 39) {
          x = 39;
        }
        for (int i = r; i <= x; i++) {
          setCol(c, i);
        }
      } else if (cc == -2) {
        int x = r - rr;
        if (x < 0) {
          x = 0;
        }
        for (int i = r; i >= x; i--) {
          setCol(c, i);
        }
      }
    }
  }

  void setCol(a, i) {
    setDefCol(a, i);
  }

  void setDefCol(a, i, {x = 1}) {
    List<int> myrow = List.from(vp.avcMap[i]);
    myrow[a] = x;
    vp.avcMap[i] = myrow;
  }

  void setSpot(int a, int b) {
    List<int> myrow = List.from(vp.avcSpotMap[a]);
    myrow[b] = 3;
    vp.avcSpotMap[a] = myrow;
  }

  void setMap(int a, int b) {
    List<int> myrow = List.from(vp.avcMap[a]);
    myrow[b] = 1;
    vp.avcMap[a] = myrow;
  }

  List<int> getCol(a) {
    List<int> mymap = List.generate(40, (index) => 0);
    for (int i = 0; i < 40; i++) {
      mymap[i] = vp.avcMap[i][a];
    }
    return mymap;
  }

  List<int> getColSpot(int a) {
    List<int> mymap = List.generate(40, (index) => 0);
    for (int i = 0; i < 40; i++) {
      mymap[i] = vp.avcSpotMap[i][a];
    }
    return mymap;
  }

  List<int> blockPosUSS() {
    int r, c;
    if (((usF - pusF).abs()) < 3 &&
        (usR - pusR).abs() < 3 &&
        (usL - pusL).abs() < 3 &&
        (usB - pusB).abs() < 3) {
      r = usF;
      c = usL;
    } else {
      r = usF > pusF ? usF : pusF;
      c = usL > pusL ? usL : pusL;
    }
    return [r, c];
  }
}

List<int> blockPos(double a, double b) {
  int r = (a * 0.114285714).round();
  int c = (b * 0.114285714).round();
  return [r, c];
}

List<int> blockPosOffset(Offset xy) {
  double a = xy.dx;
  double b = xy.dy;
  return blockPos(a, b);
}

List<double> blockRPos(int a, int b) {
  double x = a / 0.114285714;
  double y = b / 0.114285714;
  return [x, y];
}

class Loc {
  int x, y, a, b;
  Loc(this.x, this.y, this.a, this.b);
}
