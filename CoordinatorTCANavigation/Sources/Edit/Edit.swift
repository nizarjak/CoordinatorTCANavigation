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
    }

    static let reducer = Reducer<State, Action, Void> { state, action, _ in
        switch action {
        case .change(let name):
            state.name = name
        case .closeAllTapped:
            break
        }
        return .none
    }

    struct Screen: View {

        let store: Store<State, Action>

        var body: some View {
            WithViewStore(store) { viewStore in
                VStack {
                    TextField.init("Color name: ", text: viewStore.binding(get: \.name, send: Action.change))

                    Button("Close all") { viewStore.send(.closeAllTapped) }
                }
                .padding()
            }
        }
    }
}
