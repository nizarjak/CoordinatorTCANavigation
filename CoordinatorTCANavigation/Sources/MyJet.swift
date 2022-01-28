import SwiftUI
import ComposableArchitecture

enum MyJet {}

extension MyJet {

//    enum Route: Equatable {
//        case detail(DetailState)
//    }

    struct State: Equatable {
//        var route: Route?
    }
    enum Action {
        case pushButtonTapped
        case presentButtonTapped
    }
    struct Environment {}

    static let reducer = Reducer<State, Action, Environment>.combine(
        .init { state, action, environment in
            switch action {
            case .presentButtonTapped:
                return .none
            case .pushButtonTapped:
                return .none
            }
        }
    )
}


extension MyJet {
    struct View: SwiftUI.View {

        let store: Store<State, Action>
        @ObservedObject var viewStore: ViewStore<Void, Action>

        init(store: Store<State, Action>) {
            self.store = store
            self.viewStore = ViewStore(store.stateless)
        }

        var body: some SwiftUI.View {
            VStack {
                Button("Push") { viewStore.send(.pushButtonTapped) }

                Button("Present") { viewStore.send(.presentButtonTapped) }
            }
        }
    }
}

struct MyJetView_Previews: PreviewProvider {
    static var previews: some View {
        MyJet.View(
            store: .init(
                initialState: .init(),
                reducer: MyJet.reducer,
                environment: .init()
            )
        )
    }
}
