import Foundation
import UIKit

protocol CoordinatorType: AnyObject {
    /// Used for traversing to the leaf coordinator when dealing with pending effects and other cleanup.
    /// - Warning: Use weak variable as the UIKit is holding strong reference.
    var coordinator: CoordinatorType? { get set }

    /// Stop pending effects and any other cleanup if necessary.
    /// Cleanup on child coordinators is called by `closeAll(inside:until:)` function.
    func cleanup()
}

extension CoordinatorType {

    private func recursiveCleanup() {
        coordinator?.recursiveCleanup()
        self.cleanup()
    }

    /// Handles proper animation and coordinator cleanup.
    /// This should be called from the first coordinator that will survive the navigation - the one who clears the state.
    func closeAll(inside navigationController: UINavigationController?, until rootViewController: UIViewController?) {
        coordinator?.recursiveCleanup()
        coordinator = nil // so we don't clean coordinator multiple times

        // No need to handle navigation if it already happened
        guard let navigationController = navigationController else { return }

        let isPresenting = navigationController.presentedViewController != nil
        if isPresenting {
            // if something is presenting, we can hide poping below the modal screen's animation
            navigationController.dismiss(animated: true)
        }
        // pop with animation only when we're not animating any modal screen down.
        if let rootViewController = rootViewController {
            navigationController.popToViewController(rootViewController, animated: !isPresenting)
        }
    }
}


import ComposableArchitecture
import Combine

public protocol BaseCoordinatorType: AnyObject {
    var coordinator: BaseCoordinatorType? { get set }
    func recursiveCleanup()
}

extension BaseCoordinatorType {
    /// Handles proper animation and coordinator cleanup.
    /// This should be called from the first coordinator that will survive the navigation - the one who clears the state.
    func closeAll(inside navigationController: UINavigationController?, until rootViewController: UIViewController?) {
        // cleaning only childs as this coordinator should not be cleaned.
        coordinator?.recursiveCleanup()
        coordinator = nil // so we don't clean coordinator multiple times

        // No need to handle navigation if it already happened
        guard let navigationController = navigationController else { return }

        let isPresenting = navigationController.presentedViewController != nil
        if isPresenting {
            // if something is presenting, we can hide poping below the modal screen's animation
            navigationController.dismiss(animated: true)
        }
        // pop with animation only when we're not animating any modal screen down.
        if let rootViewController = rootViewController {
            navigationController.popToViewController(rootViewController, animated: !isPresenting)
        }
    }
}

open class BaseCoordinator<State, Action>: BaseCoordinatorType where State: Equatable, Action: Equatable {

    public let store: Store<State, NavigationAction<Action>>

    public weak var coordinator: BaseCoordinatorType?

    /// We're getting closed by the parent. The state was already niled and we're reacting to that.
    private var isClosedByStateChange: Bool = false
    private var cancelables: Set<AnyCancellable> = []
    public let cancelEffects: ([AnyHashable]) -> Void

    init(store: Store<State, NavigationAction<Action>>, cancelEffects: @escaping ([AnyHashable]) -> Void) {
        self.store = store
        self.cancelEffects = cancelEffects
    }

    deinit {
        guard !isClosedByStateChange else { return }
        // Getting interactively closed by user

        // Do the cleanup of self and the childs
        recursiveCleanup()

        // Update the state
        ViewStore(store).send(.onSystemClose)
    }

    func cleanup() {
        // nothing to cleanup
    }

    public func recursiveCleanup() {
        // childs will clean itself first
        self.coordinator?.recursiveCleanup()
        self.isClosedByStateChange = true
        self.cleanup()
    }

    func bindToState<LocalState: Equatable, LocalAction: Equatable>(
        state toLocalState: OptionalPath<State, LocalState>,
        action toLocalAction: CasePath<NavigationAction<Action>, NavigationAction<LocalAction>>,
        openCoordinator: @escaping (
            Store<LocalState, NavigationAction<LocalAction>>,
            @escaping ([AnyHashable]) -> Void
        ) -> BaseCoordinator<LocalState, LocalAction>,
        onClose: @escaping () -> Void
    ) {
        store.scope(
            state: toLocalState.extract(from:),
            action: toLocalAction.embed
        )
        .ifLet(
            then: { [weak self] honestLocalStore in
                guard let self = self else { return }
                let coordinator = openCoordinator(honestLocalStore, self.cancelEffects)
                self.coordinator = coordinator
            },
            else: onClose
        )
        .store(in: &cancelables)
    }
}
