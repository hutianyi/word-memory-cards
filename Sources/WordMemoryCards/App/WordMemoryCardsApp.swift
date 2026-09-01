import SwiftUI

@main
struct WordMemoryCardsApp: App {
    @StateObject private var persistence: PersistenceController
    @StateObject private var settings: SettingsStore
    @StateObject private var speech: SpeechService
    @StateObject private var router: AppRouter

    init() {
        let isUITesting = CommandLine.arguments.contains("--ui-testing")
        _persistence = StateObject(
            wrappedValue: PersistenceController(inMemory: isUITesting)
        )
        _settings = StateObject(wrappedValue: SettingsStore())
        _speech = StateObject(wrappedValue: SpeechService())
        _router = StateObject(wrappedValue: AppRouter())
    }

    var body: some Scene {
        WindowGroup {
            RootView(settings: settings, speech: speech)
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .environmentObject(persistence)
                .environmentObject(router)
                .environmentObject(speech)
        }
    }
}
