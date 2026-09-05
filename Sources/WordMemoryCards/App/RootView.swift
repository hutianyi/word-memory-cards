import SwiftUI

struct RootView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var speech: SpeechService
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var persistence: PersistenceController

    var body: some View {
        Group {
            if persistence.isReady {
                NavigationStack(path: $router.path) {
                    HomeView()
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                }
            } else {
                ProgressView("正在准备学习记录…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppPalette.background.ignoresSafeArea())
            }
        }
        .alert("无法打开本地数据库", isPresented: loadErrorBinding) {
            Button("好", role: .cancel) {}
        } message: {
            Text(persistence.loadErrorMessage ?? "发生未知错误。")
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .addWords:
            AddWordsView(container: persistence.container)
        case .review:
            ReviewSessionView(
                container: persistence.container,
                settings: settings,
                speech: speech
            )
        case .extraPractice:
            ReviewSessionView(
                container: persistence.container,
                settings: settings,
                speech: speech,
                mode: .extraPractice,
                sessionLimit: extraPracticeLimit,
                extraPracticeScope: settings.extraPracticeScope
            )
        case .settings:
            SettingsView(
                settings: settings,
                speech: speech,
                container: persistence.container
            )
        case .statistics:
            StatisticsView()
        case .wordLibrary:
            WordLibraryView()
        }
    }

    private var extraPracticeLimit: Int? {
        switch settings.extraPracticeScope {
        case .weakest20: return 20
        case .weakest50: return 50
        case .allWeak, .everything: return nil
        }
    }

    private var loadErrorBinding: Binding<Bool> {
        Binding(
            get: { persistence.loadErrorMessage != nil },
            set: { isPresented in
                if !isPresented { persistence.dismissLoadError() }
            }
        )
    }
}
