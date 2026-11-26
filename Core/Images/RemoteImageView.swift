import UIKit

/// Shows a placeholder while loading and a fallback when the URL is missing or loading fails.
final class RemoteImageView: UIImageView {
    private var loadTask: Task<Void, Never>?
    private let loader: ImageLoading

    init(loader: ImageLoading = ImageLoader.shared) {
        self.loader = loader
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = .secondarySystemFill
        tintColor = .tertiaryLabel
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setImage(url: URL?) {
        loadTask?.cancel()
        guard let url else {
            showFallback()
            return
        }
        showPlaceholder()
        loadTask = Task { [weak self, loader] in
            let image = await loader.image(for: url)
            guard !Task.isCancelled, let self else { return }
            if let image {
                self.show(image)
            } else {
                self.showFallback()
            }
        }
    }

    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
    }

    private func showPlaceholder() {
        contentMode = .center
        image = UIImage(systemName: "film")
    }

    private func showFallback() {
        contentMode = .center
        image = UIImage(systemName: "photo")
    }

    private func show(_ loaded: UIImage) {
        contentMode = .scaleAspectFill
        Motion.transition(self) { self.image = loaded }
    }
}
