import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:location_service_bfetch/position_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_fetch/background_fetch.dart';

const EVENTS_KEY = "fetch_events";

/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(String taskId) async {
  print("[BackgroundFetch] Headless event received: $taskId");
  DateTime timestamp = DateTime.now();
  final prefs = await SharedPreferences.getInstance();
  // Read fetch_events from SharedPreferences
  List<String> events = [];
  String json = prefs.getString(EVENTS_KEY);
  if (json != null) {
    events = jsonDecode(json).cast<String>();
  }
  deviceInfo();
  var locationData = await Geolocator.getCurrentPosition();

  print("current location:  ${locationData.latitude}");
  await prefs.setString("headlessMainLocData", locationData.toString());
  // Add new event.
  events.insert(0, "$taskId@$timestamp [Headless]\n $locationData");
  // Persist fetch events in SharedPreferences
  prefs.setString(EVENTS_KEY, jsonEncode(events));

  BackgroundFetch.finish(taskId);

  if (taskId == 'flutter_background_fetch') {
    BackgroundFetch.scheduleTask(
      TaskConfig(
        taskId: "com.backgroundFetchHeadlessTask",
        delay: 5000,
        periodic: true,
        startOnBoot: true,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true,
      ),
    );
  }
}

Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
  return <String, dynamic>{
    'version.securityPatch': build.version.securityPatch,
    'version.sdkInt': build.version.sdkInt,
    'version.release': build.version.release,
    'version.previewSdkInt': build.version.previewSdkInt,
    'version.incremental': build.version.incremental,
    'version.codename': build.version.codename,
    'version.baseOS': build.version.baseOS,
    'board': build.board,
    'bootloader': build.bootloader,
    'brand': build.brand,
    'device': build.device,
    'display': build.display,
    'fingerprint': build.fingerprint,
    'hardware': build.hardware,
    'host': build.host,
    'id': build.id,
    'manufacturer': build.manufacturer,
    'model': build.model,
    'product': build.product,
    'supported32BitAbis': build.supported32BitAbis,
    'supported64BitAbis': build.supported64BitAbis,
    'supportedAbis': build.supportedAbis,
    'tags': build.tags,
    'type': build.type,
    'isPhysicalDevice': build.isPhysicalDevice,
    'androidId': build.androidId,
    'systemFeatures': build.systemFeatures,
  };
}

Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
  return <String, dynamic>{
    'name': data.name,
    'systemName': data.systemName,
    'systemVersion': data.systemVersion,
    'model': data.model,
    'localizedModel': data.localizedModel,
    'identifierForVendor': data.identifierForVendor,
    'isPhysicalDevice': data.isPhysicalDevice,
    'utsname.sysname:': data.utsname.sysname,
    'utsname.nodename:': data.utsname.nodename,
    'utsname.release:': data.utsname.release,
    'utsname.version:': data.utsname.version,
    'utsname.machine:': data.utsname.machine,
  };
}

SharedPreferences pref;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable integration testing with the Flutter Driver extension.
  // See https://flutter.io/testing/ for more info.
  await Hive.initFlutter();
  Hive.registerAdapter(PositionDataAdapter());
  pref = await SharedPreferences.getInstance();
  runApp(new MyApp());

  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

void singleTask() {
  BackgroundFetch.scheduleTask(
    TaskConfig(
      taskId: "com.transistorsoft.one-shotTask",
      delay: 5000,
      periodic: false,
      forceAlarmManager: true,
      stopOnTerminate: false,
      enableHeadless: true,
    ),
  );
}

void deviceInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> deviceData;

  try {
    if (Platform.isAndroid) {
      deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);
      await prefs.setString("device", deviceData.toString());
      print(deviceData);
    } else if (Platform.isIOS) {
      deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);
      await prefs.setString("device", deviceData.toString());
      print(deviceData);
    }
  } on PlatformException {
    deviceData = <String, dynamic>{'Error:': 'Failed to get platform version.'};
  }
}

void hiveInitialize() async {
  await Hive.initFlutter();
  Hive.registerAdapter(PositionDataAdapter());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _enabled = true;
  int _status = 0;
  List<String> _events = [];

  @override
  void initState() {
    super.initState();
    Geolocator.requestPermission();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String json = prefs.getString(EVENTS_KEY);
    if (json != null) {
      setState(() {
        _events = jsonDecode(json).cast<String>();
      });
    }

    // Configure BackgroundFetch.
    BackgroundFetch.configure(
            BackgroundFetchConfig(
              minimumFetchInterval: 15,
              forceAlarmManager: false,
              stopOnTerminate: false,
              startOnBoot: true,
              enableHeadless: true,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresStorageNotLow: false,
              requiresDeviceIdle: false,
              requiredNetworkType: NetworkType.NONE,
            ),
            _onBackgroundFetch)
        .then((int status) {
      print('[BackgroundFetch] configure success: $status');
      setState(() {
        _status = status;
      });
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
      setState(() {
        _status = e;
      });
    });

    // Schedule a "one-shot" custom-task in 10000ms.
    // These are fairly reliable on Android (particularly with forceAlarmManager) but not iOS,
    // where device must be powered (and delay will be throttled by the OS).

    BackgroundFetch.scheduleTask(
      TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 5000,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true,
      ),
    );

    // Optionally query the current BackgroundFetch status.
    int status = await BackgroundFetch.status;
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  void _onBackgroundFetch(String taskId) async {
    DateTime timestamp = new DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    // hiveInitialize();
    // await Hive.initFlutter();
    // Hive.registerAdapter(PositionDataAdapter());
    var box = await Hive.openBox<PositionData>('testBox');
    deviceInfo();
    var locationData = await Geolocator.getCurrentPosition();
    final pData = positionDataFromJson(jsonEncode(locationData));
    await box.add(pData);
    var el = box.getAt(0);
    print("latitude : " + el.latitude.toString());
    print("current location:  ${locationData.latitude}");
    await prefs.setString("locationData", locationData.toString());

    // This is the fetch-event callback.
    print("[BackgroundFetch] Event received: $taskId");
    setState(() {
      _events.insert(0, "$taskId@${timestamp.toString()}\n$locationData");
    });
    // Persist fetch events in SharedPreferences
    prefs.setString(EVENTS_KEY, jsonEncode(_events));

    if (taskId == "flutter_background_fetch") {
      // Schedule a one-shot task when fetch event received (for testing).
      BackgroundFetch.scheduleTask(
        TaskConfig(
          taskId: "com.transistorsoft.customtask",
          delay: 3000,
          periodic: true,
          forceAlarmManager: false,
          stopOnTerminate: false,
          enableHeadless: true,
        ),
      );
    }

    // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
    // for taking too long in the background.
    BackgroundFetch.finish(taskId);
  }

  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }

  void _onClickStatus() async {
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status: $status');
    setState(() {
      _status = status;
    });
  }

  void _onClickClear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(EVENTS_KEY);
    setState(() {
      _events = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget emptyText = Center(
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                'Servis açık ve konum izni her zaman olarak ayarlandığı zaman uygulama belli aralıklarla arkaplanda veya açıkken\nkonum isteği yollayıp gelen yanıtı cihaz bilgleri ile locale kaydedecek'),
            SizedBox(height: 10),
            Text(
                "Android ve IOS işletim sistemleri background servisleri tetiklenme konusunda oldukça katı\nİşletim sistemleri bir arkaplan işleminin konusunda birçok kritere bakarak ne zaman çalıştırılacağına kara veriyorlar."),
            SizedBox(height: 10),
            Text(
                "Şu an servis durumu açık vaziyette uygulama kapatıldığı zaman Android'in izin verdiği minimum 15 dk lık aralıkla konum verileri istenip kaydedilecek\n Bu süreyi bir kaç değişiklik yaparak bir kaç dk lık aralıklara çektim\n \n Ama yinede işetim sistemi background processlerde her zaman bu aralığa uymayacak kendisi karar verecektir(batarya,kaynak tüketimi, diğer uygulama servisleriyle çakışma nedeniyle) "),
            SizedBox(height: 10),
            Text(
                'Servis açık durumda uygulamayı kapatıp test edebilirsiniz\nKonum isteğinde bulunulan cihaz detayları herhangi bir kayıtın üzerine tıklayınca açılacaktır'),
          ],
        ),
      ),
    );
    String device = pref.getString("device");
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: Text('Konum Servisi', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.amberAccent,
            brightness: Brightness.light,
            actions: <Widget>[
              Row(
                children: [
                  Text(
                    "Servis Durumu",
                    style: TextStyle(color: Colors.black),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: _onClickEnable,
                  ),
                ],
              ),
            ]),
        body: Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Cihaz Detayları"),
                    content: Container(
                      height: 300,
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(device),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      RaisedButton(
                        child: Text("Kapat"),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: (_events.isEmpty)
                ? emptyText
                : Container(
                    child: new ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (BuildContext context, int index) {
                          List<String> event = _events[index].split("@");
                          print(event[0]);
                          return InputDecorator(
                              decoration: InputDecoration(
                                  contentPadding: EdgeInsets.only(
                                      left: 5.0, top: 5.0, bottom: 5.0),
                                  labelStyle: TextStyle(
                                      color: Colors.blue, fontSize: 20.0),
                                  labelText:
                                      "Arkaplan Konum işlemi" //"[${event[0].toString()}]",
                                  ),
                              child: new Text(event[1],
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16.0)));
                        }),
                  ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
            child: Container(
                padding: EdgeInsets.only(left: 5.0, right: 5.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      RaisedButton(
                        onPressed: singleTask,
                        child: Text('Tek Seferlik'),
                      ),
                      RaisedButton(
                        onPressed: _onClickClear,
                        child: Text('Temizle'),
                      ),
                    ]))),
      ),
    );
  }
}
