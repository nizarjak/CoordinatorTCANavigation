import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension MyJet {

    class Coordinator: CoordinatorType {

        let store: Store<MyJet.State, MyJet.Action>
        var rootViewController: UIViewController? { navigationController }

        private weak var navigationController: UINavigationController?
        private var cancelables: Set<AnyCancellable> = []
        private var cancelEffects: ([AnyHashable]) -> Void = { _ in } // overriden in constructor

        init(store: Store<MyJet.State, MyJet.Action>) {
            Log.debug("")
            self.store = store

            self.cancelEffects = { [weak self] effects in
                guard let store = self?.store else { return }
                ViewStore(store).send(.cancelEffects(effects))
            }

            let viewController = HostingController(
                rootView: MyJet.Screen(store: store),
                coordinator: self,
                onDeinit: nil // no need to clear state as the coordinator should deallocate
            )
            let navigationController = UINavigationController(rootViewController: viewController)
//            navigationController.navigationBar.prefersLargeTitles = true
            self.navigationController = navigationController

            bindPresentedReservations(to: viewController)
            bindPushedReservations(to: navigationController)
        }

        deinit {
            Log.debug()
        }

        private func closeAll() {
            guard let navigationController = navigationController else { return }

            let isPresenting = navigationController.presentedViewController != nil
            if isPresenting {
                // if something is presenting, we can hide poping below the modal screen's animation
                navigationController.dismiss(animated: true)
            }
            // pop with animation only when we're not animating any modal screen down.
            navigationController.popToRootViewController(animated: !isPresenting)
        }

        private func bindPresentedReservations(to vc: UIViewController) {
            let reservationsPath = (\State.route).appending(path: /Route.presentedReservations)
            let reservationsStore = store.scope(state: reservationsPath.extract(from:), action: Action.presentedReservations)

            reservationsStore.ifLet { [weak self] honestReservationsStore in
                guard let self = self else { return }
                let reservationsCoordinator = Reservations.Coordinator(
                    store: honestReservationsStore,
                    cancelEffects: self.cancelEffects
                )
                reservationsCoordinator.start(presentedTo: vc)
            } else: { [weak self] in
                // dismiss programmatically -> inform UIKit
//                self?.reservationsCoordinator?.stop(animated: true)
                self?.closeAll()
            }
            .store(in: &cancelables)
        }

        private func bindPushedReservations(to nc: UINavigationController) {
            let reservationsPath = (\State.route).appending(path: /Route.pushedReservations)
            let reservationsStore = store.scope(state: reservationsPath.extract(from:), action: Action.pushedReservations)

            reservationsStore.ifLet { [weak self] honestReservationsStore in
                guard let self = self else { return }
                let reservationsCoordinator = Reservations.Coordinator(
                    store: honestReservationsStore,
                    cancelEffects: self.cancelEffects
                )
                reservationsCoordinator.start(pushedTo: nc)
            } else: { [weak self] in
                // dismiss programmatically -> inform UIKit
//                self?.reservationsCoordinator?.stop(animated: true)
                self?.closeAll()
            }
            .store(in: &cancelables)
        }

        private func cancelEffects(effectsToCancel effects: [AnyHashable]) {
            ViewStore(store).send(.cancelEffects(effects))
        }
    }

}
