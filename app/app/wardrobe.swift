import Foundation
import SwiftUI
import UIKit



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
        
            recognizeImage()
        

//            selectedColor = getDefaultColor()
//            selectedType = getDefaultType()
        }
        .padding(.vertical, 10)
        .presentationDetents([.large])
        .presentationCornerRadius(20)
    }

    // Автовыбор цвета и типа

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

    
    private func recognizeImage() {
        guard let image = image else { return }
//        isLoading = true

        APIService.shared.recognizeClothing(from: image) { result in
            DispatchQueue.main.async {
//                isLoading = false
                print(result)
                switch result {
                case .success(let response):
                    if let item = response.detected_items.first {
                        if let matchedColor = colorOptions.first(where: { $0.name.lowercased() == item.color.lowercased() }) {
                            selectedColor = matchedColor
                        }

                        if let matchedType = typeOptions.first(where: { $0.name.lowercased() == item.type.lowercased() }) {
                            selectedType = matchedType
                        }
                    }
                case .failure(let error):
                    print("Ошибка распознавания: \(error.localizedDescription)")
                    // fallback
                    selectedColor = getDefaultColor()
                    selectedType = getDefaultType()
                }
            }
        }
    }

}







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

