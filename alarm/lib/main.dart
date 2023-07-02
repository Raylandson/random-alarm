// ignore: unused_import
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'dart:math';
import 'dart:io';

AudioPlayer player = AudioPlayer();
List<File> musicList = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  FilePicker.platform;

  runApp(const MyApp());

  //await AndroidAlarmManager.periodic(
  //    const Duration(seconds: 5), 1, alarmCallBack);
}

void alarmCallBack(int id, Map<String, dynamic> params) async {
  String music = params['File'];
  AndroidUsageType.alarm;
  player.setAudioContext(const AudioContext(
      android: AudioContextAndroid(usageType: AndroidUsageType.alarm)));
  await player.play(UrlSource(music));
}

Duration timeUntilNextRing(int hour, int minute) {
  DateTime now = DateTime.now();
  DateTime desiredTime = DateTime(now.year, now.month, now.day, hour, minute);

  if (desiredTime.isBefore(now)) {
    return desiredTime.add(const Duration(days: 1)).difference(now);
  }
  return desiredTime.difference(now);
}

Future<List<File>> getMusicsFromFolder(String folderPath) async {
  Directory folderDir = Directory(folderPath);
  List<File> musicFiles = [];

  if (await folderDir.exists()) {
    List<FileSystemEntity> entities = folderDir.listSync(recursive: true);

    for (FileSystemEntity entity in entities) {
      if (entity is File && entity.path.endsWith('.mp3')) {
        musicFiles.add(entity);
      }
    }
  }
  return musicFiles;
}

Future getFolder() async {
  String? musicsDir = await FilePicker.platform.getDirectoryPath();

  if (musicsDir != null) {
    musicList = await getMusicsFromFolder(musicsDir);
    debugPrint('${musicList.length}');
  } else {
    debugPrint('action canceled');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en', 'US'),
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Random Music Alarm',
            style: TextStyle(fontSize: 20),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Alarm time: ${selectedTime.hour}:${selectedTime.minute}',
                style: const TextStyle(fontSize: 40, color: Colors.blueAccent),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: ElevatedButton(
                        child: const Text('Set alarm time'),
                        onPressed: () async {
                          final TimeOfDay? timeOfDay = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                              initialEntryMode: TimePickerEntryMode.dial,
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                    data: ThemeData.dark(), child: child!);
                              });
                          if (timeOfDay != null) {
                            setState(() {
                              selectedTime = timeOfDay;

                              Duration delay = timeUntilNextRing(
                                  selectedTime.hour, selectedTime.minute);

                              Map<String, dynamic> myMap = {
                                "File": musicList[
                                        Random().nextInt(musicList.length)]
                                    .path
                              };

                              AndroidAlarmManager.oneShot(
                                  delay, 0, alarmCallBack,
                                  params: myMap);

                              debugPrint('anotado $delay ${musicList.length}');
                            });
                          }
                        }),
                  ),
                  ElevatedButton(
                      child: const Text('Set music folder'),
                      onPressed: () async {
                        await getFolder();
                        player.stop();
                        //debugPrint('aaaaaaaaaaaaaaaaaaa ${RingTone.musicList}');
                      })
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
