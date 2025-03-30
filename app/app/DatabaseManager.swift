import Foundation
import GRDB

class DatabaseManager {
    static let shared = DatabaseManager()
    private var dbQueue: DatabaseQueue?

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbURL = documentsURL.appendingPathComponent("app.db")

            // Копируем базу из Bundle в Documents, если её ещё нет
            if !fileManager.fileExists(atPath: dbURL.path) {
                if let bundleDBURL = Bundle.main.url(forResource: "app", withExtension: "db") {
                    try fileManager.copyItem(at: bundleDBURL, to: dbURL)
                    print("✅ База данных скопирована в Documents")
                } else {
                    print("❌ Не удалось найти app.db в Bundle")
                }
            }

            // Открываем соединение с базой
            dbQueue = try DatabaseQueue(path: dbURL.path)
            print("📦 База подключена: \(dbURL.path)")

        } catch {
            print("❌ Ошибка при настройке базы данных: \(error)")
        }
        
        printAllTables()

    }

    /// Получить продукты, связанные с образом по его ID
    func fetchProducts(forLookId lookId: Int) -> [Product] {
        do {
            return try dbQueue?.read { db in
                // Получаем поле items из таблицы looks
                let row = try Row.fetchOne(db, sql: "SELECT items FROM looks WHERE id = ?", arguments: [lookId])
                guard let itemsString: String = row?["items"] else {
                    print("⚠️ Не найдено поле items для look id \(lookId)")
                    return []
                }

                // Преобразуем строку в массив ID
                let itemIds = itemsString
                    .split(separator: ",")
                    .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

                if itemIds.isEmpty {
                    print("⚠️ Пустой список продуктов для look id \(lookId)")
                    return []
                }

                // Формируем SQL-запрос с IN (...)
                let placeholders = itemIds.map { _ in "?" }.joined(separator: ",")
                let sql = "SELECT id, name, color, price, store, url FROM products WHERE id IN (\(placeholders))"

                return try Product.fetchAll(db, sql: sql, arguments: StatementArguments(itemIds))
            } ?? []
        } catch {
            print("❌ Ошибка при загрузке продуктов: \(error)")
            return []
        }
    }
    func printAllTables() {
        do {
            try dbQueue?.read { db in
                let tables = try String.fetchAll(db, sql: "SELECT name FROM sqlite_master WHERE type='table'")
                print("📋 Таблицы в базе: \(tables)")
            }
        } catch {
            print("❌ Ошибка при получении списка таблиц: \(error)")
        }
    }

}
