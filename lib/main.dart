import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:typed_data/typed_buffers.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;

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
  double _x_tank = 100;
  double _y_tank = 100;

  double _x_cam = 100;
  double _y_cam = 100;

  JoystickMode _joystickMode = JoystickMode.all;

  double _robotSpeed = 50.0;

  final ValueNotifier<Image?> _imageNotifier = ValueNotifier<Image?>(null);

  @override
  void didChangeDependencies() {
    _x_tank = MediaQuery.of(context).size.width / 2 - ballSize / 2;
    _x_cam = MediaQuery.of(context).size.width / 2 - ballSize / 2;
    super.didChangeDependencies();
  }

  bool _camLight = false;
  int _counter = 0;
  final MqttBrowserClient _client =
      MqttBrowserClient('ws://103.84.207.210:8083/mqtt', '');
  bool _isConnected = false;

  void connect() async {
    await mqttConnect(
        "mqqt-" + DateTime.now().millisecondsSinceEpoch.toString());
    print('Connection status: $_isConnected');
    setState(() {
      _isConnected = true;
    });
  }

  void disconnect() {
    _client.disconnect();
    setState(() {
      _isConnected = false;
    });
    print('Disconnected');
  }

  Future<bool> mqttConnect(String uniqueId) async {
    _client.logging(on: false);
    _client.setProtocolV311();
    _client.keepAlivePeriod = 20;
    _client.connectTimeoutPeriod = 2000;
    _client.port = 8083;
    _client.onDisconnected = onDisconnected;
    _client.onConnected = onConnected;
    _client.pongCallback = pong;

    final MqttConnectMessage connMess =
        MqttConnectMessage().withClientIdentifier(uniqueId).startClean();
    _client.connectionMessage = connMess;

    try {
      await _client.connect();
    } catch (e) {
      print('Exception: $e');
      _client.disconnect();
    }

    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected Successfully!");
      const topic = 'esp32/cam_0';
      _client.subscribe(topic, MqttQos.atMostOnce);
      return true;
    } else {
      print(
          'Connection failed - disconnecting, status is ${_client.connectionStatus}');
      _client.disconnect();
      return false;
    }
  }

  void onConnected() {
    print("Client connection was successful");
  }

  void onDisconnected() {
    print("Disconnected");
    _isConnected = false;
  }

  void pong() {
    print('Ping response client callback invoked');
  }

  Future<void> decodeImage(Uint8List message) async {
    Uint8List list = Uint8List.view(message.buffer);
    img.Image jpegImage = img.decodeJpg(list) as img.Image;
    print('img width = ${jpegImage.width}, height = ${jpegImage.height}');

    // Perbarui UI dengan gambar yang sudah siap
    _imageNotifier.value = Image.memory(
      img.encodeJpg(jpegImage) as Uint8List,
      gaplessPlayback: true,
    );
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
                                _x_tank = step * details.x;
                                _y_tank = step * details.y;
                              });
                              // Create JSON payload
                              String jsonString =
                                  jsonEncode({'x': _x_tank, 'y': _y_tank});

                              // Convert string to Uint8Buffer
                              final payload = Uint8Buffer();
                              payload.addAll(utf8.encode(jsonString));
                              if (_client != null &&
                                  _client.connectionStatus?.state ==
                                      MqttConnectionState.connected &&
                                  payload != null) {
                                _client.publishMessage(
                                    '/tank', MqttQos.exactlyOnce, payload);
                              } else {
                                print(
                                    'MQTT client is not connected or payload is null');
                                // Handle the case where the client is not connected or payload is null
                              }
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
                                  stream: _client.updates,
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
                                    final mqttReceivedMessages = snapshot.data
                                        as List<
                                            MqttReceivedMessage<MqttMessage?>>?;
                                    final recMess = mqttReceivedMessages![0]
                                        .payload as MqttPublishMessage;

// Convert MqttByteBuffer to Uint8List
                                    // Convert MqttByteBuffer to Uint8List
                                    // Convert Uint8Buffer to Uint8List
                                    Uint8Buffer buffer =
                                        recMess.payload.message;
                                    Uint8List message =
                                        buffer.buffer.asUint8List();

// Separate the image decoding process
                                    decodeImage(message);

                                    return ValueListenableBuilder<Image?>(
                                      valueListenable: _imageNotifier,
                                      builder: (context, image, child) {
                                        if (image == null) {
                                          return const CircularProgressIndicator();
                                        } else {
                                          return image;
                                        }
                                      },
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
                                    if (value == true) {
                                      connect();
                                    } else {
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
                                _x_cam = step * details.x;
                                _y_cam = step * details.y;
                              });
                              // Create JSON payload
                              String jsonString =
                                  jsonEncode({'x': _x_cam, 'y': _y_cam});

                              // Convert string to Uint8Buffer
                              final payload = Uint8Buffer();
                              payload.addAll(utf8.encode(jsonString));
                              if (_client != null &&
                                  _client.connectionStatus?.state ==
                                      MqttConnectionState.connected &&
                                  payload != null) {
                                _client.publishMessage(
                                    '/cam', MqttQos.exactlyOnce, payload);
                              } else {
                                print(
                                    'MQTT client is not connected or payload is null');
                                // Handle the case where the client is not connected or payload is null
                              }
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
