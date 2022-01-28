import SwiftUI

class HostingController<Content>: UIHostingController<Content> where Content : View {

    // strong reference
    let coordinator: Coordinator
    let onDeinit: (() -> Void)?

    init(rootView: Content, coordinator: Coordinator, onDeinit: (() -> Void)?) {
        self.coordinator = coordinator
        self.onDeinit = onDeinit
        super.init(rootView: rootView)
    }

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        onDeinit?()
    }
}
