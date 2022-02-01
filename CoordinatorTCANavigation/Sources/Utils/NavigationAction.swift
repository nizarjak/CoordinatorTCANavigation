import Foundation

enum NavigationAction<Action: Equatable>: Equatable {
    case action(Action)
    case onClose
}
