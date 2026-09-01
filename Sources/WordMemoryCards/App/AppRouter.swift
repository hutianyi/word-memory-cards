import Foundation

enum AppRoute: Hashable {
    case addWords
    case review
    case extraPractice
    case settings
    case statistics
    case wordLibrary
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func reset() {
        path.removeAll()
    }
}
