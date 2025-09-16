import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var showGlobalSearch: Bool = false
    @Published var activeUserId: String?
    
    static let shared = AppState()
    
    init() {}
    
    func login(user: User) {
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}
