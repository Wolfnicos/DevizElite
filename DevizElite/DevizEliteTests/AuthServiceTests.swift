import XCTest
import CoreData
import Combine
@testable import DevizElite

final class AuthServiceTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    final class FakeKeychain: KeychainServicing {
        var storage: [String: String] = [:]
        func savePassword(_ password: String, account: String) throws { storage[account] = password }
        func readPassword(account: String) throws -> String {
            if let value = storage[account] { return value }
            throw NSError(domain: "FakeKC", code: -1)
        }
    }

    func testRegisterAndSignIn() throws {
        let fakeKC = FakeKeychain()
        let testContext = PersistenceController(inMemory: true).container.viewContext
        let service = AuthService(keychainService: fakeKC, context: testContext)
        let exp1 = expectation(description: "register")
        var userId: UUID?
        service.register(email: "test@example.com", password: "pass123", displayName: "Test").sink { completion in
            if case let .failure(error) = completion { XCTFail("\(error)") }
        } receiveValue: { user in
            userId = user.id
            exp1.fulfill()
        }
        .store(in: &cancellables)
        wait(for: [exp1], timeout: 2)

        let exp2 = expectation(description: "signin")
        service.signIn(email: "test@example.com", password: "pass123").sink { completion in
            if case let .failure(error) = completion { XCTFail("\(error)") }
        } receiveValue: { user in
            XCTAssertEqual(user.id, userId)
            exp2.fulfill()
        }
        .store(in: &cancellables)
        wait(for: [exp2], timeout: 2)
    }
}

