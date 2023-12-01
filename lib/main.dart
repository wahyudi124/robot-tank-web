import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:webrobot/websockets.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

const ballSize = 20.0;
const step = 10.0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double _x = 100;
  double _y = 100;

  JoystickMode _joystickMode = JoystickMode.all;

  double _robotSpeed = 50.0;

  @override
  void didChangeDependencies() {
    _x = MediaQuery.of(context).size.width / 2 - ballSize / 2;
    super.didChangeDependencies();
  }

  bool _camLight = false;
  int _counter = 0;
  final WebSocket _socket = WebSocket("ws://localhost:5000");
  bool _isConnected = false;
  
  void connect(BuildContext context) async {
    _socket.connect();
    setState(() {
      _isConnected = true;
    });
  }

  void disconnect() {
    _socket.disconnect();
    setState(() {
      _isConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          padding: EdgeInsets.symmetric(horizontal: 100),
          height: 700,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(children: [
                      Text(
                        "Temperature: ",
                        style: TextStyle(
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: 200,
                        height: 170,
                        child: SfRadialGauge(
                          enableLoadingAnimation: true,
                          axes: <RadialAxis>[
                            RadialAxis(
                                showLabels: false,
                                showTicks: false,
                                radiusFactor: 0.8,
                                maximum: 240,
                                axisLineStyle: const AxisLineStyle(
                                    cornerStyle: CornerStyle.startCurve,
                                    thickness: 5),
                                annotations: <GaugeAnnotation>[
                                  GaugeAnnotation(
                                      angle: 90,
                                      widget: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text('142',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 30)),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 2, 0, 0),
                                            child: Text(
                                              '°C',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 14),
                                            ),
                                          )
                                        ],
                                      )),
                                  GaugeAnnotation(
                                    angle: 124,
                                    positionFactor: 1.1,
                                    widget: Text('0',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                  GaugeAnnotation(
                                    angle: 54,
                                    positionFactor: 1.1,
                                    widget: Text('240',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ],
                                pointers: <GaugePointer>[
                                  const RangePointer(
                                    value: 142,
                                    width: 18,
                                    pointerOffset: -6,
                                    cornerStyle: CornerStyle.bothCurve,
                                    color: Color(0xFFF67280),
                                    gradient: SweepGradient(colors: <Color>[
                                      Color(0xFFFF7676),
                                      Color(0xFFF54EA2)
                                    ], stops: <double>[
                                      0.25,
                                      0.75
                                    ]),
                                  ),
                                  MarkerPointer(
                                    value: 136,
                                    color: Colors.white,
                                    markerType: MarkerType.circle,
                                  ),
                                ]),
                          ],
                        ),
                      )
                    ]),
                    Column(
                      children: [
                        Text(
                          "Speed Tank: ",
                          style: TextStyle(
                              fontFamily: 'Comfortaa',
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                            width: 170,
                            height: 50,
                            child: SfLinearGauge(
                                interval: 20,
                                animateAxis: true,
                                animateRange: true,
                                labelPosition: LinearLabelPosition.inside,
                                tickPosition: LinearElementPosition.inside,
                                onGenerateLabels: () {
                                  return <LinearAxisLabel>[
                                    const LinearAxisLabel(text: '0', value: 0),
                                    const LinearAxisLabel(
                                        text: '20', value: 20),
                                    const LinearAxisLabel(
                                        text: '40', value: 40),
                                    const LinearAxisLabel(
                                        text: '60', value: 60),
                                    const LinearAxisLabel(
                                        text: '80', value: 80),
                                    const LinearAxisLabel(
                                        text: '100', value: 100),
                                  ];
                                },
                                axisTrackStyle: const LinearAxisTrackStyle(
                                    thickness: 16, color: Colors.transparent),
                                markerPointers: <LinearMarkerPointer>[
                                  LinearShapePointer(
                                      value: _robotSpeed,
                                      onChanged: (dynamic value) {
                                        setState(() {
                                          _robotSpeed = value as double;
                                        });
                                      },
                                      color: const Color(0xffFFFFFF),
                                      width: 24,
                                      position: LinearElementPosition.cross,
                                      shapeType: LinearShapePointerType
                                          .invertedTriangle,
                                      height: 16),
                                ],
                                ranges: const <LinearGaugeRange>[
                                  LinearGaugeRange(
                                    midValue: 0,
                                    endValue: 80,
                                    startWidth: 16,
                                    midWidth: 16,
                                    endWidth: 16,
                                    position: LinearElementPosition.cross,
                                    color: Color(0xff0DC9AB),
                                  ),
                                  LinearGaugeRange(
                                    startValue: 80.0,
                                    midValue: 0,
                                    startWidth: 16,
                                    midWidth: 16,
                                    endWidth: 16,
                                    position: LinearElementPosition.cross,
                                    color: Color(0xffF45656),
                                  )
                                ])),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "Joystick Tank : ",
                          style: TextStyle(
                              fontFamily: 'Comfortaa',
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: 150,
                          height: 150,
                          child: Joystick(
                            mode: _joystickMode,
                            listener: (details) {
                              setState(() {
                                _x = _x + step * details.x;
                                _y = _y + step * details.y;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                  width: 600,
                  padding: EdgeInsets.only(top: 75),
                  child: Column(
                    children: <Widget>[
                      Container(
                          height: 300,
                          width: 600,
                          alignment: Alignment.center,
                          color: Colors.blue,
                          child: _isConnected
                              ? StreamBuilder(
                                  stream: _socket.stream,
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const CircularProgressIndicator();
                                    }

                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      return const Center(
                                        child: Text("Connection Closed !"),
                                      );
                                    }
                                    //? Working for single frames
                                    return Image.memory(
                                      Uint8List.fromList(
                                        base64Decode(
                                          (snapshot.data.toString()),
                                        ),
                                      ),
                                      gaplessPlayback: true,
                                      excludeFromSemantics: true,
                                    );
                                  },
                                )
                              : const Text(
                                  "Initiate Connection",
                                  style: TextStyle(
                                      fontFamily: 'Comfortaa',
                                      fontWeight: FontWeight.w700),
                                )),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            child: Row(
                              children: [
                                Text(
                                  "Camera :",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Comfortaa',
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Switch(
                                  // This bool value toggles the switch.
                                  value: _isConnected,
                                  activeColor: Colors.blueAccent,
                                  onChanged: (bool value) {
                                    // This is called when the user toggles the switch.
                                    if(value == true){
                                      connect(context);
                                    }
                                    else{
                                      disconnect();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Container(
                            child: Row(
                              children: [
                                Text(
                                  "Camera Light :",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Comfortaa',
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Switch(
                                  // This bool value toggles the switch.
                                  value: _camLight,
                                  activeColor: Colors.blueAccent,
                                  onChanged: (bool value) {
                                    // This is called when the user toggles the switch.
                                    setState(() {
                                      _camLight = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        
                        ],
                      ),
                      SizedBox(
                        height: 75,
                        width: 100,
                      ),
                      Text(
                        "Prototype Robot Tank",
                        style: TextStyle(
                            fontSize: 30,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  )),
              Container(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Column(children: [
                      Text(
                        "Gas Parameter: ",
                        style: TextStyle(
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Container(
                        width: 200,
                        height: 170,
                        child: SfRadialGauge(
                          enableLoadingAnimation: true,
                          axes: <RadialAxis>[
                            RadialAxis(
                                showLabels: false,
                                showTicks: false,
                                radiusFactor: 0.8,
                                maximum: 240,
                                axisLineStyle: const AxisLineStyle(
                                    cornerStyle: CornerStyle.startCurve,
                                    thickness: 5),
                                annotations: <GaugeAnnotation>[
                                  GaugeAnnotation(
                                      angle: 90,
                                      widget: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text('142',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 30)),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 2, 0, 0),
                                            child: Text(
                                              '°C',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 14),
                                            ),
                                          )
                                        ],
                                      )),
                                  GaugeAnnotation(
                                    angle: 124,
                                    positionFactor: 1.1,
                                    widget: Text('0',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                  GaugeAnnotation(
                                    angle: 54,
                                    positionFactor: 1.1,
                                    widget: Text('240',
                                        style: TextStyle(fontSize: 14)),
                                  ),
                                ],
                                pointers: <GaugePointer>[
                                  const RangePointer(
                                    value: 142,
                                    width: 18,
                                    pointerOffset: -6,
                                    cornerStyle: CornerStyle.bothCurve,
                                    color: Color(0xFFF67280),
                                    gradient: SweepGradient(colors: <Color>[
                                      Color(0xFFFF7676),
                                      Color(0xFFF54EA2)
                                    ], stops: <double>[
                                      0.25,
                                      0.75
                                    ]),
                                  ),
                                  MarkerPointer(
                                    value: 136,
                                    color: Colors.white,
                                    markerType: MarkerType.circle,
                                  ),
                                ]),
                          ],
                        ),
                      )
                    ]),
                    Column(
                      children: [
                        Text(
                          "Speed Camera : ",
                          style: TextStyle(
                              fontFamily: 'Comfortaa',
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                            width: 170,
                            height: 50,
                            child: SfLinearGauge(
                                interval: 20,
                                animateAxis: true,
                                animateRange: true,
                                labelPosition: LinearLabelPosition.inside,
                                tickPosition: LinearElementPosition.inside,
                                onGenerateLabels: () {
                                  return <LinearAxisLabel>[
                                    const LinearAxisLabel(text: '0', value: 0),
                                    const LinearAxisLabel(
                                        text: '20', value: 20),
                                    const LinearAxisLabel(
                                        text: '40', value: 40),
                                    const LinearAxisLabel(
                                        text: '60', value: 60),
                                    const LinearAxisLabel(
                                        text: '80', value: 80),
                                    const LinearAxisLabel(
                                        text: '100', value: 100),
                                  ];
                                },
                                axisTrackStyle: const LinearAxisTrackStyle(
                                    thickness: 16, color: Colors.transparent),
                                markerPointers: <LinearMarkerPointer>[
                                  LinearShapePointer(
                                      value: _robotSpeed,
                                      onChanged: (dynamic value) {
                                        setState(() {
                                          _robotSpeed = value as double;
                                        });
                                      },
                                      color: const Color(0xffFFFFFF),
                                      width: 24,
                                      position: LinearElementPosition.cross,
                                      shapeType: LinearShapePointerType
                                          .invertedTriangle,
                                      height: 16),
                                ],
                                ranges: const <LinearGaugeRange>[
                                  LinearGaugeRange(
                                    midValue: 0,
                                    endValue: 80,
                                    startWidth: 16,
                                    midWidth: 16,
                                    endWidth: 16,
                                    position: LinearElementPosition.cross,
                                    color: Color(0xff0DC9AB),
                                  ),
                                  LinearGaugeRange(
                                    startValue: 80.0,
                                    midValue: 0,
                                    startWidth: 16,
                                    midWidth: 16,
                                    endWidth: 16,
                                    position: LinearElementPosition.cross,
                                    color: Color(0xffF45656),
                                  )
                                ])),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          "Joystick Camera : ",
                          style: TextStyle(
                              fontFamily: 'Comfortaa',
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: 150,
                          height: 150,
                          child: Joystick(
                            mode: _joystickMode,
                            listener: (details) {
                              setState(() {
                                _x = _x + step * details.x;
                                _y = _y + step * details.y;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          )),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
