import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/local/hive_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();

  // Supabase 초기화
  await Supabase.initialize(
    url: 'https://gdkcbscfmqvcfnmqtmkx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdka2Nic2NmbXF2Y2ZubXF0bWt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3MjA5MjMsImV4cCI6MjA5MTI5NjkyM30.R0IhVBvBvODlr1Fc3HejzSL0u-buP9_3NDm9alC86C4',
  );

  // iOS 위젯 App Group 설정
  HomeWidget.setAppGroupId('group.com.dailyroutine.widget');

  runApp(
    const ProviderScope(
      child: DailyRoutineApp(),
    ),
  );
}
