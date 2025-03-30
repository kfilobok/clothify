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


