import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let payload: String
    var size: CGFloat = 220

    var body: some View {
        Group {
            if let image = QRCodeGenerator.image(for: payload) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
            } else {
                Color.secondary.opacity(0.1)
                    .frame(width: size, height: size)
                    .overlay(Image(systemName: "qrcode").font(.system(size: 40)).foregroundStyle(.secondary))
            }
        }
    }
}

enum QRCodeGenerator {
    static func image(for string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        // Scale up so it's crisp
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

enum SnapDeepLink {
    /// URL that, when scanned, opens Snap and joins the game.
    static func joinURL(code: String) -> URL {
        URL(string: "snap://join?code=\(code.uppercased())")!
    }

    /// Pull a join code out of a deep link, if it's a recognized join URL.
    static func code(from url: URL) -> String? {
        guard url.scheme?.lowercased() == "snap",
              url.host?.lowercased() == "join" else { return nil }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return comps?.queryItems?.first(where: { $0.name == "code" })?.value?.uppercased()
    }
}
