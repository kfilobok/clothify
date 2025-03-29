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
    
    // MARK: - Работа с файлами
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

// Новая структура для модального окна подтверждения
struct ConfirmationView: View {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Уже добавляем эту вещь в ваш гардероб")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.top, 30)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                    .padding()
                
//                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Занимает всё доступное пространство
//
//                                    .cornerRadius(12)
//                                    .padding(.horizontal, 20)
//                                    .shadow(radius: 5) // Добавляем тень для объёма
            }
            
            Spacer()
            
            Button(action: {
                onConfirm()
                isPresented = false
            }) {
                Text("Добавить предмет в гардероб")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
        .presentationDetents([.large])
    }
}






//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//struct WardrobeView: View {
//    @State private var selectedItem: PhotosPickerItem? = nil
//    @State private var images: [UIImage] = []
//    @State private var showInvalidAspectRatioAlert = false
//    @State private var showConfirmationDialog = false
//    @State private var pendingImage: UIImage? = nil
//
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//
//    private let imagesFolderName = "WardrobeImages"
//    private let requiredAspectRatio: CGFloat = 3.0 / 2.0
//    private let aspectRatioTolerance: CGFloat = 0.1
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
//                            ForEach(images, id: \.self) { image in
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(width: 100, height: 100)
//                                    .clipped()
//                                    .cornerRadius(8)
//                            }
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
//                                    DispatchQueue.main.async {
//                                        pendingImage = image
//                                        showConfirmationDialog = true
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
//            .sheet(isPresented: $showConfirmationDialog) {
//                if let image = pendingImage {
//                    AddItemConfirmationView(
//                        image: image,
//                        onAdd: {
//                            saveImages([image])
//                            loadAllImages()
//                            showConfirmationDialog = false
//                        },
//                        onCancel: {
//                            pendingImage = nil
//                            showConfirmationDialog = false
//                        }
//                    )
//                }
//            }
//        }
//    }
//    // Проверяем соотношение сторон 3:2 (с допустимым отклонением)
//    private func hasValidAspectRatio(_ image: UIImage) -> Bool {
//        let imageAspectRatio = image.size.width / image.size.height
//        return abs(imageAspectRatio - requiredAspectRatio) <= aspectRatioTolerance
//    }
//
//    private func getDocumentsDirectory() -> URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//    private func createImagesDirectoryIfNeeded() {
//        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
//
//        if !FileManager.default.fileExists(atPath: directoryURL.path) {
//            do {
//                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
//            } catch {
//                print("Не удалось создать директорию: \(error.localizedDescription)")
//            }
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
//                do {
//                    try data.write(to: fileURL)
//                } catch {
//                    print("Не удалось сохранить изображение: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    private func loadAllImages() {
//        createImagesDirectoryIfNeeded()
//        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
//
//        do {
//            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
//
//            var loadedImages: [UIImage] = []
//
//            for fileURL in fileURLs {
//                if let imageData = try? Data(contentsOf: fileURL),
//                   let image = UIImage(data: imageData) {
//                    loadedImages.append(image)
//                }
//            }
//
//            DispatchQueue.main.async {
//                self.images = loadedImages
//            }
//
//        } catch {
//            print("Не удалось загрузить изображения: \(error.localizedDescription)")
//        }
//    }
//}
//
//struct AddItemConfirmationView: View {
//    let image: UIImage
//    let onAdd: () -> Void
//    let onCancel: () -> Void
//
//    var body: some View {
//        VStack(spacing: 20) {
//            HStack {
//                Spacer()
//                Button(action: onCancel) {
//                    Image(systemName: "xmark")
//                        .font(.title2)
//                        .foregroundColor(.gray)
//                        .padding(8)
//                }
//            }
//
//            Image(uiImage: image)
//                .resizable()
//                .scaledToFit()
//                .frame(maxHeight: 300)
//                .cornerRadius(12)
//                .shadow(radius: 5)
//
//            Text("Уже добавляем эту вещь в ваш гардероб")
//                .font(.headline)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//
//            Button(action: onAdd) {
//                Text("Добавить предмет в гардероб")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//            .padding()
//
//            Spacer()
//        }
//        .padding()
//        .presentationDetents([.medium])
//        .presentationDragIndicator(.visible)
//    }
//}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//struct WardrobeView: View {
//    @State private var selectedItem: PhotosPickerItem? = nil
//    @State private var images: [UIImage] = []
//    @State private var showInvalidAspectRatioAlert = false
//
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//
//    private let imagesFolderName = "WardrobeImages"
//    private let requiredAspectRatio: CGFloat = 3.0 / 2.0
//    private let aspectRatioTolerance: CGFloat = 0.1 // Допустимое отклонение
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
//                            ForEach(images, id: \.self) { image in
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(width: 115, height: 115)
//                                    .clipped()
//                                    .cornerRadius(8)
//                            }
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
//                                // Проверяем соотношение сторон
//                                if hasValidAspectRatio(image) {
//                                    // Сохраняем новое изображение
//                                    saveImages([image])
//
//                                    // Загружаем все изображения
//                                    loadAllImages()
//                                } else {
//                                    // Показываем алерт о неверном соотношении
//                                    DispatchQueue.main.async {
//                                        showInvalidAspectRatioAlert = true
//                                    }
//                                }
//                            }
//
//                            selectedItem = nil
//                        }
//                    }
//                    .alert("Неподходящее соотношение сторон", isPresented: $showInvalidAspectRatioAlert) {
//                        Button("OK", role: .cancel) { }
//                    } message: {
//                        Text("Пожалуйста, выберите фото с соотношением сторон 3:2")
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
//        }
//    }
//
//    // Проверяем соотношение сторон 3:2 (с допустимым отклонением)
//    private func hasValidAspectRatio(_ image: UIImage) -> Bool {
//        let imageAspectRatio = image.size.width / image.size.height
//        return abs(imageAspectRatio - requiredAspectRatio) <= aspectRatioTolerance
//    }
//
//    // MARK: - File Management (остаётся без изменений)
//
//    private func getDocumentsDirectory() -> URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//    }
//
//    private func createImagesDirectoryIfNeeded() {
//        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
//
//        if !FileManager.default.fileExists(atPath: directoryURL.path) {
//            do {
//                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
//            } catch {
//                print("Не удалось создать директорию: \(error.localizedDescription)")
//            }
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
//                do {
//                    try data.write(to: fileURL)
//                } catch {
//                    print("Не удалось сохранить изображение: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    private func loadAllImages() {
//        createImagesDirectoryIfNeeded()
//        let directoryURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
//
//        do {
//            let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
//
//            var loadedImages: [UIImage] = []
//
//            for fileURL in fileURLs {
//                if let imageData = try? Data(contentsOf: fileURL),
//                   let image = UIImage(data: imageData) {
//                    loadedImages.append(image)
//                }
//            }
//
//            DispatchQueue.main.async {
//                self.images = loadedImages
//            }
//
//        } catch {
//            print("Не удалось загрузить изображения: \(error.localizedDescription)")
//        }
//    }
//}




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//struct WardrobeView: View {
//    // Временно закомментируем использование DataStore
//    // @EnvironmentObject var dataStore: DataStore
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Ваш гардероб")
//                    .font(.largeTitle)
//                    .padding()
//
//                Spacer()

//                Text("Здесь будет отображаться ваша одежда")
//                    .foregroundColor(.gray)
//
//                Spacer()
//
//                Button(action: {
//                    // Действие для добавления новой одежды
//                }) {
//                    Text("Добавить одежду")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(Color.blue)
//                        .cornerRadius(10)
//                }
//                .padding()
//            }
//            .navigationTitle("Гардероб")
//
////            .navigationBarItems(trailing: Button(action: {
////                // Действие для фильтрации
////            }) {
////                Image(systemName: "line.3.horizontal.decrease.circle")
////            })
//
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
