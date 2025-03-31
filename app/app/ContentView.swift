import SwiftUI
import PhotosUI
import UIKit

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
    @State private var colorType: String = ""
    @State private var imageItems: [ImageItem] = []
    @State private var isLoading = true
    @State private var selectedImageItem: ImageItem? = nil

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Загрузка рекомендаций...")
                } else if colorType.isEmpty {
                    VStack {
                        Spacer()
                        Text("Здесь будут отображаться\nрекомендованные образы")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(imageItems, id: \.fileName) { item in
                                Button(action: {
                                    selectedImageItem = item
                                }) {
                                    Image(uiImage: item.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Рекомендации")
            .navigationBarItems(trailing:
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.circle")
                        .font(.title)
                }
            )
            .sheet(item: $selectedImageItem) { item in
                // ✅ Оборачиваем в NavigationView, чтобы отображалась toolbar
                NavigationView {
                    ImageDetailView(imageItem: item)
                }
            }
        }
        .onAppear {
            loadColorTypeAndImages()
        }
    }

    func loadColorTypeAndImages() {
        isLoading = true
        APIService.shared.fetchColorType { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.colorType = response.color_type.lowercased()
                    self.imageItems = loadImagesFromFolder(named: self.colorType)
                case .failure(let error):
                    print("Ошибка загрузки color_type: \(error.localizedDescription)")
                    self.colorType = ""
                    self.imageItems = []
                }
                self.isLoading = false
            }
        }
    }

    func loadImagesFromFolder(named folderName: String) -> [ImageItem] {
        var items: [ImageItem] = []

        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        let folderPath = "\(resourcePath)/looks/\(folderName)"

        do {
            let fileManager = FileManager.default
            let imagePaths = try fileManager.contentsOfDirectory(atPath: folderPath)

            for imageName in imagePaths {
                let fullPath = "\(folderPath)/\(imageName)"
                if let image = UIImage(contentsOfFile: fullPath) {
                    let item = ImageItem(image: image, fileName: imageName)
                    items.append(item)
                }
            }
        } catch {
            print("Ошибка загрузки изображений из папки \(folderName): \(error.localizedDescription)")
        }

        return items
    }
}

struct ImageItem: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let fileName: String
}


struct ImageDetailView: View {
    let imageItem: ImageItem
    @State private var products: [Product] = []
    @State private var isFavorite = false
    @State private var lookId: Int? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(uiImage: imageItem.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200)
                    .cornerRadius(12)
                    .padding()

                if products.isEmpty {
                    Text("Нет информации о продуктах")
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Продукты в образе:")
                            .font(.headline)

                        ForEach(products) { product in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🛍 \(product.name)")
                                    .font(.subheadline)
                                    .bold()
                                Text("🎨 Цвет: \(product.color)")
                                Text("💰 Цена: \(product.price)")
                                Text("🏬 Магазин: \(product.store)")
                                Link("🔗 Перейти", destination: URL(string: product.url)!)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
        .navigationTitle("Образ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .gray)
                }
            }
        }
        .onAppear {
            loadProducts()
            checkIfFavorite()
        }
    }

    private func loadProducts() {
        let idString = imageItem.fileName.components(separatedBy: ".").first ?? ""
        if let id = Int(idString) {
            self.lookId = id
            self.products = DatabaseManager.shared.fetchProducts(forLookId: id)
        }
    }

    private func checkIfFavorite() {
        let idString = imageItem.fileName.components(separatedBy: ".").first ?? ""
        guard let id = Int(idString) else { return }

        APIService.shared.fetchFavorites { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let favorites):
                    self.isFavorite = favorites.contains(id)
                case .failure(let error):
                    print("❌ Ошибка загрузки избранного: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func toggleFavorite() {
        guard let id = lookId else { return }

        if isFavorite {
            //Удаляем из избранного
            APIService.shared.removeFavorite(outfitId: id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let message):
                        self.isFavorite = false
                    case .failure(let error):
                        print("❌ Ошибка удаления из избранного: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            //Добавляем в избранное
            APIService.shared.addFavorite(outfitId: id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let message):
                        self.isFavorite = true
                    case .failure(let error):
                        print("❌ Ошибка добавления в избранное: \(error.localizedDescription)")
                    }
                }
            }
        }
    }


//    private func toggleFavorite() {
//        guard let id = lookId else { return }
//
//        isFavorite.toggle()
//
//        guard let url = URL(string: "\(APIService.shared.baseURL)/api/users/me/favorites/\(id)") else {
//            print("❌ Неверный URL")
//            return
//        }
//
//        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
//            print("❌ Нет токена")
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("❌ Ошибка запроса: \(error.localizedDescription)")
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("❌ Неверный ответ")
//                return
//            }
//
//            if httpResponse.statusCode == 200 {
//                print("✅ Образ добавлен в избранное")
//            } else {
//                print("❌ Ошибка: \(httpResponse.statusCode)")
//                if let data = data,
//                   let errorMessage = String(data: data, encoding: .utf8) {
//                    print("🔍 Ответ сервера: \(errorMessage)")
//                }
//            }
//        }
//
//        task.resume()
//    }
}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




//struct RecView: View {
//    @State private var colorType: String = ""
//    @State private var imageItems: [ImageItem] = []
//    @State private var isLoading = true
//    @State private var selectedImageItem: ImageItem? = nil
//
//    var body: some View {
//        NavigationView {
//            Group {
//                if isLoading {
//                    ProgressView("Загрузка рекомендаций...")
//                } else if colorType.isEmpty {
//                    VStack {
//                        Spacer()
//                        Text("Здесь будут отображаться\nрекомендованные образы")
//                            .foregroundColor(.gray)
//                            .multilineTextAlignment(.center)
//                        Spacer()
//                    }
//                } else {
//                    ScrollView {
//                        LazyVStack(spacing: 16) {
//                            ForEach(imageItems, id: \.fileName) { item in
//                                Button(action: {
//                                    selectedImageItem = item
//                                }) {
//                                    Image(uiImage: item.image)
//                                        .resizable()
//                                        .aspectRatio(contentMode: .fit)
//                                        .cornerRadius(12)
//                                        .padding(.horizontal)
//                                }
//                            }
//                        }
//                        .padding(.top)
//                    }
//                }
//            }
//            .navigationTitle("Рекомендации")
//            .navigationBarItems(trailing:
//                NavigationLink(destination: ProfileView()) {
//                    Image(systemName: "person.circle")
//                        .font(.title)
//                }
//            )
//            .sheet(item: $selectedImageItem) { item in
//                ImageDetailView(imageItem: item)
//            }
//        }
//        .onAppear {
//            loadColorTypeAndImages()
//        }
//    }
//
//    func loadColorTypeAndImages() {
//        isLoading = true
//        APIService.shared.fetchColorType { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let response):
//                    self.colorType = response.color_type.lowercased()
//                    self.imageItems = loadImagesFromFolder(named: self.colorType)
//                case .failure(let error):
//                    print("Ошибка загрузки color_type: \(error.localizedDescription)")
//                    self.colorType = ""
//                    self.imageItems = []
//                }
//                self.isLoading = false
//            }
//        }
//    }
//
//    func loadImagesFromFolder(named folderName: String) -> [ImageItem] {
//        var items: [ImageItem] = []
//
//        guard let resourcePath = Bundle.main.resourcePath else { return [] }
//        let folderPath = "\(resourcePath)/looks/\(folderName)"
//
//        do {
//            let fileManager = FileManager.default
//            let imagePaths = try fileManager.contentsOfDirectory(atPath: folderPath)
//
//            for imageName in imagePaths {
//                let fullPath = "\(folderPath)/\(imageName)"
//                if let image = UIImage(contentsOfFile: fullPath) {
//                    let item = ImageItem(image: image, fileName: imageName)
//                    items.append(item)
//                }
//            }
//        } catch {
//            print("Ошибка загрузки изображений из папки \(folderName): \(error.localizedDescription)")
//        }
//
//        return items
//    }
//}
//



//struct ImageItem: Identifiable, Hashable {
//    let id = UUID()
//    let image: UIImage
//    let fileName: String
//}


//struct ImageDetailView: View {
//    let imageItem: ImageItem
//    @State private var products: [Product] = []
//    @State private var isFavorite = false
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                Image(uiImage: imageItem.image)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(maxWidth: 200)
//                    .cornerRadius(12)
//                    .padding()
//
//                if products.isEmpty {
//                    Text("Нет информации о продуктах")
//                        .foregroundColor(.secondary)
//                } else {
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Продукты в образе:")
//                            .font(.headline)
//
//                        ForEach(products) { product in
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("🛍 \(product.name)")
//                                    .font(.subheadline)
//                                    .bold()
//                                Text("🎨 Цвет: \(product.color)")
//                                Text("💰 Цена: \(product.price)")
//                                Text("🏬 Магазин: \(product.store)")
//                                Link("🔗 Перейти", destination: URL(string: product.url)!)
//                            }
//                            .padding()
//                            .background(Color(.systemGray6))
//                            .cornerRadius(10)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//
//                Spacer()
//            }
//        }
//        .navigationTitle("Образ")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(action: {
//                    toggleFavorite()
//                }) {
//                    Image(systemName: isFavorite ? "heart.fill" : "heart")
//                        .foregroundColor(isFavorite ? .red : .gray)
//                }
//            }
//        }
//        .onAppear {
//            loadProducts()
//        }
//    }
//
//    private func loadProducts() {
//        let idString = imageItem.fileName.components(separatedBy: ".").first ?? ""
//        if let lookId = Int(idString) {
//            self.products = DatabaseManager.shared.fetchProducts(forLookId: lookId)
//        }
//    }
//
//    private func toggleFavorite() {
//        isFavorite.toggle()
//
//        let idString = imageItem.fileName.components(separatedBy: ".").first ?? ""
//        guard let lookId = Int(idString) else {
//            print("❌ Невозможно извлечь ID из имени файла")
//            return
//        }
//
//        guard let url = URL(string: "http://92.63.176.126:8000/api/users/me/favorites/\(lookId)") else {
//            print("❌ Неверный URL")
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        // Если нужен токен авторизации:
//        // request.setValue("Bearer \(yourToken)", forHTTPHeaderField: "Authorization")
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("❌ Ошибка запроса: \(error.localizedDescription)")
//                return
//            }
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                print("❌ Неверный ответ")
//                return
//            }
//
//            if httpResponse.statusCode == 200 {
//                print("✅ Образ добавлен в избранное")
//            } else {
//                print("❌ Ошибка: \(httpResponse.statusCode)")
//                if let data = data,
//                   let errorMessage = String(data: data, encoding: .utf8) {
//                    print("🔍 Ответ сервера: \(errorMessage)")
//                }
//            }
//        }
//
//        task.resume()
//    }
//}
//
//


//
//struct ImageDetailView: View {
//    let imageItem: ImageItem
//    @State private var products: [Product] = []
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                Image(uiImage: imageItem.image)
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(maxWidth: 200)
//                    .cornerRadius(12)
//                    .padding()
//
////                Text("Имя файла: \(imageItem.fileName)")
////                    .font(.subheadline)
////                    .foregroundColor(.gray)
//
//                if products.isEmpty {
//                    Text("Нет информации о продуктах")
//                        .foregroundColor(.secondary)
//                } else {
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Продукты в образе:")
//                            .font(.headline)
//
//                        ForEach(products) { product in
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("🛍 \(product.name)")
//                                    .font(.subheadline)
//                                    .bold()
//                                Text("🎨 Цвет: \(product.color)")
//                                Text("💰 Цена: \(product.price)")
//                                Text("🏬 Магазин: \(product.store)")
//                                Link("🔗 Перейти", destination: URL(string: product.url)!)
//                            }
//                            .padding()
//                            .background(Color(.systemGray6))
//                            .cornerRadius(10)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//
//                Spacer()
//            }
//        }
//        .onAppear {
//            loadProducts()
//        }
//    }
//
//    private func loadProducts() {
//        // Извлекаем ID из имени файла (например, "14.jpg" → 14)
//        let idString = imageItem.fileName.components(separatedBy: ".").first ?? ""
//        if let lookId = Int(idString) {
//            self.products = DatabaseManager.shared.fetchProducts(forLookId: lookId)
//        }
//    }
//}


//// Экран с деталями изображения
//struct ImageDetailView: View {
//    let imageItem: ImageItem
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Image(uiImage: imageItem.image)
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .cornerRadius(12)
//                .padding()
//
//            Text("Имя файла:")
//                .font(.headline)
//
//            Text(imageItem.fileName)
//                .font(.subheadline)
//                .foregroundColor(.gray)
//                .multilineTextAlignment(.center)
//
//            Spacer()
//        }
//        .padding()
//    }
//}




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//struct RecView: View {
//    @State private var colorType: String = ""
//    @State private var images: [UIImage] = []
//    @State private var isLoading = true
//
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//
//    var body: some View {
//        NavigationView {
//            Group {
//                if isLoading {
//                    ProgressView("Загрузка рекомендаций...")
//                } else if colorType.isEmpty {
//                    VStack {
//                        Spacer()
//                        Text("Здесь будут отображаться\nрекомендованные образы")
//                            .foregroundColor(.gray)
//                        Spacer()
//                    }
//                } else {
//                    ScrollView {
//                        LazyVStack(spacing: 16) {
//                            ForEach(images, id: \.self) { image in
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .cornerRadius(12)
//                                    .padding(.horizontal)
//                            }
//                        }
//                        .padding(.top)
//                    }
//
//
//                }
//            }
//            .navigationTitle("Рекомендации")
//            .navigationBarItems(trailing:
//                NavigationLink(destination: ProfileView()) {
//                    Image(systemName: "person.circle")
//                        .font(.title)
//                }
//            )
//        }
//        .onAppear {
//            loadColorTypeAndImages()
//        }
//    }
//
//    func loadColorTypeAndImages() {
//        isLoading = true
//        APIService.shared.fetchColorType { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let response):
//                    self.colorType = response.color_type.lowercased()
//                    self.images = loadImagesFromFolder(named: self.colorType)
//                case .failure(let error):
//                    print("Ошибка загрузки color_type: \(error.localizedDescription)")
//                    self.colorType = ""
//                    self.images = []
//                }
//                self.isLoading = false
//            }
//        }
//    }
//
//    func loadImagesFromFolder(named folderName: String) -> [UIImage] {
//        var loadedImages: [UIImage] = []
//
//        guard let resourcePath = Bundle.main.resourcePath else { return [] }
//        let folderPath = "\(resourcePath)/looks/\(folderName)"
//
//        do {
//            let fileManager = FileManager.default
//            let imagePaths = try fileManager.contentsOfDirectory(atPath: folderPath)
//
//            for imageName in imagePaths {
//                let fullPath = "\(folderPath)/\(imageName)"
//                if let image = UIImage(contentsOfFile: fullPath) {
//                    loadedImages.append(image)
//                }
//            }
//        } catch {
//            print("Ошибка загрузки изображений из папки \(folderName): \(error.localizedDescription)")
//        }
//
//        return loadedImages
//    }
//}





//struct RecView: View {
//    var body: some View {
//        NavigationView {
//            VStack {
//                Spacer()
//                Text("Здесь будут отображаться\nрекомендованные образы")
//                    .foregroundColor(.gray)
//                Spacer()
//            }
//            .navigationTitle("Рекомендации")
//            .navigationBarItems(trailing:
//                NavigationLink(destination: ProfileView()) {
//                    Image(systemName: "person.circle")
//                        .font(.title)
//                }
//            )
//        }
//    }
//}




struct ProfileView: View {
    @State private var user: User?
    @State private var isLoggedOut = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            if let user = user {
                // Основная информация
                VStack(alignment: .leading, spacing: 10) {
                    Text("👤 \(user.name)")
//                        .font(.title2)
//                        .bold()
                    Text("📧 \(user.email)")
//                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                // Разделитель
                Divider()
                    .background(Color.gray)

                // Секция "Контакты"
                VStack(alignment: .leading, spacing: 10) {
                    Text("Контакты")
                        .font(.headline)
                        .padding(.bottom, 5)

                    HStack {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                        Text("example@gmail.com")
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Image(systemName: "paperplane")
                            .foregroundColor(.purple)
                        Text("@exampleTelegram")
                            .foregroundColor(.purple)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading) // Выровнено по левому краю
                .padding()

                Spacer()

                // Кнопка выхода
                Button(action: {
                    logout()
                }) {
                    Text("Выйти из аккаунта")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding([.leading, .trailing, .bottom])

                // Переход на экран входа
                NavigationLink(destination: LoginView(), isActive: $isLoggedOut) {
                    EmptyView()
                }
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                Spacer()
            } else {
                ProgressView("Загрузка профиля...")
                Spacer()
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




//struct ProfileView: View {
//    @State private var user: User?
//    @State private var isLoggedOut = false
//    @State private var errorMessage = ""
//
//    var body: some View {
//        VStack(spacing: 20) {
//            if let user = user {
//                Text("👤 Имя:  \(user.name)")
//                    .font(.title2)
//                Text("📧 Почта:  \(user.email)")
//                    .foregroundColor(.gray)
//            } else if !errorMessage.isEmpty {
//                Text(errorMessage)
//                    .foregroundColor(.red)
//            } else {
//                ProgressView("Загрузка профиля...")
//            }
//
//            Spacer()
//
//            Button("Выйти из аккаунта") {
//                logout()
//            }
//            .padding()
//            .background(Color.red)
//            .foregroundColor(.white)
//            .cornerRadius(10)
//
//            NavigationLink(destination: LoginView(), isActive: $isLoggedOut) {
//                EmptyView()
//            }
//        }
//        .padding()
//        .navigationTitle("Профиль")
//        .onAppear {
//            loadProfile()
//        }
//    }
//
//    func loadProfile() {
//        APIService.shared.fetchProfile { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let fetchedUser):
//                    self.user = fetchedUser
//                case .failure(let error):
//                    self.errorMessage = "Ошибка загрузки профиля: \(error.localizedDescription)"
//                }
//            }
//        }
//    }
//
//    func logout() {
//        UserDefaults.standard.removeObject(forKey: "access_token")
//        isLoggedOut = true
//    }
//}

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


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


struct OutfitsView: View {
    @State private var favoriteImageItems: [ImageItem] = []
    @State private var isLoading = true
    @State private var selectedImageItem: ImageItem? = nil
    @State private var colorType: String = ""

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Загрузка избранного...")
                } else if favoriteImageItems.isEmpty {
                    VStack {
                        Spacer()
                        Text("Здесь будут отображаться ваши сохраненные образы")
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(favoriteImageItems, id: \.fileName) { item in
                                Button(action: {
                                    selectedImageItem = item
                                }) {
                                    Image(uiImage: item.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: getGridItemWidth(), height: getGridItemHeight())
                                        .clipped()
                                        .cornerRadius(10)
                                }
                            }
                        }
                        .padding()
                    }



                }
            }
            .navigationTitle("Избранное")
            .navigationBarItems(trailing:
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.circle")
                        .font(.title)
                }
            )
            .sheet(item: $selectedImageItem) { item in
                NavigationView {
                    ImageDetailView(imageItem: item)
                }
            }
        }
        .onAppear {
            loadFavorites()
        }
    }
    
    private func getGridItemWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 16 * 3 // отступы + между колонками
        return (screenWidth - spacing) / 2
    }

    private func getGridItemHeight() -> CGFloat {
        return getGridItemWidth() * 4 / 3
    }



    private func loadFavorites() {
        isLoading = true

        // Сначала получаем colorType
        APIService.shared.fetchColorType { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.colorType = response.color_type.lowercased()
                    fetchFavoriteIDs()
                case .failure(let error):
                    print("❌ Ошибка получения colorType: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }

    private func fetchFavoriteIDs() {
        APIService.shared.fetchFavorites { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ids):
                    self.favoriteImageItems = loadImagesByIDs(ids: ids, folderName: self.colorType)
                case .failure(let error):
                    print("❌ Ошибка загрузки избранного: \(error.localizedDescription)")
                    self.favoriteImageItems = []
                }
                self.isLoading = false
            }
        }
    }
    private func loadImagesByIDs(ids: [Int], folderName: String) -> [ImageItem] {
        var items: [ImageItem] = []

        guard let resourcePath = Bundle.main.resourcePath else {
            print("❌ Не найден путь к ресурсам")
            return []
        }

        let folderPath = "\(resourcePath)/looks/\(folderName)"

        do {
            let fileManager = FileManager.default
            let imagePaths = try fileManager.contentsOfDirectory(atPath: folderPath)

            for id in ids {
                // Ищем файл, в названии которого есть ID
                if let fileName = imagePaths.first(where: { $0.contains("\(id)") }) {
                    let fullPath = "\(folderPath)/\(fileName)"
                    if let image = UIImage(contentsOfFile: fullPath) {
                        let item = ImageItem(image: image, fileName: fileName)
                        items.append(item)
                    } else {
                        print("⚠️ Не удалось загрузить изображение: \(fileName)")
                    }
                } else {
                    print("❌ Файл с ID \(id) не найден в папке \(folderName)")
                }
            }
        } catch {
            print("❌ Ошибка чтения папки: \(error.localizedDescription)")
        }

        return items
    }


//    private func loadImagesByIDs(ids: [Int], folderName: String) -> [ImageItem] {
//        var items: [ImageItem] = []
//
//        guard let resourcePath = Bundle.main.resourcePath else { return [] }
//        let folderPath = "\(resourcePath)/looks/\(folderName)"
//
//        do {
//            let fileManager = FileManager.default
//            let imagePaths = try fileManager.contentsOfDirectory(atPath: folderPath)
//
//            for id in ids {
//                let fileName = "\(id)"
//                if imagePaths.contains(fileName) {
//                    let fullPath = "\(folderPath)/\(fileName)"
//                    if let image = UIImage(contentsOfFile: fullPath) {
//                        let item = ImageItem(image: image, fileName: fileName)
//                        items.append(item)
//                    }
//                }
//            }
//        } catch {
//            print("❌ Ошибка загрузки изображений: \(error.localizedDescription)")
//        }
//
//        return items
//    }
}


//struct OutfitsView: View {
//    var body: some View {
//        NavigationView {
//            VStack {
////                Text("Ваши образы")
////                    .font(.largeTitle)
////                    .padding()
//
//                Spacer()
//
//                Text("Здесь будут отображаться ваши сохраненные образы")
//                    .foregroundColor(.gray)
//
//                Spacer()
//
////                Button(action: {
////                    // Действие для создания нового образа
////                }) {
////                    Text("Создать образ")
////                        .font(.headline)
////                        .foregroundColor(.white)
////                        .padding()
////                        .background(Color.blue)
////                        .cornerRadius(10)
////                }
////                .padding()
//            }
//            .navigationTitle("Избранное")
//
//            .navigationTitle("Рекомендации")
//            .navigationBarItems(trailing:
//                NavigationLink(destination: ProfileView()) {
//                    Image(systemName: "person.circle")
//                        .font(.title)
//                }
//            )
//
//        }
//    }
//}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



struct WardrobeView: View {
    @State private var wardrobeItems: [WardrobeItem] = []
    @State private var selectedItem: WardrobeItem? = nil
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var pendingImage: UIImage? = nil
    @State private var showConfirmationSheet = false
    @State private var showInvalidAspectRatioAlert = false
    
//    @State private var selectedPickerItem: PhotosPickerItem? = nil
    

    // Выбор цвета и типа
    @State private var selectedColor: ClothingColor? = nil
    @State private var selectedType: ClothingType? = nil

    let imagesFolderName = "WardrobeImages"
    private let requiredAspectRatio: CGFloat = 3.0 / 2.0

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 115))], spacing: 16) {
                    ForEach(wardrobeItems) { item in
                        if let image = item.getImage() {
                            Button(action: {
                                selectedItem = item
                            }) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 115, height: 115)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    
                }
                .padding()
                
                PhotosPicker(
                    selection: $selectedPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Добавить одежду")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.bottom)
                .onChange(of: selectedPickerItem) { newItem in
                    Task {
                        if let newItem = newItem,
                           let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {

                            if hasValidAspectRatio(image) {
                                DispatchQueue.main.async {
                                    pendingImage = image
                                    showConfirmationSheet = true
                                }
                            } else {
                                showInvalidAspectRatioAlert = true
                            }
                        }
                        selectedItem = nil
                    }
                }
                
            }
            .navigationTitle("Гардероб")
            .navigationBarItems(trailing:
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.circle")
                        .font(.title)
                }
            )
            .onAppear {
                createImagesDirectoryIfNeeded()
                loadAllImages()
            }
            .alert("Неподходящее соотношение сторон", isPresented: $showInvalidAspectRatioAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Пожалуйста, выберите фото с соотношением сторон 3:2")
            }
            
            .sheet(isPresented: $showConfirmationSheet) {
                ConfirmationView(
                    isPresented: $showConfirmationSheet,
                    image: $pendingImage,
                    onConfirm: {
                        if let image = pendingImage {
                            saveImageAndInsertToDatabase(image: image)
                            loadAllImages()
                        }
                        pendingImage = nil
                    },
                    selectedColor: $selectedColor,
                    selectedType: $selectedType
                )
            }

            
//            .sheet(isPresented: $showConfirmationSheet) {
//                ConfirmationView(
//                    isPresented: $showConfirmationSheet,
//                    image: $pendingImage,
//                    onConfirm: {
//                        if let image = pendingImage {
//                            saveImageAndInsertToDatabase(image: image)
//                            loadAllImages()
//                        }
//                        pendingImage = nil
//                    },
//                    selectedColor: $selectedColor,
//                    selectedType: $selectedType
//                )
//            }
            
            .sheet(item: $selectedItem) { item in
                NavigationStack {
                    WardrobeItemDetailView(item: item)
                }
            }

//            .sheet(item: $selectedItem) { item in
//                WardrobeItemDetailView(item: item)
//            }
        }
        
//        .photosPicker(isPresented: .constant(false), selection: $selectedPickerItem)
//        .onChange(of: selectedPickerItem) { newItem in
//            Task {
//                if let data = try? await newItem?.loadTransferable(type: Data.self),
//                   let image = UIImage(data: data) {
//                    if isValidAspectRatio(image: image) {
//                        pendingImage = image
//                        showConfirmationSheet = true
//                    } else {
//                        showInvalidAspectRatioAlert = true
//                    }
//                }
//            }
//        }
        


        
        
        
        
    }

    // MARK: - Загрузка из БД
    private func loadAllImages() {
        let items = DatabaseManager.shared.fetchAllWardrobeItems()
        DispatchQueue.main.async {
            self.wardrobeItems = items
        }
    }

    // MARK: - Сохранение изображения и данных в БД
    private func saveImageAndInsertToDatabase(image: UIImage) {
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName).appendingPathComponent(fileName)

        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)

                let item = WardrobeItem(
                    color: selectedColor?.name ?? "Неизвестно",
                    type: selectedType?.name ?? "Неизвестно",
                    imagePath: "\(imagesFolderName)/\(fileName)",
                    createdAt: Date()
                )

                DatabaseManager.shared.insertWardrobeItem(item)
            } catch {
                print("❌ Ошибка при сохранении изображения: \(error)")
            }
        }
    }

    // MARK: - Проверка соотношения сторон
    private func isValidAspectRatio(image: UIImage) -> Bool {
        let aspectRatio = image.size.width / image.size.height
        let targetRatio: CGFloat = 3.0 / 2.0
        return abs(aspectRatio - targetRatio) < 0.1
    }

    // MARK: - Создание папки
    private func createImagesDirectoryIfNeeded() {
        let folderURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                print("❌ Ошибка создания папки: \(error)")
            }
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // Проверка соотношения сторон (остаётся без изменений)
    private func hasValidAspectRatio(_ image: UIImage) -> Bool {
        let imageAspectRatio = image.size.width / image.size.height
        return abs(imageAspectRatio - requiredAspectRatio) <= 0.1
    }

}




//struct WardrobeView: View {
//    @State private var selectedItem: PhotosPickerItem? = nil
//    @State private var images: [UIImage] = []
//    @State private var showInvalidAspectRatioAlert = false
//    @State private var showConfirmationSheet = false
//    @State private var pendingImage: UIImage? = nil
//    @State private var selectedImageItem: WardrobeImageItem? = nil
//    @State private var wardrobeItems: [WardrobeItem] = []
//    @State private var selectedItem: WardrobeItem? = nil
//
//
//
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//
//    private let imagesFolderName = "WardrobeImages"
//    private let requiredAspectRatio: CGFloat = 3.0 / 2.0
//
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack {
//                    Text("Ваш гардероб")
//                        .font(.largeTitle)
//                        .padding()
//
//                    if images.isEmpty {
//                        Text("Здесь будет отображаться ваша одежда")
//                            .foregroundColor(.gray)
//                            .padding(.top, 50)
//                    } else {
//                        LazyVGrid(columns: columns, spacing: 10) {
//                            ForEach(wardrobeItems) { item in
//                                if let image = item.getImage() {
//                                    Button(action: {
//                                        selectedItem = item
//                                    }) {
//                                        Image(uiImage: image)
//                                            .resizable()
//                                            .scaledToFill()
//                                            .frame(width: 115, height: 115)
//                                            .clipped()
//                                            .cornerRadius(8)
//                                    }
//                                }
//                            }
//
////                            ForEach(images, id: \.self) { image in
////                                Image(uiImage: image)
////                                    .resizable()
////                                    .scaledToFill()
////                                    .frame(width: 115, height: 115)
////                                    .clipped()
////                                    .cornerRadius(8)
////                            }
//                        }
//                        .padding(.horizontal)
//                    }
//
//                    Spacer()
//
//                    PhotosPicker(
//                        selection: $selectedItem,
//                        matching: .images,
//                        photoLibrary: .shared()
//                    ) {
//                        Text("Добавить одежду")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.blue)
//                            .cornerRadius(10)
//                    }
//                    .padding()
//                    .onChange(of: selectedItem) { newItem in
//                        Task {
//                            if let newItem = newItem,
//                               let data = try? await newItem.loadTransferable(type: Data.self),
//                               let image = UIImage(data: data) {
//
//                                if hasValidAspectRatio(image) {
//                                    // Сохраняем фото во временную переменную
//                                    DispatchQueue.main.async {
//                                        pendingImage = image
//                                        showConfirmationSheet = true
//                                    }
//                                } else {
//                                    showInvalidAspectRatioAlert = true
//                                }
//                            }
//                            selectedItem = nil
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Гардероб")
//            .navigationBarItems(trailing:
//                NavigationLink(destination: ProfileView()) {
//                    Image(systemName: "person.circle")
//                        .font(.title)
//                }
//            )
//            .onAppear {
//                loadAllImages()
//            }
//            .alert("Неподходящее соотношение сторон", isPresented: $showInvalidAspectRatioAlert) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text("Пожалуйста, выберите фото с соотношением сторон 3:2")
//            }
//            .sheet(isPresented: $showConfirmationSheet) {
//                ConfirmationView(
//                    isPresented: $showConfirmationSheet,
//                    image: $pendingImage,
//                    onConfirm: {
//                        if let image = pendingImage {
//                            let fileName = "\(UUID().uuidString).jpg"
//                            let fileURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName).appendingPathComponent(fileName)
//
//                            if let data = image.jpegData(compressionQuality: 0.8) {
//                                try? data.write(to: fileURL)
//
//                                // Сохраняем в БД
//                                let item = WardrobeItem(
//                                    color: selectedColor?.name ?? "Неизвестно",
//                                    type: selectedType?.name ?? "Неизвестно",
//                                    imagePath: "\(imagesFolderName)/\(fileName)",
//                                    createdAt: Date()
//                                )
//                                DatabaseManager.shared.insertWardrobeItem(item)
//                            }
//
//                            loadAllImages()
//                        }
//                        pendingImage = nil
//                    }
//
////                    onConfirm: {
////                        if let image = pendingImage {
////                            saveImages([image])
////                            loadAllImages()
////                        }
////                        pendingImage = nil
////                    }
//                )
//            }
//            .sheet(item: $selectedItem) { item in
//                WardrobeItemDetailView(item: item)
//            }
//
//        }
//    }
//
//    // Проверка соотношения сторон (остаётся без изменений)
//    private func hasValidAspectRatio(_ image: UIImage) -> Bool {
//        let imageAspectRatio = image.size.width / image.size.height
//        return abs(imageAspectRatio - requiredAspectRatio) <= 0.1
//    }
//
//    // Работа с файлами
//    private func getDocumentsDirectory() -> URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//
//    private func createImagesDirectoryIfNeeded() {
//        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
//        if !FileManager.default.fileExists(atPath: directoryURL.path) {
//            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
//        }
//    }
//
//    private func saveImages(_ images: [UIImage]) {
//        createImagesDirectoryIfNeeded()
//        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
//
//        for image in images {
//            let fileName = "\(UUID().uuidString).jpg"
//            let fileURL = directoryURL.appendingPathComponent(fileName)
//
//            if let data = image.jpegData(compressionQuality: 0.8) {
//                try? data.write(to: fileURL)
//            }
//        }
//    }
//
//    private func loadAllImages() {
//        // Загружаем все элементы из базы данных
//        let items = DatabaseManager.shared.fetchAllWardrobeItems()
//
//        // Обновляем состояние
//        DispatchQueue.main.async {
//            self.wardrobeItems = items
//        }
//    }
//
//
////    private func loadAllImages() {
////        createImagesDirectoryIfNeeded()
////        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
////
////        do {
////            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
////            var loadedImages: [UIImage] = []
////
////            for fileURL in fileURLs {
////                if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData) {
////                    loadedImages.append(image)
////                }
////            }
////
////            DispatchQueue.main.async {
////                self.images = loadedImages
////            }
////        } catch {
////            print("Ошибка загрузки: \(error.localizedDescription)")
////        }
////    }
//}
//
//
//
//struct ImagePopupView: View {
//    let imageItem: WardrobeImageItem
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Image(uiImage: imageItem.image)
//                .resizable()
//                .scaledToFit()
//                .cornerRadius(12)
//                .padding()
//
//            Text(imageItem.description)
//                .font(.headline)
//                .multilineTextAlignment(.center)
//                .padding()
//
//            Spacer()
//        }
//        .presentationDetents([.medium, .large])
//        .presentationDragIndicator(.visible)
//    }
//}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
