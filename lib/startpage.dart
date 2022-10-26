import 'dart:async';

import 'package:flutter/material.dart';
import 'package:model_viewer/model_viewer.dart';
import 'package:roborock/dpad.dart';
import 'package:roborock/modepage.dart';
import 'package:http/http.dart' as http;

class StartPage extends StatefulWidget {
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool isOn = false;
  int batteryPercent = 100;
  dynamic myBatteryTimer;

  @override
  void initState() {
    myBatteryTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        Uri uri = Uri.http("192.168.4.1", "/checkBattery");
        http.get(uri).then((value) {
          int bpl = int.parse(value.body);
          if (!bpl.isNaN) {
            batteryPercent = bpl;
          }
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 4 * h / 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0XFF5C9ECD).withOpacity(0.35),
                      Color(0XFFA2A4E3).withOpacity(0.25),
                      Color(0XFF4C53D7).withOpacity(0.15)
                    ]),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40)),
              ),
              child: Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Text(
                      "Kinesis",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontFamily: "Ethnocentric",
                        fontSize: 35,
                      ),
                    ),
                    Text(
                      "Robo Vac",
                      style: TextStyle(
                        fontSize: 35,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    // Expanded(child: Vac3d()),
                    Expanded(
                        child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ModelViewer(
                        src: "asset/images/vac.glb",
                        backgroundColor: Colors.lightBlueAccent,
                        alt: "my vacuum cleaner",
                        ar: true,
                        autoRotate: true,
                        cameraControls: true,
                      ),
                    )),
                    SizedBox(
                      height: 10,
                    ),
                    HomeButton(
                      iconData: Icons.battery_charging_full_rounded,
                      value: batteryPercent,
                      desc: "Battery Level",
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) => ModePage()));
                      },
                      child: BottomBtn(Icons.wifi_rounded, "Connection")),
                  GestureDetector(
                    onTap: () {
                      Uri uri = Uri.http("192.168.4.1", "/toggleClean");
                      http.get(uri).then((value) {
                        if (value.body == "success") {
                          setState(() {
                            isOn = !isOn;
                          });
                          //isInternet = 2;
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text("Failed")));
                        }
                      }).catchError((err) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("No Network Connection : $err")));
                      });
                    },
                    child: Material(
                      shape: CircleBorder(),
                      elevation: isOn ? 5 : 0,
                      shadowColor: isOn
                          ? Color(0xFF0B14E7)
                          : Colors.black.withOpacity(1),
                      color: isOn
                          ? Color(0xFF0B14E7)
                          : Colors.grey.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Icon(
                          Icons.power_settings_new_rounded,
                          color: isOn ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                      onTap: () async {
                        final res = await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    DpadPage(isOn)));
                        setState(() {
                          isOn = res;
                        });
                      },
                      child: BottomBtn(Icons.dashboard, "Mode"))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class HomeButton extends StatefulWidget {
  final String desc;
  final int value;
  final IconData iconData;
  HomeButton({this.desc, this.iconData, this.value});

  @override
  _HomeButtonState createState() => _HomeButtonState();
}

class _HomeButtonState extends State<HomeButton> {
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(context).size.width;
    return Container(
      width: w - 32,
      height: 64,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              height: 64,
              width: (w - 32) * ((widget.value < 1 ? 1 : widget.value) / 100),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.lightBlueAccent, Colors.blueAccent]),
              ),
            ),
          ),
          Container(
            height: 64,
            width: (w - 32),
            child: Row(
              children: [
                SizedBox(
                  width: 10,
                ),
                Icon(
                  widget.iconData,
                  color: Colors.black,
                  size: 40,
                ),
                Spacer(),
                Text(
                  "${widget.value}%",
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontFamily: "Ethnocentric"),
                ),
                SizedBox(
                  width: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BottomBtn extends StatelessWidget {
  final IconData iconData;
  final String stype;
  BottomBtn(this.iconData, this.stype);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                    width: 0.5, color: Colors.grey.withOpacity(0.1))),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                iconData,
                color: Color(0xFF0B14E7),
              ),
            ),
          ),
          Text(stype)
        ],
      ),
    );
  }
}
