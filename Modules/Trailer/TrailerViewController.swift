import UIKit
import WebKit

/// Avoids a retain cycle between the web view's content controller and the view controller.
private final class ScriptMessageProxy: NSObject, WKScriptMessageHandler {
    private let onMessage: () -> Void

    init(onMessage: @escaping () -> Void) {
        self.onMessage = onMessage
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        onMessage()
    }
}

final class TrailerViewController: StatefulViewController, TrailerViewProtocol, WKNavigationDelegate {
    private let presenter: TrailerPresenterProtocol
    private let webView: WKWebView

    init(presenter: TrailerPresenterProtocol) {
        self.presenter = presenter
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let contentController = WKUserContentController()
        configuration.userContentController = contentController
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)
        contentController.add(ScriptMessageProxy { [weak self] in self?.presenter.playbackFailed() }, name: "playerError")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = presenter.title
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.right.square"),
            primaryAction: UIAction { [weak self] _ in self?.presenter.openInYouTube() })
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Open in YouTube"

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        view.insertSubview(webView, belowSubview: stateView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        stateView.showLoading()
        presenter.viewDidLoad()
    }

    func load(embedURL: URL) {
        // The player reports its own errors (for example embedding disabled) by postMessage, which the
        // navigation delegate cannot see, so forward them to the Presenter to trigger the YouTube fallback.
        let html = """
        <html><head><meta name="viewport" content="width=device-width, initial-scale=1"></head>
        <body style="margin:0;background:#000">
        <iframe id="player" width="100%" height="100%" src="\(embedURL.absoluteString)" frameborder="0"
        allow="autoplay; encrypted-media; picture-in-picture" allowfullscreen></iframe>
        <script>
        var frame = document.getElementById('player');
        frame.addEventListener('load', function () {
          frame.contentWindow.postMessage(JSON.stringify({event: 'listening', id: 1}), '*');
        });
        window.addEventListener('message', function (event) {
          try {
            if (JSON.parse(event.data).event === 'onError') {
              window.webkit.messageHandlers.playerError.postMessage('error');
            }
          } catch (error) {}
        });
        </script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: TrailerEmbed.origin))
    }

    func showPlaybackFailure(message: String) {
        stateView.showEmpty(message: message)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        stateView.hide()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        presenter.playbackFailed()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        presenter.playbackFailed()
    }
}
