import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../ads/ad_banner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_review/in_app_review.dart';

class StudyChart extends StatefulWidget {
  const StudyChart({super.key});

  @override
  StudyChartState createState() => StudyChartState();
}

class StudyChartState extends State<StudyChart> {
  final InAppReview inAppReview = InAppReview.instance;
  List<BarChartGroupData> _chartData = [];
  bool _isLoading = true;
  late DateTime _currentStartDate;

  @override
  void initState() {
    super.initState();
    _currentStartDate = DateTime.now().subtract(const Duration(days: 6));
    _fetchStudyData();
  }

  Future<void> _fetchStudyData() async {
    setState(() {
      _isLoading = true;
    });

    String deviceId = await getDeviceId();
    DateTime endDate = _currentStartDate.add(const Duration(days: 6));

    var querySnapshot = await FirebaseFirestore.instance
        .collection('studySessions')
        .where('deviceId', isEqualTo: deviceId)
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_currentStartDate))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('startTime', descending: false)
        .get();

    Map<String, int> dailyTotals = {};

    // 過去7日間のすべて日付を初期化
    for (int i = 0; i < 7; i++) {
      DateTime date = _currentStartDate.add(Duration(days: i));
      String dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyTotals[dateString] = 0;
    }

    for (var doc in querySnapshot.docs) {
      DateTime date = (doc['startTime'] as Timestamp).toDate();
      String dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      int duration = _parseDuration(doc['duration'] as String);

      dailyTotals[dateString] = (dailyTotals[dateString] ?? 0) + duration;
    }

    List<BarChartGroupData> chartData = [];
    int index = 0;
    dailyTotals.forEach((date, totalSeconds) {
      double hours = totalSeconds / 3600;
      chartData.add(BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: hours,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ));
      index++;
    });

    setState(() {
      _chartData = chartData;
      _isLoading = false;
    });
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url =
        Uri.parse('https://tsutsunoidoblog.com/onibenn-privacy-policy/');
    if (!await launchUrl(url)) {
      throw Exception('プライバシーポリシーページを開けませんでした');
    }
  }

  Future<void> _requestReview() async {
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }

  void _navigateWeek(int direction) {
    setState(() {
      _currentStartDate = _currentStartDate.add(Duration(days: 7 * direction));
    });
    _fetchStudyData();
  }

  int _parseDuration(String duration) {
    List<String> parts = duration.split(':');
    return int.parse(parts[0]) * 3600 +
        int.parse(parts[1]) * 60 +
        int.parse(parts[2]);
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

  double? _getTodayStudyHours() {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    for (int i = 0; i < _chartData.length; i++) {
      final date = _currentStartDate.add(Duration(days: i));
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (dateString == todayString) {
        return _chartData[i].barRods[0].toY;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('勉強時間グラフ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String result) {
              if (result == 'option1') {
                _launchPrivacyPolicy();
              } else if (result == 'option2') {
                _requestReview();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'option1',
                child: Text('プライバシーポリシー',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem<String>(
                value: 'option2',
                child: Text('レビューする',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(children: [
                      Positioned(
                        left: 64,
                        top: 16,
                        child: Text(
                          '${_currentStartDate.add(Duration(days: 6)).year}年${_currentStartDate.add(Duration(days: 6)).month}月',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => _navigateWeek(-1),
                          ),
                          Expanded(
                              child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 18,
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      '${rod.toY.toStringAsFixed(2)}時間',
                                      const TextStyle(color: Colors.white),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final date = _currentStartDate
                                          .add(Duration(days: value.toInt()));
                                      return Text('${date.month}/${date.day}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold));
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(
                                show: true,
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              barGroups: _chartData,
                            ),
                          )),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () => _navigateWeek(1),
                          ),
                        ],
                      ),
                    ]),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _getTodayStudyHours() != null
                          ? Text('今日の勉強時間: ${_getTodayStudyHours()!.floor()}時間',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold))
                          : const SizedBox.shrink(), // 今日のデータがない場合は何も表示しない
                      const SizedBox(height: 16),
                      const AdBanner(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
