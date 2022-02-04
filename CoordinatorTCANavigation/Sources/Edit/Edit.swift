import Foundation
import SwiftUI
import ComposableArchitecture

enum Edit {}

extension Edit {
    struct State: Equatable, Identifiable {
        var id: String = UUID().uuidString
        var name: String
    }

    enum Action: Equatable {
        case change(name: String)
        case closeAllTapped
        case closeToReservationsTapped
    }

    static let reducer = Reducer<State, Action, Void> { state, action, _ in
        switch action {
        case .change(let name):
            state.name = name
        case .closeAllTapped, .closeToReservationsTapped:
            break
        }
        return .none
    }

    struct Screen: View {

        let store: Store<State, Action>

        var body: some View {
            WithViewStore(store) { viewStore in
                VStack(spacing: 20) {
                    TextField.init("Color name: ", text: viewStore.binding(get: \.name, send: Action.change))

                    Button("Close all") { viewStore.send(.closeAllTapped) }

                    Button("Close to Reservations") { viewStore.send(.closeToReservationsTapped) }
                }
                .padding()
            }
        }
    }

    class Coordinator: BaseCoordinator<State, Action>, PresentableCoordinator {
        func start(presentedTo viewController: UIViewController, animated: Bool) {
            let vc = HostingController(
                rootView: Edit.Screen(store: store.scope(action: NavigationAction.action)),
                strongReference: self
            )
            viewController.present(vc, animated: animated)
        }
    }
}

