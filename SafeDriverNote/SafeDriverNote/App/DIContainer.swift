import Foundation
import SwiftData

@MainActor
final class AppDI: ObservableObject {
    static let shared = AppDI()

    // Lazy injected repositories/services
    var logRepository: LogRepository { LogRepositorySwiftData() }
    var checklistRepository: ChecklistRepository { ChecklistRepositorySwiftData() }
    var knowledgeRepository: KnowledgeRepository { KnowledgeRepositorySwiftData() }
    var tagSuggestionService: TagSuggestionService { TagSuggestionService.shared }
    var knowledgeSyncService: KnowledgeSyncService { KnowledgeSyncService(repository: knowledgeRepository) }

    private init() {}
}
