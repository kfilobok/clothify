import Foundation

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


