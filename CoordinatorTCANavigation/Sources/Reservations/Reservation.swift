import Foundation
import SwiftUI
import ComposableArchitecture

enum Reservation {}

extension Reservation {
    struct State: Equatable, Identifiable {
        let id: UUID
        let name: String
        let color: Color
    }

    enum Action: Equatable {
        case pushButtonTapped
        case presentButtonTapped
    }

    static let reducer: Reducer<State, Action, Void> = .empty

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
            initialState: .init(id: .init(), name: "Blue", color: .blue),
            reducer: Reservation.reducer,
            environment: ()
        ))
    }
}
