import Foundation
import ComposableArchitecture

public struct Storage {
    private static let modelUrl = URL(fileURLWithPath: Bundle.main.bundlePath + "/../../../PersistentStore/model.json")

    public static func loadEffect<Value: Decodable>() -> Effect<Result<Value?, Error>> {
        Effect { callback in
            // TODO: Move to environment: FileManager
            guard FileManager.default.fileExists(atPath: modelUrl.path) else {
                callback(.success(nil))
                return
            }
            do {
                // TODO: Move to environment: contentsOf
                let valueData = try Data(contentsOf: modelUrl)
                let value = try JSONDecoder().decode(Value.self, from: valueData)
                callback(.success(value))
            } catch {
                callback(.failure(error))
            }
        }
    }

    public static func saveEffect<Value: Encodable>(value: Value) -> Effect<Result<Void, Error>> {
        Effect { callback in
            do {
                let valueData = try JSONEncoder().encode(value)
                // TODO: Move to environment: write
                try valueData.write(to: modelUrl, options: .atomic)
                callback(.success(()))
            } catch {
                callback(.failure(error))
            }
        }
    }

}
