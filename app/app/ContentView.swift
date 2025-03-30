import SwiftUI
import PhotosUI

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
    @State private var images: [UIImage] = []
    @State private var isLoading = true

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

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
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
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
                    self.images = loadImagesFromFolder(named: self.colorType)
                case .failure(let error):
                    print("Ошибка загрузки color_type: \(error.localizedDescription)")
                    self.colorType = ""
                    self.images = []
                }
                self.isLoading = false
            }
        }
    }

    func loadImagesFromFolder(named folderName: String) -> [UIImage] {
        var loadedImages: [UIImage] = []

        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        let folderPath = "\(resourcePath)/looks/\(folderName)"

        do {
            let fileManager = FileManager.default
            let imagePaths = try fileManager.contentsOfDirectory(atPath: folderPath)

            for imageName in imagePaths {
                let fullPath = "\(folderPath)/\(imageName)"
                if let image = UIImage(contentsOfFile: fullPath) {
                    loadedImages.append(image)
                }
            }
        } catch {
            print("Ошибка загрузки изображений из папки \(folderName): \(error.localizedDescription)")
        }

        return loadedImages
    }
}





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


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


struct WardrobeView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var images: [UIImage] = []
    @State private var showInvalidAspectRatioAlert = false
    @State private var showConfirmationSheet = false
    @State private var pendingImage: UIImage? = nil // Фото, ожидающее подтверждения
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    private let imagesFolderName = "WardrobeImages"
    private let requiredAspectRatio: CGFloat = 3.0 / 2.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("Ваш гардероб")
                        .font(.largeTitle)
                        .padding()
                    
                    if images.isEmpty {
                        Text("Здесь будет отображаться ваша одежда")
                            .foregroundColor(.gray)
                            .padding(.top, 50)
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(images, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 115, height: 115)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    PhotosPicker(
                        selection: $selectedItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Добавить одежду")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let newItem = newItem,
                               let data = try? await newItem.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                
                                if hasValidAspectRatio(image) {
                                    // Сохраняем фото во временную переменную
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
            }
            .navigationTitle("Гардероб")
            .navigationBarItems(trailing:
                NavigationLink(destination: ProfileView()) {
                    Image(systemName: "person.circle")
                        .font(.title)
                }
            )
            .onAppear {
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
                            saveImages([image])
                            loadAllImages()
                        }
                        pendingImage = nil
                    }
                )
            }
        }
    }
    
    // Проверка соотношения сторон (остаётся без изменений)
    private func hasValidAspectRatio(_ image: UIImage) -> Bool {
        let imageAspectRatio = image.size.width / image.size.height
        return abs(imageAspectRatio - requiredAspectRatio) <= 0.1
    }
    
    // Работа с файлами
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func createImagesDirectoryIfNeeded() {
        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
    }
    
    private func saveImages(_ images: [UIImage]) {
        createImagesDirectoryIfNeeded()
        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
        
        for image in images {
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = directoryURL.appendingPathComponent(fileName)
            
            if let data = image.jpegData(compressionQuality: 0.8) {
                try? data.write(to: fileURL)
            }
        }
    }
    
    private func loadAllImages() {
        createImagesDirectoryIfNeeded()
        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            var loadedImages: [UIImage] = []
            
            for fileURL in fileURLs {
                if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData) {
                    loadedImages.append(image)
                }
            }
            
            DispatchQueue.main.async {
                self.images = loadedImages
            }
        } catch {
            print("Ошибка загрузки: \(error.localizedDescription)")
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
