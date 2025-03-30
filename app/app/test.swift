import SwiftUI

struct Question {
    let id: Int
    let text: String
    let options: [Option]
}

struct Option: Identifiable {
    let id: Int
    let text: String
}

struct TestView: View {
    @State private var currentQuestionIndex = 0
    @State private var selectedOptionId: Int? = nil
    @State private var answers: [TestAnswer] = []
    @State private var result: TestResultResponse? = nil
    @State private var navigateToMain = false
    @State private var isSubmitting = false

    let questions: [Question] = [
        Question(id: 1, text: "Какие цвета преобладают в Вашем гардеробе?", options: [
            Option(id: 1, text: "Пастельные оттенки"),
            Option(id: 2, text: "Базовые с акцентами"),
            Option(id: 3, text: "Яркие цвета и принты"),
            Option(id: 4, text: "Нет единого цвета")
        ]),
        Question(id: 2, text: "Какие верхние элементы одежды преобладают?", options: [
            Option(id: 5, text: "Рубашки, футболки поло, джемперы"),
            Option(id: 6, text: "Пиджаки, жилетки, рубашки"),
            Option(id: 7, text: "Свитшоты, джинсы, свитера, футболки"),
            Option(id: 8, text: "Зипки, толстовки, худи"),
            Option(id: 9, text: "Лонгсливы, футболки"),
            Option(id: 10, text: "Нет определенных вещей")
        ]),
        Question(id: 3, text: "Какие нижние элементы одежды преобладают?", options: [
            Option(id: 11, text: "Брюки"),
            Option(id: 12, text: "Спортивки, карго"),
            Option(id: 13, text: "Джинсы")
        ]),
        Question(id: 4, text: "Какую обувь вы предпочитаете?", options: [
            Option(id: 14, text: "Кроссовки и кеды"),
            Option(id: 15, text: "Мокасины и лоферы"),
            Option(id: 16, text: "Мартинсы и грубые ботинки")
        ]),
        Question(id: 5, text: "Какой формат верхней одежды вы предпочитаете?", options: [
            Option(id: 17, text: "Дутая куртка"),
            Option(id: 18, text: "Пальто"),
            Option(id: 19, text: "Дубленка"),
            Option(id: 20, text: "Бомбер")
        ]),
        Question(id: 6, text: "Какие аксессуары вы носите на регулярной основе?", options: [
            Option(id: 21, text: "Солнечные очки"),
            Option(id: 22, text: "Часы"),
            Option(id: 23, text: "Кепки и шапки"),
            Option(id: 24, text: "Барсетки, рюкзаки"),
            Option(id: 25, text: "Кожаные сумки и портфели"),
            Option(id: 26, text: "Цепочки, кольца"),
            Option(id: 27, text: "Галстуки"),
            Option(id: 28, text: "Не ношу аксессуары")
        ])
    ]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                if let result = result {
                    // Показ результата
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ваш стиль: \(result.color_type)")
                            .font(.title)
                        Text(result.description)
                        Text("Рекомендуем: \(result.recommended_colors.joined(separator: ", "))")
                        Text("Избегать: \(result.avoid_colors.joined(separator: ", "))")

                        Button("Перейти в приложение") {
                            navigateToMain = true
                        }
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)

                        NavigationLink(destination: ContentView(), isActive: $navigateToMain) {
                            EmptyView()
                        }
                    }
                } else {
                    // Показ вопроса
                    let question = questions[currentQuestionIndex]
                    Text(question.text)
                        .font(.title2)
                        .padding(.bottom)

                    ForEach(question.options) { option in
                        HStack {
                            Image(systemName: selectedOptionId == option.id ? "largecircle.fill.circle" : "circle")
                                .onTapGesture {
                                    selectedOptionId = option.id
                                }
                            Text(option.text)
                                .onTapGesture {
                                    selectedOptionId = option.id
                                }
                        }
                        .padding(.vertical, 4)
                    }

                    Spacer()

                    Button(action: {
                        if let selected = selectedOptionId {
                            let answer = TestAnswer(question_id: question.id, selected_option_id: selected)
                            answers.append(answer)
                            selectedOptionId = nil

                            if currentQuestionIndex + 1 < questions.count {
                                currentQuestionIndex += 1
                            } else {
                                // Последний вопрос — отправляем
                                isSubmitting = true
                                submitAnswers()
                            }
                        }
                    }) {
                        Text(currentQuestionIndex + 1 == questions.count ? "Завершить" : "Далее")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedOptionId == nil ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(selectedOptionId == nil || isSubmitting)
                }
            }
            .padding()
            .navigationBarTitle("Тест", displayMode: .inline)
        }
    }

    func submitAnswers() {
        APIService.shared.sendTestResults(answers: answers) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success(let response):
                    self.result = response
                case .failure(let error):
                    print("Ошибка отправки теста: \(error.localizedDescription)")
                }
            }
        }
    }
}
