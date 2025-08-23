import Foundation

struct RemoteKnowledgeItem: Codable {
    let id: String
    let title: String
    let what: String
    let why: String
    let how: String
    let tags: [String]
}

@MainActor
final class KnowledgeSyncService {
    private let repository: KnowledgeRepository
    private let session: URLSession
    private let endpoint: URL

    init(repository: KnowledgeRepository, endpoint: URL = URL(string: "https://chenyuanqi.com/driver-knowledge.json")!, session: URLSession = .shared) {
        self.repository = repository
        self.endpoint = endpoint
        self.session = session
    }

    func sync() async throws {
        let (data, response) = try await session.data(from: endpoint)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let items = try JSONDecoder().decode([RemoteKnowledgeItem].self, from: data)
        let cards = items.map { RemoteKnowledgeItem in
            KnowledgeCard(id: RemoteKnowledgeItem.id,
                          title: RemoteKnowledgeItem.title,
                          what: RemoteKnowledgeItem.what,
                          why: RemoteKnowledgeItem.why,
                          how: RemoteKnowledgeItem.how,
                          tags: RemoteKnowledgeItem.tags)
        }
        try repository.upsert(cards: cards)
    }
}