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
                                let idString = item.fileName.components(separatedBy: ".").first ?? ""
                                let lookId = Int(idString) ?? -1

                                let value = percentile(for: lookId)
//                                let value = percentile()
                                let circleColor = colorForPercentile(value)
            

                                Button(action: {
                                    selectedImageItem = item
                                }) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(uiImage: item.image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .cornerRadius(12)
                                            .padding(.horizontal)

                                        Circle()
                                            .fill(circleColor)
                                            .frame(width: 32, height: 32)
                                            .padding(8)
                                            .offset(x: -16)
                                    }
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

                NavigationView {
                    ImageDetailView(imageItem: item)
                }
            }
        }
        .onAppear {
            loadColorTypeAndImages()
        }
    }
    
    func percentile(for lookId: Int) -> Double {
        let ratio = DatabaseManager.shared.calculateOwnedItemRatio(forLookId: lookId)
        let thresholds: [Double] = [1.0, 0.5, 1.0/3.0, 0.0]
        let sorted = thresholds.sorted(by: >)
//        print(lookId, ratio)
        

        for value in sorted {
            if ratio >= value {
                return value
            }
        }

        return 0.0
    }

    
//    func percentile() -> Double {
//        let values: [Double] = [1.0, 0.5, 1.0/3.0, 0.0]
//        return values.randomElement()!
//    }

    
    func colorForPercentile(_ value: Double) -> Color {
        switch value {
        case 1.0:
            return .green
        case 0.5:
            return .yellow
        case 1.0/3.0:
            return .orange
        default:
            return .red
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
                    print(" Ошибка загрузки избранного: \(error.localizedDescription)")
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
                    case .success(let _):
                        self.isFavorite = false
                    case .failure(let error):
                        print("Ошибка удаления из избранного: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            //Добавляем в избранное
            APIService.shared.addFavorite(outfitId: id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let _):
                        self.isFavorite = true
                    case .failure(let error):
                        print("Ошибка добавления в избранное: \(error.localizedDescription)")
                    }
                }
            }
        }
    }


}



//struct ImageItem: Identifiable, Hashable {
//    let id = UUID()
//    let image: UIImage
//    let fileName: String
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
                    Text("При возникновении проблем обращайтесь: ")
//                        .font(.headline)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                Spacer()

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
        let spacing: CGFloat = 16 * 3
        return (screenWidth - spacing) / 2
    }

    private func getGridItemHeight() -> CGFloat {
        return getGridItemWidth() * 4 / 3
    }



    private func loadFavorites() {
        isLoading = true

        APIService.shared.fetchColorType { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.colorType = response.color_type.lowercased()
                    fetchFavoriteIDs()
                case .failure(let error):
                    print("Ошибка получения colorType: \(error.localizedDescription)")
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
                    print("Ошибка загрузки избранного: \(error.localizedDescription)")
                    self.favoriteImageItems = []
                }
                self.isLoading = false
            }
        }
    }
    private func loadImagesByIDs(ids: [Int], folderName: String) -> [ImageItem] {
        var items: [ImageItem] = []

        guard let resourcePath = Bundle.main.resourcePath else {
            print("Не найден путь к ресурсам")
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
                        print("Не удалось загрузить изображение: \(fileName)")
                    }
                } else {
                    print(" Файл с ID \(id) не найден в папке \(folderName)")
                }
            }
        } catch {
            print(" Ошибка чтения папки: \(error.localizedDescription)")
        }

        return items
    }


}






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
    private let requiredAspectRatio: CGFloat = 1.0 / 1.0

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
                Text("Пожалуйста, выберите фото с соотношением сторон 1:1")
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

            

            
            .sheet(item: $selectedItem) { item in
                NavigationStack {
                    WardrobeItemDetailView(item: item)
                }
            }


        }
        
        
    }

    //Загрузка из БД
    private func loadAllImages() {
        let items = DatabaseManager.shared.fetchAllWardrobeItems()
        DispatchQueue.main.async {
            self.wardrobeItems = items
        }
    }

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
                print("Ошибка при сохранении изображения: \(error)")
            }
        }
    }


    private func isValidAspectRatio(image: UIImage) -> Bool {
        let aspectRatio = image.size.width / image.size.height
        let targetRatio: CGFloat = 1.0 / 1.0
        return abs(aspectRatio - targetRatio) < 0.1
    }

    private func createImagesDirectoryIfNeeded() {
        let folderURL = getDocumentsDirectory().appendingPathComponent(imagesFolderName)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                print("Ошибка создания папки: \(error)")
            }
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    

    private func hasValidAspectRatio(_ image: UIImage) -> Bool {
        let imageAspectRatio = image.size.width / image.size.height
        return abs(imageAspectRatio - requiredAspectRatio) <= 0.1
    }

}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
