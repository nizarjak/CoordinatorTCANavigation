import Foundation
import SwiftUI
import ComposableArchitecture

enum Reservation {}

extension Reservation {
    struct State: Equatable, Identifiable {
        let id: String
        let name: String
        let color: Color
        var isLiked: Bool
    }

    enum Action: Equatable {
        case pushButtonTapped
        case presentButtonTapped
        case likeButtonTapped
    }

    static let reducer = Reducer<State, Action, Void> { state, action, _ in
        switch action {
        case .likeButtonTapped:
            state.isLiked.toggle()

        case .pushButtonTapped, .presentButtonTapped:
            break
        }
        return .none
    }

    struct View: SwiftUI.View {

        let store: Store<State, Action>

        var body: some SwiftUI.View {
            WithViewStore(store) { viewStore in
                VStack {
                    HStack {
                        Text(viewStore.name)

                        Circle()
                            .fill(viewStore.color)
                            .frame(width: 20, height: 20)

                        Button(action: { viewStore.send(.likeButtonTapped) }) {
                            Image(systemName: viewStore.isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                                .foregroundColor(viewStore.color)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    HStack {
                        Button("Push", action: { viewStore.send(.pushButtonTapped) })
                            .frame(maxWidth: .infinity)


                        Button("Present", action: { viewStore.send(.presentButtonTapped) })
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .frame(height: 100)
            }
        }
    }
}

struct Reservation_Preview: PreviewProvider {
    static var previews: some View {
        Reservation.View(store: Store(
            initialState: .init(id: .init(), name: "Green", color: .green, isLiked: true),
            reducer: Reservation.reducer,
            environment: ()
        ))
    }
}
