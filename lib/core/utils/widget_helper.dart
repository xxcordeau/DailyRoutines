import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

// iOS 위젯에 루틴 완료 데이터를 저장하고 갱신 트리거
// App Group ID: group.com.dailyroutine.widget
Future<void> updateHomeWidget({
  required int completed,
  required int total,
}) async {
  if (kIsWeb) return;
  await HomeWidget.saveWidgetData<int>('completed', completed);
  await HomeWidget.saveWidgetData<int>('total', total);
  await HomeWidget.updateWidget(iOSName: 'DailyRoutineWidget');
}
