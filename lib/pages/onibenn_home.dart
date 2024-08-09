import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onibenn_detail.dart';
import '../ad_banner.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class OnibennHome extends StatefulWidget {
  const OnibennHome({super.key});

  @override
  State<OnibennHome> createState() => _OnibennHomeState();
}

class _OnibennHomeState extends State<OnibennHome> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _studySessions = [];
  List<Map<String, dynamic>> _filteredSessions = [];

  @override
  void initState() {
    super.initState();
    fetchStudySessions().then((data) {
      setState(() {
        _studySessions = data;
        _filteredSessions = data;
      });
    });
    _searchController.addListener(_filterSessions);
  }

  void _filterSessions() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredSessions = _studySessions.where((session) =>
          session['content'].toLowerCase().contains(searchTerm)).toList();
    });
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

  Future<List<Map<String, dynamic>>> fetchStudySessions() async {
    String deviceId = await getDeviceId();
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    var querySnapshot = await FirebaseFirestore.instance
        .collection('studySessions')
        .where('deviceId', isEqualTo: deviceId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    List<Map<String, dynamic>> updatedSessions = querySnapshot.docs
        .map((doc) => {
              'docId': doc.id,
              'content': doc['content'],
              'deviceId': doc['deviceId'],
              'duration': doc['duration'] ?? '00:00:00',
              'startTime': doc['startTime'],
            })
        .toList();

    setState(() {
      _studySessions = updatedSessions;
    });

    return _studySessions;
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _saveAndNavigate() async {
    String studyContent = _controller.text;
    if (studyContent.isNotEmpty) {
      String deviceId = await getDeviceId();
      DocumentReference docRef =
          FirebaseFirestore.instance.collection('studySessions').doc();
      await docRef.set({
        'deviceId': deviceId,
        'content': studyContent,
        'startTime': Timestamp.now(),
        'duration': '00:00:00',
      });
      String docId = docRef.id;
      _studySessions.add({
        'docId': docId,
        'content': studyContent,
        'deviceId': deviceId,
        'duration': '00:00:00',
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OnibennDetail(content: studyContent, docId: docRef.id),
          ),
        ).then((value) {
          if (value == true && mounted) {
            fetchStudySessions().then((data) {
              setState(() {
                _studySessions = data;
              });
            });
          }
          _controller.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '鬼勉 - 勉強時間計測アプリ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white70),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '検索',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        toolbarHeight: 100,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          const Text('勉強内容を入力してください。'),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '勉強内容',
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveAndNavigate,
            child: const Text('計測する'),
          ),
          const SizedBox(height: 20),
          if (_filteredSessions.isNotEmpty)
            const Text('今日の勉強記録'),
          Expanded(
            child: Scrollbar(
              thickness: 6.0,
              radius: const Radius.circular(10),
              child: ListView.builder(
                itemCount: _filteredSessions.length,
                itemBuilder: (context, index) {
                  final session = _filteredSessions[index];
                  return ListTile(
                    title: Text(session['content'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(() {
                      var parts = session['duration'].split(':');
                      return '勉強時間: ${parts[0]}時間${parts[1]}分';
                    }()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            if (!mounted) return;
                            var doc = await FirebaseFirestore.instance
                                .collection('studySessions')
                                .doc(session['docId'])
                                .get();
                            if (doc.exists) {
                              // ドキュメントが存在するか確認
                              var data = doc.data()!;
                              var duration = data['duration'] as String;
                              var parts =
                                  duration.split(':').map(int.parse).toList();
                              var initialSeconds =
                                  parts[0] * 3600 + parts[1] * 60 + parts[2];

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OnibennDetail(
                                      content: session['content'],
                                      docId: session['docId'],
                                      initialTime: initialSeconds),
                                ),
                              ).then((_) {
                                if (mounted) fetchStudySessions();
                              });
                            } else {
                              // ドキュメントが存在しない場合の処理（エラーメッセージ表示など）
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'データが存在しません。ドキュメントID: ${session['docId']}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: const Text('再開'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            if (!mounted) return;
                            bool confirm = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('削除確認'),
                                      content:
                                          Text('${session['content']}を削除しますか？'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('キャンセル'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('削除'),
                                        ),
                                      ],
                                    );
                                  },
                                ) ??
                                false;
                            if (confirm) {
                              await FirebaseFirestore.instance
                                  .collection('studySessions')
                                  .doc(session['docId'])
                                  .delete();
                              fetchStudySessions();
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                TextButton(
                  onPressed: _studySessions.isNotEmpty
                      ? () async {
                          bool confirm = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('全削除確認'),
                                    content: const Text('今日の全てのデータを削除しますか？'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('キャンセル'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('削除'),
                                      ),
                                    ],
                                  );
                                },
                              ) ??
                              false;

                          if (confirm) {
                            String deviceId = await getDeviceId();
                            DateTime now = DateTime.now();
                            DateTime startOfDay = DateTime(now.year, now.month, now.day);
                            DateTime endOfDay = startOfDay.add(const Duration(days: 1));

                            await FirebaseFirestore.instance
                                .collection('studySessions')
                                .where('deviceId', isEqualTo: deviceId)
                                .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                                .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
                                .get()
                                .then((snapshot) {
                              for (DocumentSnapshot ds in snapshot.docs) {
                                ds.reference.delete();
                              }
                            });
                            fetchStudySessions();
                          }
                        }
                      : null,
                  child: const Text('全て削除'),
                ),
                const AdBanner(),
                const AdBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}