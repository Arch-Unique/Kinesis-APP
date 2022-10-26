// import 'package:control_pad/views/joystick_view.dart';
// import 'package:control_pad/views/pad_button_view.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:roborock/vacmap.dart';
import 'package:roborock/vacpainter.dart';
import 'package:web_socket_channel/io.dart';
//import 'package:flutter_processing/flutter_processing.dart';
// import 'package:roborock/p5rev/p5.dart';

// import 'package:roborock/vacmap.dart';

class DpadPage extends StatefulWidget {
  final bool vacOn;
  DpadPage(this.vacOn);
  @override
  _DpadPageState createState() => _DpadPageState();
}

class _DpadPageState extends State<DpadPage> with TickerProviderStateMixin {
  bool isOn = true;
  double speedVal = 50;
  Offset zoneStart, zoneEnd, spotStart;
  bool isSpot = false, isZone = false, isMap = false;

  Vacmap vmap;
  VacPainter vp = VacPainter();
  //0 - clean
  //1 - map
  //2 - spot
  //3 - zone
  //4 - isfree
  int curState = 4;

  //Duration duration = const Duration(seconds: 1);

  //AnimationController _controller;
  // late PAnimator animator;
  IOWebSocketChannel _channel;

  @override
  void initState() {
    isOn = widget.vacOn;
    vp.setSwitch(isOn);

    //get isOn from VAC and set real value
    try {
      _channel = IOWebSocketChannel.connect("ws://192.168.4.1/ws");
      _channel.stream.listen(
        (event) {
          setState(() {
            vp.data = event;
          });
        },
        onDone: () => print("Done"),
        onError: (error) => print(error),
      );
    } catch (_) {
      print("Error connecting");
    }
    super.initState();
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    double padSize = w / 1.5;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: GestureDetector(
          onTap: () async {
            vp.removeMap();
          },
          child: Text(
            "Cleaning",
            style: TextStyle(color: Colors.black),
          ),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_outlined),
            color: Colors.black,
            onPressed: () {
              Navigator.of(context).pop(isOn);
            }),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${vp.getPercentClean()}%',
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
          )
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(width: 0.0, color: Colors.grey)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FlatButton(
                  onPressed: isMyState(2)
                      ? () {
                          setState(() {
                            // isOn = !isOn;
                            // vmap.toggleSketch();
                            if (curState == 4) {
                              curState = 2;
                              isSpot = true;
                              isZone = false;
                              isMap = false;
                              vp.isZoning = false;
                              vp.isMapping = false;
                              _channel.sink.add("spot");
                            } else {
                              curState = 4;
                              isSpot = false;
                              vp.isSpotting = false;
                              _channel.sink.add("%%");
                            }
                          });
                        }
                      : null,
                  disabledColor: Colors.grey.withOpacity(0.1),
                  disabledTextColor: Colors.grey,
                  child: Text(isMyState(2, true) ? "Spot" : "Stop",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  color: isMyState(2, true)
                      ? Colors.yellowAccent.withOpacity(0.35)
                      : Colors.redAccent.withOpacity(0.35),
                ),
                FlatButton(
                    onPressed: isMyState(3)
                        ? () {
                            setState(() {
                              //vmap.resetSketch();
                              if (curState == 4) {
                                curState = 3;
                                isZone = true;
                                isSpot = false;
                                isMap = false;
                                vp.isSpotting = false;
                                vp.isMapping = false;
                                _channel.sink.add("zone");
                              } else {
                                curState = 4;
                                isZone = false;
                                vp.isZoning = false;
                                _channel.sink.add("%%");
                              }
                            });
                          }
                        : null,
                    disabledColor: Colors.grey.withOpacity(0.1),
                    disabledTextColor: Colors.grey,
                    child: Text(isMyState(3, true) ? "Zone" : "Stop",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    color: isMyState(3, true)
                        ? Colors.grey.withOpacity(0.35)
                        : Colors.redAccent.withOpacity(0.35)),
              ],
            ),
            Spacer(),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0XFF5C9ECD).withOpacity(0.35),
                      Color(0XFFA2A4E3).withOpacity(0.25),
                      Color(0XFF4C53D7).withOpacity(0.15)
                    ]),
              ),
              height: h * 0.5,
              width: double.maxFinite,
              child: Center(
                  child: GestureDetector(
                onTapDown: (TapDownDetails details) {
                  setState(() {
                    if (isSpot) {
                      final box = context.findRenderObject() as RenderBox;
                      spotStart = box.globalToLocal(details.localPosition);
                      log(spotStart.toString());
                    }
                  });
                },
                onTapUp: (TapUpDetails details) {
                  setState(() {
                    if (isSpot) {
                      vp.resetSpotMap();
                      vp.c = spotStart;
                      vp.isSpotting = true;
                      List<int> rc = blockPosOffset(vp.c);
                      _channel.sink.add(
                          "spot%" + rc[0].toString() + "%" + rc[1].toString());
                    }
                  });
                },
                onPanStart: (DragStartDetails details) {
                  setState(() {
                    if (isZone) {
                      final box = context.findRenderObject() as RenderBox;
                      zoneStart = box.globalToLocal(details.localPosition);
                      vp.b = zoneStart;
                      log(zoneStart.toString());
                    }
                  });
                },
                onPanUpdate: (DragUpdateDetails details) {
                  setState(() {
                    if (isZone) {
                      final box = context.findRenderObject() as RenderBox;
                      zoneEnd = box.globalToLocal(details.localPosition);
                      vp.e = zoneEnd;
                      log(zoneEnd.toString());
                    }
                  });
                },
                onPanEnd: (DragEndDetails details) {
                  setState(() {
                    if (isZone && zoneStart != null && zoneEnd != null) {
                      vp.isZoning = true;
                      vp.saveMap();
                      zoneStart = null;
                      zoneEnd = null;
                    }
                  });
                },
                child: Container(
                  height: 350,
                  width: 350,
                  child: CustomPaint(
                    painter: Vacmap(vp),
                    size: Size.square(350),
                  ),
                ),
              )),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FlatButton(
                  onPressed: isMyState(0)
                      ? () {
                          setState(() {
                            isOn = !isOn;
                            vp.toggleSketch();
                            _channel.sink.add("clean");
                            if (curState == 4) {
                              curState = 0;
                            } else {
                              curState = 4;
                            }
                          });
                        }
                      : null,
                  child: Text(isOn ? "Stop" : "Clean",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  disabledColor: Colors.grey.withOpacity(0.1),
                  disabledTextColor: Colors.grey,
                  color: isOn
                      ? Colors.redAccent.withOpacity(0.35)
                      : Colors.lightGreenAccent.withOpacity(0.35),
                ),
                FlatButton(
                    onPressed: isMyState(1)
                        ? () {
                            setState(() {
                              //vmap.resetSketch();
                              if (curState == 4) {
                                curState = 1;
                                isMap = true;
                                isZone = false;
                                isSpot = false;
                                vp.isSpotting = false;
                                vp.isZoning = false;
                                vp.isMapping = true;
                                _channel.sink.add("map");
                              } else {
                                curState = 4;
                                isMap = false;
                                vp.isMapping = false;
                                _channel.sink.add("%%");
                              }
                            });
                          }
                        : null,
                    disabledColor: Colors.grey.withOpacity(0.1),
                    disabledTextColor: Colors.grey,
                    child: Text(isMyState(1, true) ? "Map" : "Stop",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    color: isMyState(1, true)
                        ? Color(0XFF4C53D7).withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.35)),
              ],
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Speed",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Slider(
              value: speedVal,
              max: 100,
              min: 0,
              divisions: 10,
              label: "$speedVal",
              onChanged: (value) {
                setState(() {
                  speedVal = value;
                  vp.setSpeed(speedVal.toInt());
                  _channel.sink.add("changespeed%${speedVal.toInt()}");
                });
              },
            ),
            Text("$speedVal"),
            SizedBox(
              height: 16,
            ),
          ],
        ),
      ),
    );
  }

  bool isMyState(int a, [bool isMe = false]) {
    if (isMe) {
      if (curState == a) {
        return false;
      } else {
        return true;
      }
    }
    return curState == a || curState == 4;
  }
}
