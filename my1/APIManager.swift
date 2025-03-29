import Foundation

class APIManager {
    static let shared = APIManager()
    private let baseURL = "https://yourserver.com/api"

    func fetchUser(userId: Int, completion: @escaping (User?) -> Void) {
        guard let url = URL(string: "\(baseURL)/user?id=\(userId)") else {
            print("❌ Ошибка: неверный URL")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Ошибка запроса: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("❌ Ошибка: нет данных")
                completion(nil)
                return
            }

            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                DispatchQueue.main.async {
                    completion(user)
                }
            } catch {
                print("❌ Ошибка декодирования JSON: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
