import Foundation
import SwiftData

@MainActor
final class AppDI: ObservableObject {
    static let shared = AppDI()

    // Lazy injected repositories/services
    var logRepository: LogRepository { LogRepositorySwiftData() }
    var checklistRepository: ChecklistRepository { ChecklistRepositorySwiftData() }
    var knowledgeRepository: KnowledgeRepository { KnowledgeRepositorySwiftData() }
    var driveRouteRepository: DriveRouteRepository { DriveRouteRepositorySwiftData() }
    var userProfileRepository: UserProfileRepository { UserProfileRepositorySwiftData() }
    var tagSuggestionService: TagSuggestionService { TagSuggestionService.shared }
    var knowledgeSyncService: KnowledgeSyncService { KnowledgeSyncService(repository: knowledgeRepository) }
    var locationService: LocationService { LocationService.shared }
    var driveService: DriveService { DriveService.shared }

    private init() {}
}
