import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension Reservations {
    class Coordinator: CoordinatorType {

        let store: Store<State, NavigationAction<Action>>

        private weak var navigationController: UINavigationController?
        private weak var rootViewController: UIViewController?

        private var cancelables: Set<AnyCancellable> = []

        var effectsToCancel: [AnyHashable] = []
        var cancelEffects: ([AnyHashable]) -> Void

        init(store: Store<State, NavigationAction<Action>>, cancelEffects: @escaping ([AnyHashable]) -> Void) {
            Log.debug()
            self.store = store
            self.cancelEffects = cancelEffects
        }

        deinit {
            Log.debug()
            // closed by interaction?
            let viewStore = ViewStore(store)
            cancelEffects(effectsToCancel)
            viewStore.send(.onClose)
        }

        func start(pushedTo navigationController: UINavigationController, animated: Bool = true) {
            let vc = makeReservationsVC()
            vc.title = "Reservations"
            vc.navigationItem.rightBarButtonItem = .init(title: "Close", style: .plain, target: self, action: #selector(closeTapped))
            navigationController.pushViewController(vc, animated: animated)
            self.navigationController = navigationController
            self.rootViewController = vc

            bindPresentedDetail(to: vc)
            bindPushedDetail(to: navigationController)
        }

        func start(presentedTo viewController: UIViewController, animated: Bool = true) {
            let vc = makeReservationsVC()
            let nc = UINavigationController(rootViewController: vc)
//            nc.navigationBar.prefersLargeTitles = true
            viewController.present(nc, animated: animated)
            self.navigationController = nc
            self.rootViewController = vc

            bindPresentedDetail(to: vc)
            bindPushedDetail(to: nc)
        }

        private func makeReservationsVC(onDeinit: (() -> Void)? = nil) -> UIViewController {
            let vc = HostingController(
                rootView: Reservations.Screen(store: store.scope(action: NavigationAction.action)),
                coordinator: self,
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
            let detailPath = (\State.route).appending(path: /Route.presentedDetail)
            let detailStore = store.scope(
                state: detailPath.extract(from:),
                action: (/NavigationAction<Action>.action).appending(path: /Action.presentedDetail).embed
            )

            detailStore.ifLet { [weak self, weak vc] honestDetailStore in
                guard let vc = vc, let self = self else { return }
                let detailCoordinator = Detail.Coordinator(
                    store: honestDetailStore,
                    cancelEffects: self.cancelEffects
                )
                detailCoordinator.start(presentedTo: vc)
            } else: { [weak self] in
                // dismiss programmatically -> inform UIKit
                self?.closeAll()
            }
            .store(in: &cancelables)
        }

        private func bindPushedDetail(to vc: UINavigationController) {
            let detailPath = (\State.route).appending(path: /Route.pushedDetail)
            let detailStore = store.scope(
                state: detailPath.extract(from:),
                action: (/NavigationAction<Action>.action).appending(path: /Action.pushedDetail).embed
            )

            detailStore.ifLet { [weak self] honestDetailStore in
                guard let nc = self?.navigationController, let self = self else { return }
                let detailCoordinator = Detail.Coordinator(
                    store: honestDetailStore,
                    cancelEffects: self.cancelEffects
                )
                detailCoordinator.start(pushedTo: nc)
            } else: { [weak self] in
                // dismiss programmatically -> inform UIKit
                self?.closeAll()
            }
            .store(in: &cancelables)
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
