import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RecView()
                .tabItem {
                    Label("Рекомендации", systemImage: "photo")
                }
                .tag(0)
            
            OutfitsView()
                .tabItem {
                    Label("Избранное", systemImage: "heart")
                }
                .tag(1)

            WardrobeView()
                .tabItem {
                    Label("Гардероб", systemImage: "tshirt")
                }
                .tag(2)
            
        }
    }
}



struct RecView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                Text("Здесь будут отображаться\nрекомендованные образы")
                    .foregroundColor(.gray)
                Spacer()
            }
            .navigationTitle("Рекомендации")
            .navigationBarItems(trailing:
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.circle")
                        .font(.title)
                }
            )
        }
    }
}





struct ProfileView: View {
    @State private var user: User?
    @State private var isLoggedOut = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            if let user = user {
                Text("👤 Имя:  \(user.name)")
                    .font(.title2)
                Text("📧 Почта:  \(user.email)")
                    .foregroundColor(.gray)
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else {
                ProgressView("Загрузка профиля...")
            }

            Spacer()

            Button("Выйти из аккаунта") {
                logout()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)

            NavigationLink(destination: LoginView(), isActive: $isLoggedOut) {
                EmptyView()
            }
        }
        .padding()
        .navigationTitle("Профиль")
        .onAppear {
            loadProfile()
        }
    }

    func loadProfile() {
        APIService.shared.fetchProfile { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedUser):
                    self.user = fetchedUser
                case .failure(let error):
                    self.errorMessage = "Ошибка загрузки профиля: \(error.localizedDescription)"
                }
            }
        }
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: "access_token")
        isLoggedOut = true
    }
}

//
//struct ProfileView: View {
//    var body: some View {
//        VStack {
//            Spacer()
//            Text("Личный кабинет")
//                .font(.largeTitle)
//                .padding()
//            Text("Здесь будет информация о пользователе")
//                .foregroundColor(.gray)
//            Spacer()
//        }
//        .navigationTitle("Профиль")
//        .navigationBarBackButtonHidden(false) // Показывает стандартную кнопку "назад"
//    }
//}




struct OutfitsView: View {
    var body: some View {
        NavigationView {
            VStack {
//                Text("Ваши образы")
//                    .font(.largeTitle)
//                    .padding()

                Spacer()

                Text("Здесь будут отображаться ваши сохраненные образы")
                    .foregroundColor(.gray)

                Spacer()

//                Button(action: {
//                    // Действие для создания нового образа
//                }) {
//                    Text("Создать образ")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(10)
//                }
//                .padding()
            }
            .navigationTitle("Избранное")
            
            .navigationTitle("Рекомендации")
            .navigationBarItems(trailing:
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.circle")
                        .font(.title)
                }
            )
            
        }
    }
}





struct WardrobeView: View {
    // Временно закомментируем использование DataStore
    // @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationView {
            VStack {
                Text("Ваш гардероб")
                    .font(.largeTitle)
                    .padding()

                Spacer()

                Text("Здесь будет отображаться ваша одежда")
                    .foregroundColor(.gray)

                Spacer()

                Button(action: {
                    // Действие для добавления новой одежды
                }) {
                    Text("Добавить одежду")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Гардероб")
            
//            .navigationBarItems(trailing: Button(action: {
//                // Действие для фильтрации
//            }) {
//                Image(systemName: "line.3.horizontal.decrease.circle")
//            })
            
            .navigationTitle("Рекомендации")
            .navigationBarItems(trailing:
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.circle")
                        .font(.title)
                }
            )
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
