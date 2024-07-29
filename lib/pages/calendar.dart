import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../ad_banner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  CalendarState createState() => CalendarState();
}

class CalendarState extends State<Calendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<String> getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId;
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'unknown';
    } else {
      deviceId = 'unknown';
    }
    return deviceId;
  }

  Future<void> _fetchEvents() async {
    String deviceId = await getDeviceId();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('studySessions')
        .where('deviceId', isEqualTo: deviceId)
        .get();
    final events = <DateTime, List<dynamic>>{};

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final startTime = (data['startTime'] as Timestamp).toDate();
      final date = DateTime(startTime.year, startTime.month, startTime.day);
      final duration = data['duration'] as String;

      if (events[date] == null) {
        events[date] = [];
      }
      events[date]!.add({'content': data['content'], 'duration': duration});
    }

    setState(() {
      _events = events;
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _events.entries
        .where((entry) => isSameDay(entry.key, day))
        .expand((entry) => entry.value)
        .toList();
  }

  String _getTotalDurationForDay(DateTime day) {
    final events = _getEventsForDay(day);
    if (events.isEmpty) return '';

    int totalSeconds = 0;
    for (var event in events) {
      final durationParts = event['duration'].split(':');
      totalSeconds += int.parse(durationParts[0]) * 3600 +
          int.parse(durationParts[1]) * 60 +
          int.parse(durationParts[2]);
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '$hours時間$minutes分';
  }

  void _showEventDialog(DateTime day) {
    final events = _getEventsForDay(day);
    final totalDuration = _getTotalDurationForDay(day);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${DateFormat('yyyy/MM/dd').format(day)}の勉強記録',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '総勉強時間: $totalDuration',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (events.isNotEmpty)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: events.map((event) => ListTile(
                    title: Text(event['content']),
                    subtitle: Text('勉強時間: ${event['duration']}'),
                  )).toList(),
                ),
              )
            else
              const Text('この日の勉強記録はありません。', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'カレンダー',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text('カレンダーに日々の勉強内容を記録します。'),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2010, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _showEventDialog(selectedDay);
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getEventsForDay,
              calendarStyle: const CalendarStyle(
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        padding: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.blue.withOpacity(0.8),
                        ),
                        child: Text(
                          _getTotalDurationForDay(date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.0,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
          Expanded(child: Container()),
          const SafeArea(child: Column(
            children: [
              AdBanner(),
              AdBanner(),
            ],
          )),
        ],
      ),
    );
  }
}