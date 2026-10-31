import Foundation

@MainActor
protocol MomentRepository {
    func fetchAll() throws -> [Moment]
    func save(_ moment: Moment) throws
    func mergeAll(_ moments: [Moment]) throws
    func replaceAll(with moments: [Moment]) throws
    func delete(id: UUID) throws
    func deleteAll() throws
}
