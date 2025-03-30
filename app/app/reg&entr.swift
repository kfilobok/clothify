import SwiftUI

struct RegisterView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Регистрация")
                .font(.largeTitle)

            TextField("Имя", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
//                .disableAutocorrection(true)

            SecureField("Пароль", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button("Зарегистрироваться") {
                register()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

//            NavigationLink(destination: ContentView(), isActive: $isRegistered) {
//                EmptyView()
//            }
            NavigationLink(destination: TestView(), isActive: $isRegistered) {
                EmptyView()
            }

        }
        .padding()
    }

    func register() {
        APIService.shared.register(email: email, password: password, name: name) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    UserDefaults.standard.set(response.access_token, forKey: "access_token")
                    isRegistered = true
                case .failure(let error):
                    errorMessage = "Ошибка регистрации: \(error.localizedDescription)"
                }
            }
        }
    }
}



struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Вход")
                    .font(.largeTitle)

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
//                    .disableAutocorrection(true)

                SecureField("Пароль", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button("Войти") {
                    login()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)

                NavigationLink("Нет аккаунта? Зарегистрироваться", destination: RegisterView())

                NavigationLink(destination: ContentView(), isActive: $isLoggedIn) {
                    EmptyView()
                }
            }
            .padding()
        }
    }

    func login() {
        APIService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Сохраняем токен, если нужно
                    UserDefaults.standard.set(response.access_token, forKey: "access_token")
                    isLoggedIn = true
                case .failure(let error):
                    errorMessage = "Ошибка входа: \(error.localizedDescription)"
                }
            }
        }
    }
}

