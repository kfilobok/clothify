//
//  APIService.swift

import Foundation

class APIService {
    static let shared = APIService()
    private init() {}

    let baseURL = "http://92.63.176.126:8000" // http://92.63.176.126:8000/docs

    func register(email: String, password: String, name: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/auth/register") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "email": email,
            "password": password,
            "name": name
        ]

        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func login(email: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/auth/login") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "email": email,
            "password": password
        ]

        request.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            do {
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
  

    
    func fetchProfile(completion: @escaping (Result<User, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/auth/profile") else { return }
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            print("Нет токена")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
//            print(String(data: data, encoding: .utf8) ?? "Нет данных")

            guard let data = data else { return }



            do {
                let user = try JSONDecoder().decode(User.self, from: data)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func sendTestResults(answers: [TestAnswer], completion: @escaping (Result<TestResultResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/colortype/results") else { return }
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            print("Нет токена")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let requestBody = TestResultRequest(answers: answers)

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            do {
                let result = try JSONDecoder().decode(TestResultResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchColorType(completion: @escaping (Result<ColorTypeResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/users/me/colortype") else { return }
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            print("Нет токена")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }
//            print(data)
//            if let responseString = String(data: data, encoding: .utf8) {
//                print("Ответ от сервера: \(responseString)")
//            } else {
//                print("Не удалось преобразовать данные в строку")
//            }


            do {
                let result = try JSONDecoder().decode(ColorTypeResponse.self, from: data)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func addFavorite(outfitId: Int, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/users/me/favorites/\(outfitId)") else { return }
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            print("Нет токена")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            if let responseString = String(data: data, encoding: .utf8) {
                completion(.success(responseString))
            } else {
                completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
            }
        }.resume()
    }

    
    func fetchFavorites(completion: @escaping (Result<[Int], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/users/me/favorites") else { return }
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            print("Нет токена")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            do {
                let favorites = try JSONDecoder().decode([Int].self, from: data)
                completion(.success(favorites))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func removeFavorite(outfitId: Int, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/users/me/favorites/\(outfitId)") else { return }
        guard let token = UserDefaults.standard.string(forKey: "access_token") else {
            print("Нет токена")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else { return }

            if let responseString = String(data: data, encoding: .utf8) {
                completion(.success(responseString))
            } else {
                completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
            }
        }.resume()
    }



}
