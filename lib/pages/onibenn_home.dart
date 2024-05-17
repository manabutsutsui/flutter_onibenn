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
  List<Map<String, dynamic>> _studySessions = [];

  @override
  void initState() {
    super.initState();
    fetchStudySessions().then((data) {
      setState(() {
        _studySessions = data;
      });
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
    // print("デバイスID: $deviceId");  // デバッグ出力
    return deviceId;
  }

  Future<List<Map<String, dynamic>>> fetchStudySessions() async {
    String deviceId = await getDeviceId();
    var querySnapshot = await FirebaseFirestore.instance
        .collection('studySessions')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    List<Map<String, dynamic>> updatedSessions = querySnapshot.docs
        .map((doc) => {
              'docId': doc.id,
              'content': doc['content'],
              'deviceId': doc['deviceId'],
              'duration': doc['duration'],
              // その他のデータ
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
    super.dispose();
  }

  void _saveAndNavigate() async {
    String studyContent = _controller.text;
    if (studyContent.isNotEmpty) {
      String deviceId = await getDeviceId();
      DocumentReference docRef =
          FirebaseFirestore.instance.collection('studySessions').doc();
      await docRef.set({
        'deviceId': deviceId, // デバイスIDも保存
        'content': studyContent,
        'startTime': Timestamp.now(),
      });
      String docId = docRef.id; // ドキュメントIDを取得
      // docId を保存する処理をここに追加
      _studySessions.add({
        'docId': docId, // ドキュメントIDをリストに追加
        'content': studyContent,
        'deviceId': deviceId,
        'duration': '00:00:00', // 初期値
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
        });
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '鬼勉 - 勉強時間計測アプリ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey,
            height: 5.0,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 20),
          const Text('勉強内容を入力してください'),
          const SizedBox(height: 20),
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
            child: const Text('勉強時間を計測する'),
          ),
          const SizedBox(height: 20),



          Expanded(
            child: Scrollbar(
              thickness: 6.0,
              radius: const Radius.circular(10),
              child: ListView.builder(
                itemCount: _studySessions.length,
                itemBuilder: (context, index) {
                  final session = _studySessions[index];
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
            child: TextButton(
              onPressed: _studySessions.isNotEmpty
                  ? () async {
                      bool confirm = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('全削除確認'),
                                content: const Text('全てのデータを削除しますか？'),
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
              child: const Text('全て削除する'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }
}
