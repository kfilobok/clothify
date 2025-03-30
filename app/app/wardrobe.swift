import Foundation
import SwiftUI



struct ClothingColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
}



struct ConfirmationView: View {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?
    @State private var selectedColor: ClothingColor? = nil
    let onConfirm: () -> Void
    
    private let colorOptions: [ClothingColor] = [
        ClothingColor(name: "Чёрный", color: .black),
        ClothingColor(name: "Белый", color: .white),
        ClothingColor(name: "Серый", color: .gray),
        ClothingColor(name: "Синий", color: .blue),
        ClothingColor(name: "Голубой", color: .cyan),
        ClothingColor(name: "Зеленый", color: .green),
        ClothingColor(name: "Жёлтый", color: .yellow),
        //ClothingColor(name: "Оливковый", color: .green),
        ClothingColor(name: "Бежевый", color: Color(red: 0.99, green: 0.96, blue: 0.86)),
        ClothingColor(name: "Коричневый", color: .brown),
        ClothingColor(name: "Фиолетовый", color: .purple),
        ClothingColor(name: "Красный", color: .red),
        ClothingColor(name: "Розовый", color: Color(red: 0.98, green: 0.82, blue: 0.9)),
        ClothingColor(name: "Оранжевый", color: .orange)
    ]
    
    // Разбиваем цвета на группы по 3 для 3 колонок
    private var colorColumns: [[ClothingColor]] {
        stride(from: 0, to: colorOptions.count, by: 3).map {
            Array(colorOptions[$0..<min($0 + 3, colorOptions.count)])
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
//            Text("Уже добавляем эту вещь в ваш гардероб")
//                .font(.title2)
//                .multilineTextAlignment(.center)
//                .padding(.top, 20)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
            }
            
            // Секция выбора цвета с 3 колонками
            VStack(alignment: .leading, spacing: 8) {
                Text("Цвет:")
                    .font(.headline)
                    .padding(.horizontal, 24)
                
                // Три колонки с чипсами
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
                            
                            // Добавляем пустые View для выравнивания, если в строке меньше 3 элементов
                            if row.count < 3 {
                                ForEach(0..<(3 - row.count), id: \.self) { _ in
                                    Spacer()
                                        .frame(maxWidth: .infinity)
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
        .padding(.vertical, 10)
        .presentationDetents([.large])
        .presentationCornerRadius(20)
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
