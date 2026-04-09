// DailyRoutineWidget.swift
// Xcode에서 Widget Extension 타겟을 직접 추가한 뒤 이 파일을 사용하세요.
//
// [Xcode 설정 방법]
// 1. File > New > Target > Widget Extension 선택
// 2. Product Name: DailyRoutineWidget
// 3. Include Configuration Intent: 체크 해제
// 4. Target Membership: DailyRoutineWidget 타겟에만 포함
//
// [App Group 설정]
// 1. Runner 타겟 > Signing & Capabilities > + Capability > App Groups
// 2. App Group ID: group.com.dailyroutine.widget 추가
// 3. DailyRoutineWidget 타겟에도 동일하게 App Group 추가
//
// [Bundle ID]
// Runner:  com.dailyroutine.app (또는 실제 Bundle ID에 맞게)
// Widget:  com.dailyroutine.app.widget

import WidgetKit
import SwiftUI

// UserDefaults에서 Flutter가 저장한 데이터를 읽는 구조체
struct RoutineEntry: TimelineEntry {
    let date: Date
    let completed: Int
    let total: Int

    var progressText: String { "\(completed) / \(total)" }
    var rate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

struct RoutineProvider: TimelineProvider {
    let appGroupId = "group.com.dailyroutine.widget"

    func placeholder(in context: Context) -> RoutineEntry {
        RoutineEntry(date: Date(), completed: 3, total: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutineEntry) -> Void) {
        completion(entry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoutineEntry>) -> Void) {
        let e = entry()
        // 1시간마다 갱신 (Flutter에서 updateAllWidgets() 호출 시 즉시 반영됨)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        completion(Timeline(entries: [e], policy: .after(nextUpdate)))
    }

    private func entry() -> RoutineEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let completed = defaults?.integer(forKey: "completed") ?? 0
        let total = defaults?.integer(forKey: "total") ?? 0
        return RoutineEntry(date: Date(), completed: completed, total: total)
    }
}

// 홈화면 위젯 (systemSmall)
struct RoutineWidgetView: View {
    let entry: RoutineEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("오늘 루틴")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 1, green: 0.42, blue: 0.42))
            Text(entry.progressText)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            ProgressView(value: entry.rate)
                .tint(Color(red: 1, green: 0.42, blue: 0.42))
                .frame(height: 4)
        }
        .padding()
        .containerBackground(.white, for: .widget)
    }
}

// 잠금화면 원형 위젯 (accessoryCircular)
struct RoutineCircularView: View {
    let entry: RoutineEntry

    var body: some View {
        Gauge(value: entry.rate) {
            Text("루틴")
                .font(.system(size: 8))
        } currentValueLabel: {
            Text("\(entry.completed)")
                .font(.system(size: 14, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
        .tint(Color(red: 1, green: 0.42, blue: 0.42))
    }
}

// 잠금화면 직사각형 위젯 (accessoryRectangular)
struct RoutineRectangularView: View {
    let entry: RoutineEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("오늘 루틴")
                    .font(.system(size: 11, weight: .semibold))
                Text(entry.progressText)
                    .font(.system(size: 16, weight: .bold))
            }
            Spacer()
            ProgressView(value: entry.rate)
                .progressViewStyle(.circular)
                .tint(Color(red: 1, green: 0.42, blue: 0.42))
                .frame(width: 28, height: 28)
        }
    }
}

@main
struct DailyRoutineWidget: Widget {
    let kind = "DailyRoutineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RoutineProvider()) { entry in
            RoutineWidgetView(entry: entry)
        }
        .configurationDisplayName("오늘 루틴")
        .description("오늘의 루틴 완료 현황을 확인합니다.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}
