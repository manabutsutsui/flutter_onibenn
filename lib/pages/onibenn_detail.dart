import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../ad_banner.dart';

class OnibennDetail extends StatefulWidget {
  const OnibennDetail({super.key, required this.content, required this.docId, this.initialTime = 0});
  final String content;
  final String docId;
  final int initialTime;

  @override
  State<OnibennDetail> createState() => _OnibennDetailState();
}

class _OnibennDetailState extends State<OnibennDetail> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialTime;  
  }

  String get _formattedTime {
    final int hours = _seconds ~/ 3600;
    final int minutes = (_seconds % 3600) ~/ 60;
    final int seconds = _seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    if (_timer != null) return;  

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void _resetTimer() {
    setState(() {
      _seconds = 0;
    });
  }

  void _resetTimerWithConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('リセット確認'),
          content: const Text('タイマーをリセットしてもよろしいですか？'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); 
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                _resetTimer(); 
                Navigator.of(context).pop(); 
              },
              child: const Text('リセット'),
            ),
          ],
        );
      },
    );
  }

  void _saveStudySessionAndNavigateBack() async {
    await FirebaseFirestore.instance.collection('studySessions').doc(widget.docId).update({
      'duration': _formattedTime,
      'endTime': Timestamp.now(),
    });

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '鬼勉 - 勉強時間計測アプリ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_timer != null && _timer!.isActive) {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('警告'),
                    content: const Text('タイマーがまだ動作中です。本当に戻りますか？'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('戻る'),
                      ),
                    ],
                  );
                },
              );
            } else {
              if (_seconds != widget.initialTime) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('変更の保存'),
                      content: const Text('変更を保存して戻りますか？'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () async {
                             _saveStudySessionAndNavigateBack();
                             Navigator.of(context).pop();
                          },
                          child: const Text('保存して戻る'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                Navigator.of(context).pop();
              }
            }
          },
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            Text(
              widget.content,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _formattedTime,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 60,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startTimer,
                  child: const Text('スタート'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _stopTimer,
                  child: const Text('ストップ'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _resetTimerWithConfirmation,
                  child: const Text('リセット'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveStudySessionAndNavigateBack, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
              ),
              child: const Text('終了する', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }
}
