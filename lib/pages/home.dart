import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timer.dart';
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
    DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

    var querySnapshot = await FirebaseFirestore.instance
        .collection('studySessions')
        .where('deviceId', isEqualTo: deviceId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('startTime', descending: true)
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
      _filteredSessions = updatedSessions;
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            tabs: [
              Tab(text: '勉強内容'),
              Tab(text: '勉強記録'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStudyContentTab(),
            _buildStudyRecordTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyContentTab() {
    return Column(
      children: <Widget>[
        const SizedBox(height: 10),
        const Text('勉強内容を入力してください。', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ],
    );
  }

  Widget _buildStudyRecordTab() {
    // セッションを日付でグループ化
    Map<String, List<Map<String, dynamic>>> groupedSessions = {};
    final now = DateTime.now();

    for (var session in _filteredSessions) {
      final sessionDate = (session['startTime'] as Timestamp).toDate();
      final difference = now.difference(sessionDate).inDays;

      String dateString;
      if (difference == 0) {
        dateString = '今日';
      } else if (difference == 1) {
        dateString = '昨日';
      } else {
        dateString = '${sessionDate.month}月${sessionDate.day}日';
      }

      if (!groupedSessions.containsKey(dateString)) {
        groupedSessions[dateString] = [];
      }
      groupedSessions[dateString]!.add(session);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: groupedSessions.length,
              itemBuilder: (context, index) {
                String dateString = groupedSessions.keys.elementAt(index);
                List<Map<String, dynamic>> sessions = groupedSessions[dateString]!;
                  
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                      child: Text(
                        dateString,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    ...sessions.map((session) => ListTile(
                          title: Text(session['content']),
                          subtitle: Text('勉強時間: ${_formatDuration(session['duration'])}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () => _resumeSession(session),
                                child: const Text('再開'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteSession(session),
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(String duration) {
    var parts = duration.split(':');
    return '${parts[0]}時間${parts[1]}分';
  }

  void _resumeSession(Map<String, dynamic> session) async {
    if (!mounted) return;
    var doc = await FirebaseFirestore.instance
        .collection('studySessions')
        .doc(session['docId'])
        .get();
    if (doc.exists) {
      var data = doc.data()!;
      var duration = data['duration'] as String;
      var parts = duration.split(':').map(int.parse).toList();
      var initialSeconds = parts[0] * 3600 + parts[1] * 60 + parts[2];

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('データが存在しません。ドキュメントID: ${session['docId']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteSession(Map<String, dynamic> session) async {
    if (!mounted) return;
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('削除確認'),
              content: Text('${session['content']}を削除しますか？'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
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
  }
}