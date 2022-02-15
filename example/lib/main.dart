import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_elves/flutter_blue_elves.dart';
import 'device_control.dart';
import 'dart:io';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

//flutter blue
class _MyAppState extends State<MyApp> {
  List<AndroidBluetoothLack> _blueLack = [];
  IosBluetoothState _iosBlueState = IosBluetoothState.unKnown;
  List<ScanResult> _scanResultList = [];
  List<HideConnectedDevice> _hideConnectedList = [];
  final List<_ConnectedItem> _connectedList = [];
  bool _isScaning = false;

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(milliseconds: 5000),
        Platform.isAndroid ? androidGetBlueLack : iosGetBlueState);
    getHideConnectedDevice();
  }

  void iosGetBlueState(timer) {
    FlutterBlueElves.instance.iosCheckBluetoothState().then((value) {
      setState(() {
        _iosBlueState = value;
      });
    });
  }

  void androidGetBlueLack(timer) {
    FlutterBlueElves.instance.androidCheckBlueLackWhat().then((values) {
      setState(() {
        _blueLack = values;
      });
    });
  }

  void getHideConnectedDevice() {
    FlutterBlueElves.instance.getHideConnectedDevices().then((values) {
      setState(() {
        _hideConnectedList = values;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: Platform.isAndroid ? 160 : null,
        centerTitle: false,
        title: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Tap here to focus",
                  filled: true,
                  fillColor: Colors.blue.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  )
              ),
              onChanged: (val){
                final snackBar = SnackBar(
                  content: Text('$val', style: TextStyle(color: Colors.white),),
                  backgroundColor: Colors.green,
                );

                // Find the ScaffoldMessenger in the widget tree
                // and use it to show a SnackBar.
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },

            ),
          ],
        ),
      ),

      body:
        ListView.separated(
          itemCount: (_connectedList.isNotEmpty ? _connectedList.length + 1 : 0) +
              (_hideConnectedList.isNotEmpty
                  ? _hideConnectedList.length + 1
                  : 0) +
              (_scanResultList.isNotEmpty ? _scanResultList.length + 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (_connectedList.isNotEmpty && index <= _connectedList.length) {
              if (index == 0) {
                return const Text("Connected device",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold));
              } else {
                _ConnectedItem currentConnected = _connectedList[index - 1];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(currentConnected._name ?? "Unnamed device",
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16)),
                            Text(
                                currentConnected._macAddress ??
                                    "Unable to get mac address",
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: StreamBuilder<DeviceState>(
                            initialData: DeviceState.connected,
                            stream: currentConnected._device.stateStream,
                            builder: (BuildContext context,
                                AsyncSnapshot<DeviceState> snapshot) {
                              DeviceState? currentState =
                              snapshot.connectionState ==
                                  ConnectionState.active
                                  ? snapshot.data
                                  : currentConnected._device.state;
                              return Column(children: [
                                ElevatedButton(
                                  child: Text(
                                      currentState == DeviceState.connected
                                          ? "Disconnect"
                                          : "Connect"),
                                  onPressed: () {
                                    if (currentState == DeviceState.connected) {
                                      currentConnected._device.disConnect();
                                    } else {
                                      currentConnected._device
                                          .connect(connectTimeout: 10000);
                                    }
                                  },
                                ),
                                ElevatedButton(
                                  child: const Text("destroy"),
                                  onPressed: () {
                                    currentConnected._device.destroy();
                                    setState(() {
                                      _connectedList.removeAt(index - 1);
                                    });
                                  },
                                ),
                                ElevatedButton(
                                  child: const Text("To tap"),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return DeviceControl(
                                              currentConnected._name,
                                              currentConnected._macAddress,
                                              currentConnected._device);
                                        },
                                      ),
                                    );
                                  },
                                )
                              ]);
                            }),
                      ),
                    ],
                  ),
                );
              }
            } else if (_hideConnectedList.isNotEmpty &&
                index -
                    (_connectedList.isNotEmpty
                        ? _connectedList.length + 1
                        : 0) <=
                    _hideConnectedList.length) {
              int hideStartIndex =
              _connectedList.isNotEmpty ? _connectedList.length + 1 : 0;
              if (index == hideStartIndex) {
                return const Text("HideConnected",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold));
              } else {
                HideConnectedDevice currentHide =
                _hideConnectedList[index - hideStartIndex - 1];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            flex: 7,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentHide.name ?? "Unnamed device",
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 16)),
                                Text(
                                    currentHide.uuids.length.toString() +
                                        " Service Advertised",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                                Text(
                                    currentHide.macAddress ??
                                        "Unable to get mac address",
                                    style: const TextStyle(
                                        color: Colors.black, fontSize: 12)),
                              ],
                            )),
                        Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      Device toConnectDevice = currentHide
                                          .connect(connectTimeout: 10000);
                                      setState(() {
                                        _connectedList.insert(
                                            0,
                                            _ConnectedItem(
                                                toConnectDevice,
                                                currentHide.macAddress,
                                                currentHide.name));
                                        _hideConnectedList
                                            .removeAt(index - hideStartIndex - 1);
                                      });
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return DeviceControl(
                                                currentHide.name,
                                                currentHide.macAddress,
                                                toConnectDevice);
                                          },
                                        ),
                                      );
                                    },
                                    child: const Text("Connect"))
                              ],
                            )),
                      ]),
                );
              }
            } else {
              int scanStartIndex =
                  (_connectedList.isNotEmpty ? _connectedList.length + 1 : 0) +
                      (_hideConnectedList.isNotEmpty
                          ? _hideConnectedList.length + 1
                          : 0);
              if (index == scanStartIndex) {
                return const Text("Scan Results",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold));
              } else {
                ScanResult currentScan =
                _scanResultList[index - scanStartIndex - 1];
                return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(currentScan.name ?? "Unnamed device",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 16)),
                              Text(
                                  currentScan.uuids.length.toString() +
                                      " Service Advertised",
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              Text(
                                  currentScan.macAddress ??
                                      "Unable to get mac address",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 12)),
                              currentScan.localName == null
                                  ? const Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              )
                                  : Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text("LocalName:",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12)),
                                  Text(currentScan.localName!,
                                      style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14))
                                ],
                              ),
                              currentScan.manufacturerSpecificData == null
                                  ? const Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              )
                                  : const Text("ManufacturerData:",
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              currentScan.manufacturerSpecificData == null
                                  ? const Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              )
                                  : Column(
                                  children: currentScan
                                      .manufacturerSpecificData!.entries
                                      .map((entry) {
                                    String data = "";
                                    for (int byte in entry.value) {
                                      String byteStr = byte.toRadixString(16);
                                      data += byteStr.length > 1
                                          ? byteStr
                                          : ("0" + byteStr);
                                      data += ",";
                                    }
                                    data = data.replaceRange(
                                        data.length - 1, null, "");
                                    data = "[" + data + "]";
                                    int keyInt = entry.key;
                                    String keyStr = keyInt.toRadixString(16);
                                    return Text(keyStr + ":" + data,
                                        style: const TextStyle(
                                            color: Colors.black, fontSize: 12));
                                  }).toList()),
                              currentScan.row == null
                                  ? const Padding(
                                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                              )
                                  : Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const Text("Row:",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12)),
                                  Text((currentScan.row!
                                      .map((byte) {
                                    String byteStr =
                                    byte.toRadixString(16);
                                    return byteStr.length > 1
                                        ? byteStr
                                        : "0" + byteStr;
                                  })
                                      .toList()
                                      .toString()))
                                ],
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              ElevatedButton(
                                  onPressed: () {
                                    Device toConnectDevice = currentScan.connect(
                                        connectTimeout: 10000);
                                    setState(() {
                                      _connectedList.insert(
                                          0,
                                          _ConnectedItem(
                                              toConnectDevice,
                                              currentScan.macAddress,
                                              currentScan.name));
                                      _scanResultList
                                          .removeAt(index - scanStartIndex - 1);
                                    });
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return DeviceControl(
                                              currentScan.name,
                                              currentScan.macAddress,
                                              toConnectDevice);
                                        },
                                      ),
                                    );
                                  },
                                  child: const Text("Connect")),
                              Text(currentScan.rssi.toString() + " dBm",
                                  style: const TextStyle(
                                      color: Colors.lightGreen, fontSize: 12))
                            ],
                          ),
                        )
                      ],
                    ));
              }
            }
          },
          separatorBuilder: (BuildContext context, int index) {
            if (_connectedList.isNotEmpty && index <= _connectedList.length) {
              if (index == 0 || index == _connectedList.length) {
                return const Divider(color: Colors.white);
              } else {
                return const Divider(color: Colors.grey);
              }
            } else if (_hideConnectedList.isNotEmpty &&
                index -
                    (_connectedList.isNotEmpty
                        ? _connectedList.length + 1
                        : 0) <=
                    _hideConnectedList.length) {
              int hideStartIndex =
              _connectedList.isNotEmpty ? _connectedList.length + 1 : 0;
              if (index == hideStartIndex ||
                  index == hideStartIndex + _hideConnectedList.length) {
                return const Divider(color: Colors.white);
              } else {
                return const Divider(color: Colors.grey);
              }
            } else {
              int scanStartIndex =
                  (_connectedList.isNotEmpty ? _connectedList.length + 1 : 0) +
                      (_hideConnectedList.isNotEmpty
                          ? _hideConnectedList.length + 1
                          : 0);
              if (index == scanStartIndex ||
                  index == scanStartIndex + _scanResultList.length) {
                return const Divider(color: Colors.white);
              } else {
                return const Divider(color: Colors.grey);
              }
            }
          },
        ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isScaning ? Colors.red : Colors.blue,
        onPressed: () {
          getHideConnectedDevice();
          if ((Platform.isAndroid && _blueLack.isEmpty) ||
              (Platform.isIOS &&
                  _iosBlueState == IosBluetoothState.poweredOn)) {
            if (_isScaning) {
              FlutterBlueElves.instance.stopScan();
            } else {
              _scanResultList = [];
              setState(() {
                _isScaning = true;
              });
              FlutterBlueElves.instance.startScan(5000).listen((event) {
                setState(() {
                  _scanResultList.insert(0, event);
                });
              }).onDone(() {
                setState(() {
                  _isScaning = false;
                });
              });
            }
          }
        },
        tooltip: 'scan',
        child: Icon(_isScaning ? Icons.stop : Icons.find_replace),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _ConnectedItem {
  final Device _device;
  final String? _macAddress;
  final String? _name;

  _ConnectedItem(this._device, this._macAddress, this._name);
}
