import CoreData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter

    @FetchRequest private var dueStates: FetchedResults<ReviewStateEntity>
    @FetchRequest private var words: FetchedResults<WordEntity>

    init(calendar: Calendar = .current, now: Date = Date()) {
        let start = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) ?? now

        _dueStates = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "nextReviewDate < %@", tomorrow as NSDate),
            animation: .default
        )
        _words = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \WordEntity.createdAt, ascending: true)],
            animation: .default
        )
    }

    var body: some View {
        ZStack {
            AppPalette.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 30)

                Text("单词卡片")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)

                VStack(spacing: 8) {
                    Text("今天待复习")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(AppPalette.textSecondary)
                    Text("\(dueStates.count) 张")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(AppPalette.accent)
                }
                .accessibilityElement(children: .combine)

                VStack(spacing: 14) {
                    Button {
                        router.push(.review)
                    } label: {
                        Label("开始复习", systemImage: "play.fill")
                    }
                    .buttonStyle(LargePrimaryButtonStyle())
                    .disabled(dueStates.isEmpty)
                    .accessibilityIdentifier("home.startReview")

                    Button {
                        router.push(.addWords)
                    } label: {
                        Label(words.isEmpty ? "添加第一个单词" : "添加单词", systemImage: "plus")
                    }
                    .buttonStyle(LargeSecondaryButtonStyle())
                    .accessibilityIdentifier("home.addWords")
                }
                .frame(maxWidth: 440)

                if words.isEmpty {
                    Text("还没有单词，先添加一些单词开始学习。")
                        .font(.body)
                        .foregroundStyle(AppPalette.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("词库共有 \(words.count) 个单词")
                        .font(.subheadline)
                        .foregroundStyle(AppPalette.textSecondary)
                }

                Spacer()

                HStack(spacing: 30) {
                    utilityButton("词库", symbol: "books.vertical", route: .wordLibrary)
                    utilityButton("统计", symbol: "chart.bar.xaxis", route: .statistics)
                    utilityButton("设置", symbol: "gearshape", route: .settings)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func utilityButton(_ title: String, symbol: String, route: AppRoute) -> some View {
        Button {
            router.push(route)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            .frame(minWidth: 64, minHeight: 54)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppPalette.textSecondary)
    }
}
