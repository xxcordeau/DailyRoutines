import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/daily_record.dart';
import '../../../data/repositories/completion_repository.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, Map<String, DailyRecord>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<Map<String, DailyRecord>> {
  HistoryNotifier() : super({}) {
    _load();
  }

  void _load() {
    state = CompletionRepository().getAllDailyRecords();
  }

  void refresh() => _load();
}
