import Foundation
import UIKit
import ComposableArchitecture
import Combine
import SwiftUI

extension MyJet {

    class Coordinator: CoordinatorType {

        let store: Store<MyJet.State, MyJet.Action>
        var rootViewController: UIViewController? { navigationController }

        private weak var reservationsCoordinator: Reservations.Coordinator?

        private weak var navigationController: UINavigationController?
        private var cancelables: Set<AnyCancellable> = []

        init(store: Store<MyJet.State, MyJet.Action>) {
            Log.debug("")
            self.store = store

            let viewController = HostingController(
                rootView: MyJet.Screen(store: store),
                coordinator: self,
                onDeinit: nil // no need to clear state as the coordinator should deallocate
            )
            let navigationController = UINavigationController(rootViewController: viewController)
            navigationController.navigationBar.prefersLargeTitles = true
            self.navigationController = navigationController


            bindPresentedReservations(to: viewController)
            bindPushedReservations(to: navigationController)
        }

        deinit {
            Log.debug()
        }

        func bindPresentedReservations(to vc: UIViewController) {
            let reservationsPath = (\State.route).appending(path: /Route.presentedReservations)
            let reservationsStore = store.scope(state: reservationsPath.extract(from:), action: Action.presentedReservations)

            reservationsStore.ifLet { [weak self] honestReservationsStore in
                let reservationsCoordinator = Reservations.Coordinator(store: honestReservationsStore)
                reservationsCoordinator.start(presentedTo: vc)
                self?.reservationsCoordinator = reservationsCoordinator
            } else: { [weak self] in
                // dismiss programmatically -> inform UIKit
                self?.reservationsCoordinator?.stop(animated: true)
            }
            .store(in: &cancelables)
        }

        func bindPushedReservations(to nc: UINavigationController) {
            let reservationsPath = (\State.route).appending(path: /Route.pushedReservations)
            let reservationsStore = store.scope(state: reservationsPath.extract(from:), action: Action.pushedReservations)

            reservationsStore.ifLet { [weak self] honestReservationsStore in
                let reservationsCoordinator = Reservations.Coordinator(store: honestReservationsStore)
                reservationsCoordinator.start(pushedTo: nc)
                self?.reservationsCoordinator = reservationsCoordinator
            } else: { [weak self] in
                // dismiss programmatically -> inform UIKit
                self?.reservationsCoordinator?.stop(animated: true)
            }
            .store(in: &cancelables)
        }
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
