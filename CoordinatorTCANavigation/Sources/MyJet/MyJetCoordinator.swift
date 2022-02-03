import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension MyJet {

    class Coordinator: BaseCoordinatorType {
        let store: Store<MyJet.State, MyJet.Action>
        var windowRootViewController: UIViewController? { navigationController }

        weak var coordinator: BaseCoordinatorType?

        private weak var navigationController: UINavigationController?
        private weak var rootViewController: UIViewController?

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
                strongReference: self,
                onDeinit: nil // no need to clear state as the coordinator should deallocate
            )
            let navigationController = UINavigationController(rootViewController: viewController)
            viewController.title = "MyJet"
            navigationController.navigationBar.prefersLargeTitles = true
            self.navigationController = navigationController
            self.rootViewController = viewController

            bindPresentedReservations(to: viewController)
            bindPushedReservations(to: navigationController)
        }

        deinit {
            Log.debug()
        }

        func recursiveCleanup() {
            // empty for now
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
                self.coordinator = reservationsCoordinator
            } else: { [weak self] in
                // state was cleared
                self?.closeAll(inside: self?.navigationController, until: self?.rootViewController)
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
                self.coordinator = reservationsCoordinator
            } else: { [weak self] in
                // state was cleared
                self?.closeAll(inside: self?.navigationController, until: self?.rootViewController)
            }
            .store(in: &cancelables)
        }

        private func cancelEffects(effectsToCancel effects: [AnyHashable]) {
            ViewStore(store).send(.cancelEffects(effects))
        }
    }

}
