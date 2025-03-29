import SwiftUI

@main
struct xcodeappApp: App {
    var body: some Scene {
        WindowGroup {
            if UserDefaults.standard.string(forKey: "access_token") != nil {
                ContentView()
            } else {
                LoginView()
            }
        }
    }
}
