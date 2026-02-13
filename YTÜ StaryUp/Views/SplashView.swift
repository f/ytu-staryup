import SwiftUI
import WebKit

struct SVGLogoView: UIViewRepresentable {
    var fillColor: String = "#FFFFFF"
    var animated: Bool = true
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        
        if let svgURL = Bundle.main.url(forResource: "staryup_logo", withExtension: "svg"),
           let svgContent = try? String(contentsOf: svgURL, encoding: .utf8) {
            let coloredSVG = svgContent.replacingOccurrences(of: "fill=\"#FFFFFF\"", with: "fill=\"\(fillColor)\"")
            var finalSVG = coloredSVG
            if !animated {
                finalSVG = finalSVG.replacingOccurrences(of: "opacity: 0;", with: "opacity: 1;")
                    .replacingOccurrences(of: "animation:", with: "/* animation: */")
            }
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <style>
              html, body {
                margin: 0; padding: 0;
                background: transparent;
                display: flex;
                align-items: center;
                justify-content: center;
                height: 100%;
                width: 100%;
                overflow: hidden;
              }
              svg {
                width: 100%;
                height: auto;
                display: block;
              }
            </style>
            </head>
            <body>
            \(finalSVG)
            </body>
            </html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: ()) {
        uiView.stopLoading()
    }
}

struct SplashView: View {
    let onFinished: () -> Void
    
    @State private var showSubtitle = false
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                SVGLogoView()
                    .frame(height: 45)
                    .padding(.horizontal, 40)
                
                // Subtitle
                Text("Fikirlerini paylaş, ekip bul")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 8)
                    .animation(.easeOut(duration: 0.5), value: showSubtitle)
            }
        }
        .task {
            // Wait for SVG animation (~1s)
            try? await Task.sleep(for: .milliseconds(1200))
            showSubtitle = true
            
            // Hold, then finish
            try? await Task.sleep(for: .milliseconds(1200))
            onFinished()
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
