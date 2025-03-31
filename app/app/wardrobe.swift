import Foundation
import SwiftUI



struct ClothingColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
}

struct ClothingType: Identifiable, Hashable {
    let id = UUID()
    let name: String
}


struct ConfirmationView: View {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    let onConfirm: () -> Void

    @Binding var selectedColor: ClothingColor?
    @Binding var selectedType: ClothingType?

    private let colorOptions: [ClothingColor] = [
        ClothingColor(name: "черный", color: .black),
        ClothingColor(name: "белый", color: .white),
        ClothingColor(name: "серый", color: .gray),
        ClothingColor(name: "синий", color: .blue),
        ClothingColor(name: "голубой", color: .cyan),
        ClothingColor(name: "зелёный", color: .green),
        ClothingColor(name: "желтый", color: .yellow),
        ClothingColor(name: "бежевый", color: Color(red: 0.99, green: 0.96, blue: 0.86)),
        ClothingColor(name: "коричневый", color: .brown),
        ClothingColor(name: "фиолетовый", color: .purple),
        ClothingColor(name: "красный", color: .red),
        ClothingColor(name: "розовый", color: Color(red: 0.98, green: 0.82, blue: 0.9)),
        ClothingColor(name: "оранжевый", color: .orange)
    ]

    private let typeOptions: [ClothingType] = [
        ClothingType(name: "футболка"),
        ClothingType(name: "майка"),
        ClothingType(name: "водолазка"),
        ClothingType(name: "рубашка"),
        ClothingType(name: "пиджак"),
        ClothingType(name: "жилетка"),
        ClothingType(name: "свитер"),
        ClothingType(name: "джемпер"),
        ClothingType(name: "бомбер"),
        ClothingType(name: "свитшот"),
        ClothingType(name: "спортивки"),
        ClothingType(name: "толстовка"),
        ClothingType(name: "брюки"),
        ClothingType(name: "джинсы"),
        ClothingType(name: "шорты")
    ]

    private var colorColumns: [[ClothingColor]] {
        stride(from: 0, to: colorOptions.count, by: 3).map {
            Array(colorOptions[$0..<min($0 + 3, colorOptions.count)])
        }
    }

    private var typeColumns: [[ClothingType]] {
        stride(from: 0, to: typeOptions.count, by: 3).map {
            Array(typeOptions[$0..<min($0 + 3, typeOptions.count)])
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }

            // Цвет
            VStack(alignment: .leading, spacing: 8) {
                Text("Цвет:")
                    .font(.headline)
                    .padding(.horizontal, 24)

                VStack(spacing: 5) {
                    ForEach(colorColumns, id: \.self) { row in
                        HStack(spacing: 5) {
                            ForEach(row) { option in
                                ColorChip(
                                    color: option,
                                    isSelected: selectedColor == option
                                ) {
                                    selectedColor = option
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if row.count < 3 {
                                ForEach(0..<(3 - row.count), id: \.self) { _ in
                                    Spacer().frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 5)
            }

            // Тип
            VStack(alignment: .leading, spacing: 8) {
                Text("Тип одежды:")
                    .font(.headline)
                    .padding(.horizontal, 24)

                VStack(spacing: 5) {
                    ForEach(typeColumns, id: \.self) { row in
                        HStack(spacing: 5) {
                            ForEach(row) { option in
                                TypeChip(
                                    type: option,
                                    isSelected: selectedType == option
                                ) {
                                    selectedType = option
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            if row.count < 3 {
                                ForEach(0..<(3 - row.count), id: \.self) { _ in
                                    Spacer().frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 5)
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
                    .background(selectedColor == nil ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .disabled(selectedColor == nil)
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .onAppear {
            selectedColor = getDefaultColor()
            selectedType = getDefaultType()
        }
        .padding(.vertical, 10)
        .presentationDetents([.large])
        .presentationCornerRadius(20)
    }

    // MARK: - Автовыбор цвета и типа

    private func getDefaultColor() -> ClothingColor {
        if let image = image {
            let dominantUIColor = analyzeImageColor(image)
            return closestColor(from: dominantUIColor)
        }
        return colorOptions.first!
    }

    private func getDefaultType() -> ClothingType? {
        return typeOptions.first
    }

    private func analyzeImageColor(_ image: UIImage) -> UIColor {
        guard let cgImage = image.cgImage else { return .gray }
        let inputImage = CIImage(cgImage: cgImage)

        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        guard let filter = CIFilter(
            name: "CIAreaAverage",
            parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]
        ),
        let outputImage = filter.outputImage else {
            return .gray
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
    }

    private func closestColor(from uiColor: UIColor) -> ClothingColor {
        let color = Color(uiColor)
        return colorOptions.min(by: { colorDistance(color, $0.color) < colorDistance(color, $1.color) }) ?? colorOptions[0]
    }

    private func colorDistance(_ color1: Color, _ color2: Color) -> CGFloat {
        let cg1 = UIColor(color1).cgColor.components ?? [0, 0, 0]
        let cg2 = UIColor(color2).cgColor.components ?? [0, 0, 0]

        let r = cg1[0] - cg2[0]
        let g = cg1[1] - cg2[1]
        let b = cg1[2] - cg2[2]

        return sqrt(r * r + g * g + b * b)
    }
}




//struct ConfirmationView: View {
//    @Binding var isPresented: Bool
//    @Binding var image: UIImage?
//
////    @State private var selectedColor: ClothingColor? = nil
////    @State private var selectedType: ClothingType? = nil
//
//    let onConfirm: () -> Void
//
//    @Binding var selectedColor: ClothingColor?
//    @Binding var selectedType: ClothingType?
//
//
//
//    private let colorOptions: [ClothingColor] = [
//        ClothingColor(name: "Чёрный", color: .black),
//        ClothingColor(name: "Белый", color: .white),
//        ClothingColor(name: "Серый", color: .gray),
//        ClothingColor(name: "Синий", color: .blue),
//        ClothingColor(name: "Голубой", color: .cyan),
//        ClothingColor(name: "Зеленый", color: .green),
//        ClothingColor(name: "Жёлтый", color: .yellow),
//        //ClothingColor(name: "Оливковый", color: .green),
//        ClothingColor(name: "Бежевый", color: Color(red: 0.99, green: 0.96, blue: 0.86)),
//        ClothingColor(name: "Коричневый", color: .brown),
//        ClothingColor(name: "Фиолетовый", color: .purple),
//        ClothingColor(name: "Красный", color: .red),
//        ClothingColor(name: "Розовый", color: Color(red: 0.98, green: 0.82, blue: 0.9)),
//        ClothingColor(name: "Оранжевый", color: .orange)
//    ]
//
//    private let typeOptions: [ClothingType] = [
//            ClothingType(name: "  Футболка"),
//            ClothingType(name: "  Майка"),
//            ClothingType(name: "  Водолазка"),
//            ClothingType(name: "  Рубашка"),
//            ClothingType(name: "  Пиджак"),
//            ClothingType(name: "  Жилетка"),
//            ClothingType(name: "  Свитер"),
//            ClothingType(name: "  Джемпер"),
//            ClothingType(name: "  Бомбер"),
//            ClothingType(name: "  Свитшот"),
//            ClothingType(name: "  Спортивки"),
//            ClothingType(name: "  Толстовка"),
//            ClothingType(name: "  Брюки"),
//            ClothingType(name: "  Джинсы"),
//            ClothingType(name: "  Шорты")
//        ]
//
//
//
//    // Разбиваем на группы по 3 для 3 колонок
//    private var colorColumns: [[ClothingColor]] {
//        stride(from: 0, to: colorOptions.count, by: 3).map {
//            Array(colorOptions[$0..<min($0 + 3, colorOptions.count)])
//        }
//    }
//
//    private var typeColumns: [[ClothingType]] {
//            stride(from: 0, to: typeOptions.count, by: 3).map {
//                Array(typeOptions[$0..<min($0 + 3, typeOptions.count)])
//            }
//        }
//
//
//    private func getDefaultColor() -> ClothingColor {
//        if let image = image {
//            let dominantUIColor = analyzeImageColor(image)
//            return closestColor(from: dominantUIColor)
//        }
//        return colorOptions.first ?? colorOptions[0]
//    }
//
//    var body: some View {
//        VStack(spacing: 16) {
////            Text("Уже добавляем эту вещь в ваш гардероб")
////                .font(.title2)
////                .multilineTextAlignment(.center)
////                .padding(.top, 20)
//
//            if let image = image {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxHeight: 220)
//                    .cornerRadius(12)
//                    .padding(.horizontal, 24)
//            }
//
//            // Секция выбора цвета с 3 колонками
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Цвет:")
//                    .font(.headline)
//                    .padding(.horizontal, 24)
//
//                // Три колонки с чипсами
//                VStack(spacing: 5) {
//                    ForEach(colorColumns, id: \.self) { row in
//                        HStack(spacing: 5) {
//                            ForEach(row) { option in
//                                ColorChip(
//                                    color: option,
//                                    isSelected: selectedColor == option
//                                ) {
//                                    selectedColor = option
//                                }
//
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                            }
//
//                            // Добавляем пустые View для выравнивания, если в строке меньше 3 элементов
//                            if row.count < 3 {
//                                ForEach(0..<(3 - row.count), id: \.self) { _ in
//                                    Spacer()
//                                        .frame(maxWidth: .infinity)
//                                }
//                            }
//                        }
//                    }
//                }
//                .padding(.horizontal, 5)
//            }
//
//            VStack(alignment: .leading, spacing: 8) {
//                            Text("Тип одежды:")
//                                .font(.headline)
//                                .padding(.horizontal, 24)
//
//                            VStack(spacing: 5) {
//                                ForEach(typeColumns, id: \.self) { row in
//                                    HStack(spacing: 5) {
//                                        ForEach(row) { option in
//                                            TypeChip(
//                                                type: option,
//                                                isSelected: selectedType == option
//                                            ) {
//                                                selectedType = option
//                                            }
//                                            .frame(maxWidth: .infinity, alignment: .leading)
//                                        }
//
//                                        if row.count < 3 {
//                                            ForEach(0..<(3 - row.count), id: \.self) { _ in
//                                                Spacer()
//                                                    .frame(maxWidth: .infinity)
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.horizontal, 5)
//                        }
//
//            Spacer()
//
//            Button(action: {
//                onConfirm()
//                isPresented = false
//            }) {
//                Text("Добавить предмет в гардероб")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(selectedColor == nil ? Color.gray : Color.blue)
//                    .cornerRadius(10)
//            }
//            .disabled(selectedColor == nil)
//            .padding(.horizontal, 24)
//            .padding(.bottom, 20)
//        }
//
//        .onAppear {
//                    // Устанавливаем значение по умолчанию при появлении
//                    selectedColor = getDefaultColor()
//                    selectedType = getDefaultType()
//                }
//        .padding(.vertical, 10)
//        .presentationDetents([.large])
//        .presentationCornerRadius(20)
//
//    }
//
//    private func getDefaultType() -> ClothingType? {
//            // Здесь можно добавить логику определения типа по изображению
//            // Пока просто возвращаем первый вариант
//            return typeOptions.first
//        }
//
//
//    private func analyzeImageColor(_ image: UIImage) -> UIColor {
//        // Упрощённый анализ - берём средний цвет
//        guard let cgImage = image.cgImage else { return .gray }
//        let inputImage = CIImage(cgImage: cgImage)
//
//        let extentVector = CIVector(
//            x: inputImage.extent.origin.x,
//            y: inputImage.extent.origin.y,
//            z: inputImage.extent.size.width,
//            w: inputImage.extent.size.height
//        )
//
//        guard let filter = CIFilter(
//            name: "CIAreaAverage",
//            parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]
//        ) else { return .gray }
//
//        guard let outputImage = filter.outputImage else { return .gray }
//
//        var bitmap = [UInt8](repeating: 0, count: 4)
//        let context = CIContext(options: [.workingColorSpace: kCFNull!])
//        context.render(
//            outputImage,
//            toBitmap: &bitmap,
//            rowBytes: 4,
//            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
//            format: .RGBA8,
//            colorSpace: nil
//        )
//
//        return UIColor(
//            red: CGFloat(bitmap[0]) / 255,
//            green: CGFloat(bitmap[1]) / 255,
//            blue: CGFloat(bitmap[2]) / 255,
//            alpha: CGFloat(bitmap[3]) / 255
//        )
//    }
//
//    private func closestColor(from uiColor: UIColor) -> ClothingColor {
//        let color = Color(uiColor) // Конвертируем UIColor в SwiftUI Color
//
//        // Простая реализация сравнения цветов (можно улучшить)
//        return colorOptions.min(by: { color1, color2 in
//            let distance1 = colorDistance(color, color1.color)
//            let distance2 = colorDistance(color, color2.color)
//            return distance1 < distance2
//        }) ?? colorOptions[0]
//    }
//
//    // Вспомогательная функция для сравнения цветов
//    private func colorDistance(_ color1: Color, _ color2: Color) -> CGFloat {
//        let cgColor1 = UIColor(color1).cgColor.components ?? [0,0,0,0]
//        let cgColor2 = UIColor(color2).cgColor.components ?? [0,0,0,0]
//
//        let rDiff = cgColor1[0] - cgColor2[0]
//        let gDiff = cgColor1[1] - cgColor2[1]
//        let bDiff = cgColor1[2] - cgColor2[2]
//
//        return sqrt(rDiff*rDiff + gDiff*gDiff + bDiff*bDiff)
//    }
//
//}



struct ColorChip: View {
    let color: ClothingColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color.color)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                
                Text(color.name)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading) // ← Выравнивание по левому краю
            .background(
                isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity, alignment: .leading) // ← Дополнительное выравнивание
    }
}


struct TypeChip: View {
        let type: ClothingType
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(type.name)
                    .font(.system(size: 14))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05)
                    )
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            .foregroundColor(.primary)
        }
    }
    



struct WardrobeItemDetailView: View {
    let item: WardrobeItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let image = item.getImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .padding()
            }

            Text("Цвет: \(item.color)")
//                .font(.title2)

            Text("Тип: \(item.type)")
//                .font(.title2)

            Text("Добавлено: \(formattedDate(item.createdAt))")
//                .font(.footnote)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
        .navigationTitle("Информация")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(role: .destructive) {
                    deleteItem()
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    func deleteItem() {
        // Удаляем изображение с диска
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(item.imagePath)

        try? FileManager.default.removeItem(at: fileURL)

        // Удаляем из базы данных
        DatabaseManager.shared.deleteWardrobeItem(item)

        // Закрываем окно
        dismiss()
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}




//struct WardrobeItemDetailView: View {
//    let item: WardrobeItem
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            if let image = item.getImage() {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//                    .cornerRadius(12)
//                    .padding()
//            }
//
//            Text("Тип: \(item.type)")
////                .font(.headline)
//
//
//            Text("Цвет: \(item.color)")
//                .font(.subheadline)
//
//            Text("Добавлено: \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
////                .foregroundColor(.gray)
//
////            Spacer()
//        }
//        .multilineTextAlignment(.leading)
//        .padding()
//        .presentationDetents([.medium, .large])
//    }
//}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//// Горизонтальный чипс (круг + текст рядом)
//struct ColorChip: View {
//    let color: ClothingColor
//    let isSelected: Bool
//    let action: () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            HStack(spacing: 6) {
//                Circle()
//                    .fill(color.color)
//                    .frame(width: 20, height: 20)
//                    .overlay(
//                        Circle()
//                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
//                    )
//
//                Text(color.name)
//                    .font(.system(size: 14))
//            }
//            .padding(.horizontal, 12)
//            .padding(.vertical, 8)
//            .frame(maxWidth: .infinity)
//            .background(
//                isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05)
//            )
//            .cornerRadius(20)
//            .overlay(
//                RoundedRectangle(cornerRadius: 20)
//                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
//            )
//        }
//        .foregroundColor(.primary)
//    }
//}

//struct ConfirmationView: View {
//    @Binding var isPresented: Bool
//    @Binding var image: UIImage?
//    @State private var selectedColor: ClothingColor? = nil
//    let onConfirm: () -> Void
//
//    private let colorOptions: [ClothingColor] = [
//        ClothingColor(name: "Чёрный", color: .black),
//        ClothingColor(name: "Белый", color: .white),
//        ClothingColor(name: "Серый", color: .gray),
//        ClothingColor(name: "Красный", color: .red),
//        ClothingColor(name: "Синий", color: .blue),
//        ClothingColor(name: "Жёлтый", color: .yellow)
//    ]
//
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Уже добавляем эту вещь в ваш гардероб")
//                .font(.title2)
//                .multilineTextAlignment(.center)
//                .padding(.top, 20)
//
//            if let image = image {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(maxHeight: 220)
//                    .cornerRadius(12)
//                    .padding(.horizontal, 24)
//            }
//
//            // Секция выбора цвета
//            VStack(alignment: .leading, spacing: 20) {
//                Text("Цвет:")
//                    .font(.headline)
//                    .padding(.horizontal, 24)
//
//                // Исправленный LazyVGrid
//                LazyVGrid(
//                    columns: [
//                        GridItem(.flexible()),
//                        GridItem(.flexible()),
//                        GridItem(.flexible())
//                    ],
//                    spacing: 5
//                ) {
//                    ForEach(colorOptions) { option in
//                        ColorChip(
//                            color: option,
//                            isSelected: selectedColor == option
//                        ) {
//                            selectedColor = option
//                        }
//                    }
//                }
//                .padding(.horizontal, 10)
//            }
//
//            Spacer()
//
//            Button(action: {
//                onConfirm()
//                isPresented = false
//            }) {
//                Text("Добавить предмет в гардероб")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(selectedColor == nil ? Color.gray : Color.blue)
//                    .cornerRadius(10)
//            }
//            .disabled(selectedColor == nil)
//            .padding(.horizontal, 24)
//            .padding(.bottom, 20)
//        }
//        .padding(.vertical, 10)
//        .presentationDetents([.large])
//        .presentationCornerRadius(20)
//    }
//}
//
//// Компонент ColorChip остается без изменений
//struct ColorChip: View {
//    let color: ClothingColor
//    let isSelected: Bool
//    let action: () -> Void
//
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 6) {
//                Circle()
//                    .fill(color.color)
//                    .frame(width: 40, height: 40)
//                    .overlay(
//                        Circle()
//                            .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
//                    )
//
//                Text(color.name)
//                    .font(.system(size: 14))
//                    .lineLimit(1)
//                    .minimumScaleFactor(0.7)
//            }
//            .frame(width: 80, height: 80)
//            .background(
//                isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05)
//            )
//            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
//            )
//        }
//        .foregroundColor(.primary)
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
