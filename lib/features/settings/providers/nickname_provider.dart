import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/hive_service.dart';

const _nicknameKey = 'nickname';

final nicknameProvider = StateNotifierProvider<NicknameNotifier, String>((ref) {
  return NicknameNotifier();
});

class NicknameNotifier extends StateNotifier<String> {
  NicknameNotifier() : super('') {
    _load();
  }

  void _load() {
    state = HiveService.settings.get(_nicknameKey, defaultValue: '') as String;
  }

  Future<void> setNickname(String name) async {
    await HiveService.settings.put(_nicknameKey, name.trim());
    state = name.trim();
  }
}
