import SwiftUI

@main
struct BankingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "banknote")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Banking App")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("MVVM-C Architecture Foundation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Project structure initialized successfully!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding()
            }
            .navigationTitle("Welcome")
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    ContentView()
}
