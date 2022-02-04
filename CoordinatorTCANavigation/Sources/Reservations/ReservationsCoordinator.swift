import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension Reservations {
    class Coordinator: BaseCoordinator<State, Action>, PresentableCoordinator, PushableCoordinator {

        override init(store: Store<Reservations.State, NavigationAction<Reservations.Action>>) {
            super.init(store: store)
            Log.debug()
        }

        deinit {
            Log.debug()
        }

        func start(pushedTo navigationController: UINavigationController, animated: Bool = true) {
            let vc = makeReservationsVC()
            navigationController.pushViewController(vc, animated: animated)

            bindPresentedDetail(to: vc)
            bindPushedDetail(to: navigationController)
        }

        func start(presentedTo viewController: UIViewController, animated: Bool = true) {
            let vc = makeReservationsVC()
            let nc = UINavigationController(rootViewController: vc)
            nc.navigationBar.prefersLargeTitles = true
            viewController.present(nc, animated: animated)

            bindPresentedDetail(to: vc)
            bindPushedDetail(to: nc)
        }

        private func makeReservationsVC() -> UIViewController {
            let vc = HostingController(
                rootView: Reservations.Screen(store: store.scope(action: NavigationAction.action)),
                strongReference: self,
                onDeinit: nil
            )
            vc.title = "Reservations"
            vc.navigationItem.rightBarButtonItem = .init(title: "Close", style: .plain, target: self, action: #selector(closeTapped))

            return vc
        }

        @objc private func closeTapped() {
            ViewStore(store).send(.action(.closeButtonTapped))
        }

        private func bindPresentedDetail(to viewController: UIViewController) {
            present(
                state: (\State.route).appending(path: /Route.presentedDetail),
                action: (/NavigationAction<Action>.action).appending(path: /Action.presentedDetail),
                into: viewController,
                coordinator: Detail.Coordinator.init(store:)
            )
        }

        private func bindPushedDetail(to navigationController: UINavigationController) {
            push(
                state: (\State.route).appending(path: /Route.pushedDetail),
                action: (/NavigationAction<Action>.action).appending(path: /Action.pushedDetail),
                into: navigationController,
                coordinator: Detail.Coordinator.init(store:)
            )
        }
    }
}
