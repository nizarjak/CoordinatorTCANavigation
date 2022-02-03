import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension Reservations {
    class Coordinator: BaseCoordinator<State, Action> {

        private weak var navigationController: UINavigationController?
        private weak var rootViewController: UIViewController?

        private var cancelables: Set<AnyCancellable> = []

        deinit {
            Log.debug()
        }

        func start(pushedTo navigationController: UINavigationController, animated: Bool = true) {
            let vc = makeReservationsVC()
            navigationController.pushViewController(vc, animated: animated)
            self.navigationController = navigationController
            self.rootViewController = vc

            bindPresentedDetail(to: vc)
            bindPushedDetail(to: navigationController)
        }

        func start(presentedTo viewController: UIViewController, animated: Bool = true) {
            let vc = makeReservationsVC()
            let nc = UINavigationController(rootViewController: vc)
            nc.navigationBar.prefersLargeTitles = true
            viewController.present(nc, animated: animated)
            self.navigationController = nc
            self.rootViewController = vc

            bindPresentedDetail(to: vc)
            bindPushedDetail(to: nc)
        }

        private func makeReservationsVC(onDeinit: (() -> Void)? = nil) -> UIViewController {
            let vc = HostingController(
                rootView: Reservations.Screen(store: store.scope(action: NavigationAction.action)),
                strongReference: self,
                onDeinit: onDeinit
            )
            vc.title = "Reservations"
            vc.navigationItem.rightBarButtonItem = .init(title: "Close", style: .plain, target: self, action: #selector(closeTapped))

            return vc
        }

        @objc private func closeTapped() {
            ViewStore(store).send(.action(.closeButtonTapped))
        }

        private func bindPresentedDetail(to vc: UIViewController) {
            bindToState(
                state: (\State.route).appending(path: /Route.presentedDetail),
                action: (/NavigationAction<Action>.action).appending(path: /Action.presentedDetail)
            ) { coordinatorStore, cancelEffects in
                let coord = Detail.Coordinator(store: coordinatorStore, cancelEffects: cancelEffects)
                coord.start(presentedTo: vc)
                return coord
            } onClose: { [weak self] in
                self?.closeAll(inside: self?.navigationController, until: self?.rootViewController)
            }
        }

        private func bindPushedDetail(to nc: UINavigationController) {
            bindToState(
                state: (\State.route).appending(path: /Route.pushedDetail),
                action: (/NavigationAction<Action>.action).appending(path: /Action.pushedDetail)
            ) { coordinatorStore, cancelEffects in
                let coord = Detail.Coordinator(store: coordinatorStore, cancelEffects: cancelEffects)
                coord.start(pushedTo: nc)
                return coord
            } onClose: { [weak self] in
                self?.closeAll(inside: self?.navigationController, until: self?.rootViewController)
            }
        }

        private func closeAll() {
            guard let navigationController = navigationController else { return }

            let isPresenting = navigationController.presentedViewController != nil
            // pop with animation only when we're not animating any modal screen down.
            if let rootViewController = rootViewController {
                navigationController.popToViewController(rootViewController, animated: !isPresenting)
            }
            if isPresenting {
                // if something is presenting, we can hide poping below the modal screen's animation
                navigationController.dismiss(animated: true)
            }
        }
    }
}
