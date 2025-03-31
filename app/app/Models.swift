import Foundation
import GRDB
import UIKit


struct Product: FetchableRecord, Decodable, Identifiable {
    let id: Int
    let name: String
    let color: String
    let price: String
    let store: String
    let url: String
}

struct User: Codable {
    let id: Int
    let email: String
    let name: String
    let color_type: String?
    let onboarding_completed: Bool
}

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
    let user: User
}

struct APIErrorDetail: Codable {
    let loc: [String]
    let msg: String
    let type: String
}

struct APIErrorResponse: Codable {
    let detail: [APIErrorDetail]
}




struct TestAnswer: Codable {
    let question_id: Int
    let selected_option_id: Int
}

struct TestResultRequest: Codable {
    let answers: [TestAnswer]
}

struct TestResultResponse: Codable {
    let color_type: String
    let description: String
    let recommended_colors: [String]
    let avoid_colors: [String]
}

struct ColorTypeResponse: Codable {
    let color_type: String
    let description: String
    let recommended_colors: [String]
    let avoid_colors: [String]
}

struct WardrobeImageItem: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let description: String
}


struct WardrobeItem: Codable, FetchableRecord, PersistableRecord, Identifiable, Hashable {
    var id: Int64?
    let color: String
    let type: String
    let imagePath: String
    let createdAt: Date

    // ✅ Указываем имя таблицы
    static let databaseTableName = "wardrobe"

    // ✅ Явно указываем соответствие между свойствами и столбцами
    enum CodingKeys: String, CodingKey {
        case id
        case color
        case type
        case imagePath = "image_path"
        case createdAt = "created_at"
    }

    // ✅ Получение изображения
    func getImage() -> UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(imagePath)
        return UIImage(contentsOfFile: url.path)
    }
    
    
//    func getImage() -> UIImage? {
//        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let fileURL = documentsURL.appendingPathComponent(imagePath)
//        return UIImage(contentsOfFile: fileURL.path)
//    }
}





//struct WardrobeItem: Codable, FetchableRecord, PersistableRecord {
//    var id: Int64?
//    let color: String
//    let type: String
//    let imagePath: String
//    let createdAt: Date
//
//    enum CodingKeys: String, CodingKey {
//        case id, color, type
//        case imagePath = "image_path"
//        case createdAt = "created_at"
//    }
//
//    func getImage() -> UIImage? {
//        let documentsURL = FileManager.default.urls(
//            for: .documentDirectory,
//            in: .userDomainMask
//        ).first!
//        let fileURL = documentsURL.appendingPathComponent(imagePath)
//        return UIImage(contentsOfFile: fileURL.path)
//    }
//}

