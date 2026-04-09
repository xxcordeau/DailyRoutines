import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'data/local/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // iOS 위젯 App Group 설정
  HomeWidget.setAppGroupId('group.com.dailyroutine.widget');

  runApp(
    const ProviderScope(
      child: DailyRoutineApp(),
    ),
  );
}
