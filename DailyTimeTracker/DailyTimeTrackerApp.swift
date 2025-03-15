import SwiftUI

@main
struct DailyTimeTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
    
    init() {
        appDelegate.persistenceController = persistenceController
    }
}
