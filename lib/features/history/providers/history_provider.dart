import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/daily_record.dart';
import '../../../data/repositories/completion_repository.dart';
import '../../../data/local/hive_service.dart';
import '../../../core/utils/date_utils.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, Map<String, DailyRecord>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<Map<String, DailyRecord>> {
  HistoryNotifier() : super({}) {
    _ensureDemoData();
    _load();
  }

  void _load() {
    state = CompletionRepository().getAllDailyRecords();
  }

  void refresh() => _load();

  /// 데모 데이터: 처음 실행 시 과거 6개월치 샘플 기록 생성
  Future<void> _ensureDemoData() async {
    final box = HiveService.dailyRecords;
    if (box.isNotEmpty) return; // 이미 데이터 있으면 스킵

    final today = AppDateUtils.today;
    // 간단한 결정론적 패턴으로 샘플 생성
    final rates = [0.0, 0.3, 0.5, 0.7, 0.9, 1.0, 0.8, 0.0, 0.6, 0.4];
    for (int i = 180; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      // 주말은 완료율 낮게, 평일은 높게
      final weekday = date.weekday;
      double rate;
      if (weekday == 7 || weekday == 6) {
        rate = rates[i % 4] * 0.5; // 주말: 낮음
      } else {
        rate = rates[i % rates.length]; // 평일: 다양
      }
      if (rate < 0.05) continue; // 일부 날짜는 기록 없음

      final record = DailyRecord(
        date: date,
        totalTasks: 5,
        completedTasks: (rate * 5).round(),
      );
      final key = date.toIso8601String().substring(0, 10);
      await box.put(key, record);
    }
  }
}
