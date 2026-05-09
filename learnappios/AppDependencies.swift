import Foundation
import CoreData
import CoreDataStore
import CoreNetwork
import CoreDomain

final class AppDependencies {
    let keychain = KeychainStore()

    lazy var apiClient = APIClient(
        baseURL: URL(string: "https://ts-memo-api-1.onrender.com")!,
        tokenProvider: { [keychain] in keychain.load() }
    )

    // MARK: - Repository 実装

    lazy var authRepo: AuthRepositoryProtocol =
        AuthRepositoryImpl(apiClient: apiClient, keychain: keychain)
    lazy var childrenRepo: ChildrenRepositoryProtocol =
        ChildrenRepositoryImpl(apiClient: apiClient)
    lazy var taskRepo: TaskRepositoryProtocol =
        TaskRepositoryImpl(apiClient: apiClient)
    lazy var dailyRepo: DailyRepositoryProtocol =
        DailyRepositoryImpl(apiClient: apiClient)
    lazy var summaryRepo: SummaryRepositoryProtocol =
        SummaryRepositoryImpl(apiClient: apiClient)

    // MARK: - UseCase

    // Auth
    lazy var loginUseCase         = LoginUseCase(repository: authRepo)
    lazy var signupUseCase        = SignupUseCase(repository: authRepo)
    lazy var getMeUseCase         = GetMeUseCase(repository: authRepo)
    lazy var logoutUseCase        = LogoutUseCase(repository: authRepo)
    lazy var deleteAccountUseCase = DeleteAccountUseCase(repository: authRepo)
    // Children
    lazy var getChildrenUseCase   = GetChildrenUseCase(repository: childrenRepo)
    lazy var createChildUseCase   = CreateChildUseCase(repository: childrenRepo)
    lazy var updateChildUseCase   = UpdateChildUseCase(repository: childrenRepo)
    lazy var deleteChildUseCase   = DeleteChildUseCase(repository: childrenRepo)
    // Tasks
    lazy var getTasksUseCase      = GetTasksUseCase(repository: taskRepo)
    lazy var createTaskUseCase    = CreateTaskUseCase(repository: taskRepo)
    lazy var updateTaskUseCase    = UpdateTaskUseCase(repository: taskRepo)
    lazy var archiveTaskUseCase   = ArchiveTaskUseCase(repository: taskRepo)
    lazy var reorderTasksUseCase  = ReorderTasksUseCase(repository: taskRepo)
    // Daily
    lazy var getDailyViewUseCase   = GetDailyViewUseCase(repository: dailyRepo)
    lazy var updateDailyLogUseCase = UpdateDailyLogUseCase(repository: dailyRepo)
    // Summary
    lazy var getCalendarSummaryUseCase = GetCalendarSummaryUseCase(repository: summaryRepo)
    lazy var getSummaryUseCase         = GetSummaryUseCase(repository: summaryRepo)
}
