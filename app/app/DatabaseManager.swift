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
            copyDatabaseIfNeeded()



            // Открываем соединение с базой
            dbQueue = try DatabaseQueue(path: dbURL.path)
            createWardrobeTableIfNeeded()
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
    
    
    func copyDatabaseIfNeeded() {
        let fileManager = FileManager.default

        // Путь к файлу в Bundle
        guard let bundleURL = Bundle.main.url(forResource: "app", withExtension: "db") else {
            print("❌ Не удалось найти app.db в Bundle")
            return
        }

        // Путь к файлу в Documents
        let documentsURL = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let destinationURL = documentsURL.appendingPathComponent("app.db")

        // Проверка: если файл уже есть — не копируем
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("✅ База уже существует в Documents: \(destinationURL.path)")
            return
        }

        do {
            try fileManager.copyItem(at: bundleURL, to: destinationURL)
            print("✅ База успешно скопирована в Documents: \(destinationURL.path)")
        } catch {
            print("❌ Ошибка при копировании базы: \(error)")
        }
    }
    
    private func createWardrobeTableIfNeeded() {
        do {
            try dbQueue?.write { db in
                try db.create(table: "wardrobe", ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("color", .text).notNull()
                    t.column("type", .text).notNull()
                    t.column("image_path", .text).notNull()
                    t.column("created_at", .datetime).notNull()
                }
            }
            print("✅ Таблица wardrobe создана (если её не было)")
        } catch {
            print("❌ Ошибка создания таблицы wardrobe: \(error)")
        }
    }
    
    func insertWardrobeItem(_ item: WardrobeItem) {
        do {
            try dbQueue?.write { db in
                try item.insert(db)
            }
            print("✅ Вещь добавлена в гардероб")
        } catch {
            print("❌ Ошибка при добавлении вещи: \(error)")
        }
    }

    func fetchAllWardrobeItems() -> [WardrobeItem] {
        do {
            return try dbQueue?.read { db in
                try WardrobeItem.fetchAll(db)
            } ?? []
        } catch {
            print("❌ Ошибка при загрузке гардероба: \(error)")
            return []
        }
    }

    func deleteWardrobeItem(_ item: WardrobeItem) {
        guard let dbQueue2 = dbQueue else {
            print("Ошибка: dbQueue не инициализирован")
            return
        }

        do {
            try dbQueue2.write { db in
                try item.delete(db)
            }
        } catch {
            print("Ошибка при удалении WardrobeItem: \(error)")
        }
    }





}
