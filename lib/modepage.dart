import 'package:flutter/material.dart';
import 'package:open_settings/open_settings.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;

class ModePage extends StatefulWidget {
  const ModePage({Key key}) : super(key: key);

  @override
  _ModePageState createState() => _ModePageState();
}

class _ModePageState extends State<ModePage> with WidgetsBindingObserver {
  bool isConnected = false;
  int isInternet = 0;
  TextEditingController cont1, cont2;

  void setConnected(bool a) {
    setState(() {
      isConnected = a;
    });
  }

  void setInternet(int a) {
    setState(() {
      isInternet = a;
    });
  }

  @override
  void initState() {
    super.initState();
    print("not connected");
    WidgetsBinding.instance.addObserver(this);
    WiFiForIoTPlugin.isConnected().then((value) {
      setConnected(value);
    });
    cont1 = TextEditingController();
    cont2 = TextEditingController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WiFiForIoTPlugin.isConnected().then((value) {
        setConnected(value);
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Connection",
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
            icon: Icon(Icons.arrow_back_outlined),
            color: Colors.black,
            onPressed: () {
              Navigator.of(context).pop();
            }),
        backgroundColor: Colors.white,
        elevation: 0,
        shape: Border(bottom: BorderSide(width: 0.0, color: Colors.grey)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(!isConnected
                  ? "Please make sure you're connected to \nSSID: KinesisRoboVAC \nPassword: qwerty12"
                  : "You're connected"),
              SizedBox(
                height: 16,
              ),
              Icon(
                isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                size: 200,
                color: isConnected ? Colors.green : Colors.black,
              ),
              SizedBox(
                height: 16,
              ),
              ElevatedButton(
                onPressed: () {
                  if (isConnected) {
                    WiFiForIoTPlugin.disconnect();
                    setConnected(false);
                    //isConnected = false;
                  } else {
                    OpenSettings.openWIFISetting();
                  }
                },
                child: Text(isConnected ? "Disconnect" : "Connect"),
              ),
              SizedBox(
                height: 16,
              ),
              isConnected
                  ? GestureDetector(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text("Enter Network Details"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      decoration:
                                          InputDecoration(hintText: "SSID"),
                                      controller: cont1,
                                    ),
                                    SizedBox(
                                      height: 16,
                                    ),
                                    TextField(
                                        decoration: InputDecoration(
                                            hintText: "Password"),
                                        obscureText: true,
                                        controller: cont2),
                                  ],
                                ),
                                actions: [
                                  FlatButton(
                                      onPressed: () {
                                        if (isInternet == 0) {
                                          setInternet(1);
                                          //isInternet = 1;
                                          Uri uri = Uri.http(
                                              "192.168.4.1", "/chooseMode", {
                                            "ssid": cont1.value.text,
                                            "password": cont2.value.text
                                          });
                                          http.get(uri).then((value) {
                                            if (value.body == "success") {
                                              setInternet(2);
                                              //isInternet = 2;
                                            } else {
                                              setInternet(0);
                                              //isInternet = 0;
                                            }
                                          });
                                        }
                                      },
                                      color: Colors.amberAccent,
                                      child: Text("Go")),
                                ],
                              );
                            });
                      },
                      child: modeContainer(isInternet))
                  : SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget modeContainer(int isInternet) {
  if (isInternet == 0) {
    return Text(
      "Connect AVC to Internet",
      style: TextStyle(color: Colors.blue),
    );
  } else if (isInternet == 1) {
    return CircularProgressIndicator();
  }
  return Text("Connected to Internet");
}
