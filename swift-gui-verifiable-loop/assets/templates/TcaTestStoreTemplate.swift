import XCTest
import ComposableArchitecture

@MainActor
final class LoginFlowTests: XCTestCase {

  func testLoginHappyPath() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      // Inject deterministic dependencies here (UUID/Date/Clock/Clients).
    }

    await store.send(.login(.submitButtonTapped)) {
      $0.login.isLoading = true
    }

    await store.receive(.login(.loginResponse(.success))) {
      $0.login.isLoading = false
      $0.isAuthenticated = true
    }
  }
}

// Replace with your reducer
@Reducer
struct AppFeature {
  struct State: Equatable { var login = Login.State(); var isAuthenticated = false }
  enum Action { case login(Login.Action) }
  var body: some ReducerOf<Self> {
    Scope(state: \.login, action: \.login) { Login() }
    Reduce { state, action in
      switch action {
      case .login: return .none
      }
    }
  }

  @Reducer
  struct Login {
    struct State: Equatable { var isLoading = false }
    enum Action { case submitButtonTapped; case loginResponse(Result<Void, Error>) }
    var body: some ReducerOf<Self> {
      Reduce { state, action in
        switch action {
        case .submitButtonTapped:
          state.isLoading = true
          return .none
        case .loginResponse(.success):
          state.isLoading = false
          return .none
        case .loginResponse(.failure):
          state.isLoading = false
          return .none
        }
      }
    }
  }
}
