import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

class MyJetCoordinator: Coordinator {

    struct State: Equatable {
        var route: Route? = nil
        var myJet: MyJet.State
    }

    enum Route: Equatable {
        case detail(Detail.State)
    }

    enum Action: Equatable {
        case myJet(MyJet.Action)
        case detail(Detail.Action)
        case routeDismissed
    }

    struct Environment {
        var myJet: MyJet.Environment { .init() }
        var detail: Detail.Environment { .init() }
    }

    static let reducer: Reducer<State, Action, Environment> = .combine([
        Detail.reducer._pullback(
            state: OptionalPath(\State.route).appending(path: /Route.detail),
            action: /Action.detail,
            environment: \.detail
        ),

        .init { state, action, _ in
            switch action {
            case .myJet(.pushButtonTapped), .myJet(.presentButtonTapped):
                state.route = .detail(.init())

            case .detail(.pushButtonTapped), .detail(.presentButtonTapped):
                state.route = .detail(.init())

            case .detail(.closeButtonTapped):
                state.route = nil

            case .routeDismissed:
                state.route = nil
            }

            return .none
        },

        MyJet.reducer.pullback(
            state: \.myJet,
            action: /Action.myJet,
            environment: \.myJet
        ),
    ]).debug()

    let store: Store<State, Action>
    var rootViewController: UIViewController? { navigationController }

    private weak var navigationController: UINavigationController?
    private var cancelables: Set<AnyCancellable> = []

    init(store: Store<State, Action>) {
        self.store = store

        let vc = HostingController(
            rootView: MyJet.View(store: store.scope(state: \.myJet, action: Action.myJet)),
            coordinator: self,
            onDeinit: nil // no need to clear state as the coordinator should deallocate
        )
        let navigationController = UINavigationController(rootViewController: vc)
        self.navigationController = navigationController

        ViewStore(store.actionless.scope(state: \.route))
            .publisher
            .map { $0 != nil }
            .removeDuplicates()
            .sink { [weak self] isPresented in
                guard let self = self else { return }

                if isPresented {
                    self.showDetail()
                } else {
                    self.hideDetail()
                }
            }
            .store(in: &cancelables)
    }

    func showDetail() {
        // How to scope the store to have the honest value there?
        // I can capture fallback value and create new store if needed - actions won't work though

        let viewStore = ViewStore(store)

        let detailPath = OptionalPath(\State.route).appending(path: /Route.detail)
        guard let detailState = detailPath.extract(from: viewStore.state) else { return }

        let store = store.scope(
            state: { globalState in
                detailPath.extract(from: globalState) ?? detailState
            },
            action: Action.detail
        )

        let vc = HostingController(
            rootView: Detail.Screen(store: store),
            coordinator: self,
            onDeinit: {
                viewStore.send(.routeDismissed)
            }
        )

        navigationController?.pushViewController(vc, animated: true)
    }

    func hideDetail() {
        navigationController?.popViewController(animated: true)
    }

}

extension Optional {
    static var cacheLastSome: (Self) -> Self {
        var lastWrapped: Wrapped?
        return {
            lastWrapped = $0 ?? lastWrapped
            return lastWrapped
        }
    }
}
