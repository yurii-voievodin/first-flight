import SpriteKit

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
typealias PlatformFontWeight = UIImage.SymbolWeight
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformFontWeight = NSFont.Weight
#endif

/// Renders an SF Symbol to an SKTexture, cross-platform.
func sfSymbolTexture(name: String, pointSize: CGFloat, weight: PlatformFontWeight = .medium, tintColor: SKColor) -> SKTexture? {
    #if os(iOS)
    let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
    guard let image = UIImage(systemName: name, withConfiguration: config) else { return nil }

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: pointSize, height: pointSize))
    let rendered = renderer.image { _ in
        image.withTintColor(tintColor, renderingMode: .alwaysOriginal)
            .draw(in: CGRect(x: 0, y: 0, width: pointSize, height: pointSize))
    }
    return SKTexture(image: rendered)
    #elseif os(macOS)
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
    guard let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return nil }

    let size = CGSize(width: pointSize, height: pointSize)
    let rendered = NSImage(size: size, flipped: false) { rect in
        NSGraphicsContext.current?.imageInterpolation = .high
        tintColor.set()
        image.draw(in: rect)
        return true
    }
    return SKTexture(image: rendered)
    #endif
}
