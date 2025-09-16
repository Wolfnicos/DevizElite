import Foundation
import Combine
import CoreData

final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var displayName: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authService: AuthServicing
    private var cancellables: Set<AnyCancellable> = []
    private let appState: AppState
    private let context: NSManagedObjectContext

    init(appState: AppState, context: NSManagedObjectContext, authService: AuthServicing = AuthService.shared) {
        self.appState = appState
        self.context = context
        self.authService = authService
    }

    func signIn() {
        errorMessage = nil
        isLoading = true
        authService.signIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                self?.appState.activeUserId = user.id?.uuidString
                self?.appState.isAuthenticated = true
            }
            .store(in: &cancellables)
    }

    func register() {
        errorMessage = nil
        isLoading = true
        authService.register(email: email, password: password, displayName: displayName.isEmpty ? nil : displayName)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] user in
                self?.appState.activeUserId = user.id?.uuidString
                self?.appState.isAuthenticated = true
            }
            .store(in: &cancellables)
    }
}


