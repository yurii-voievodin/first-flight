import SpriteKit
import CoreImage
import CoreImage.CIFilterBuiltins
import OSLog

final class TerrainTextureFactory {
    private let ciContext: CIContext

    init() {
        // GPU context зазвичай швидший
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false
        ])
    }

    /// Applies a Gaussian blur but prevents edge darkening/light seams by clamping pixels beyond the image bounds
    /// (a practical Core Image equivalent of "bleed/extrude" for tile textures).
    private func gaussianBlurWithBleed(_ image: CIImage, radius: CGFloat, extent: CGRect) -> CIImage {
        // Clamp extends edge pixels outward infinitely, so the blur doesn't sample transparent black outside bounds.
        let clamped = image.clampedToExtent()
        let blurred = clamped.applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
        return blurred.cropped(to: extent)
    }

    /// Samples Core Image's infinite random field deterministically by shifting it with an offset.
    /// Optional `scale` lets you sample at larger/smaller feature sizes WITHOUT introducing
    /// transparent edges (scale is applied to the infinite field before cropping).
    private func randomField(extent: CGRect, offset: CGPoint, scale: CGFloat = 1.0) -> CIImage {
        let field = CIFilter.randomGenerator().outputImage!

        // We want: sample field at (local + offset) / scale.
        // Achieve this by scaling the infinite field first, then translating by -offset/scale.
        let scaled = field.transformed(by: CGAffineTransform(scaleX: 1.0 / scale, y: 1.0 / scale))
        let shifted = scaled.transformed(by: CGAffineTransform(translationX: -offset.x / scale, y: -offset.y / scale))
        return shifted.cropped(to: extent)
    }

    /// Final, shared tuning applied at the end of every texture generation.
    private func applyGlobalTuning(_ image: CIImage, params p: Params) -> CIImage {
        image
            .applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: CGFloat(p.globalBrightness),
                kCIInputContrastKey: CGFloat(p.globalContrast),
                kCIInputSaturationKey: 0.0
            ])
            .applyingFilter("CIGammaAdjust", parameters: [
                "inputPower": CGFloat(p.globalGamma)
            ])
    }

    struct Params {
        var size: Int = 128

        /// Pixel offset into the infinite noise field (set from tile coordinate: (x*size, y*size)).
        var fieldOffset: CGPoint = .zero

        // Micro detail
        let speckleOpacity: Float = 0.7   // 0..1, higher = stronger micro-grain

        // Dust
        var dustAmount: Float = 0.10       // 0..1
        let dustPatchScale: Float = 5      // чим більше — тим більші плями

        let dustColor: CIColor = CIColor(red: 0.32, green: 0.33, blue: 0.37, alpha: 1)

        // Base surface (solid) — keeps the texture calm and avoids heavy visual noise.
        let baseColor: CIColor = CIColor(red: 0.10, green: 0.11, blue: 0.13, alpha: 1)

        // Global (applied at the very end of texture generation)
        // These keep the noise structure intact while pushing the texture away from "white sand".
        let globalBrightness: Float = -0.14      // darker overall
        let globalContrast: Float = 0.94         // slightly lower contrast to avoid harsh speckles
        let globalGamma: Float = 1.10            // > 1 darkens mid/high tones; < 1 brightens
    }

    func makeRockWithDustCIImage(_ p: Params) -> CIImage {
        let extent = CGRect(x: 0, y: 0, width: p.size, height: p.size)
        
        
        // 1) Base surface (solid) — no heavy random noise by default.
        let base = CIImage(color: p.baseColor).cropped(to: extent)

        // Optional: micro-grain to avoid a perfectly flat look.
        // For a gritty surface, keep `speckleOpacity` in a stronger range (e.g. 0.6...0.8).
        let baseWithGrain: CIImage
        if p.speckleOpacity > 0.0001 {
            let grainSource = randomField(extent: extent, offset: p.fieldOffset, scale: 1.0)
            let microGrain = gaussianBlurWithBleed(grainSource, radius: 0.8, extent: extent)
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputContrastKey: 0.75,
                    kCIInputBrightnessKey: -0.25,
                    kCIInputSaturationKey: 0.0
                ])
                .applyingFilter("CIOpacity", parameters: [
                    "inputOpacity": CGFloat(p.speckleOpacity)
                ])
            baseWithGrain = microGrain.applyingFilter("CISourceOverCompositing", parameters: [
                kCIInputBackgroundImageKey: base
            ])
        } else {
            baseWithGrain = base
        }

        // 3) Dust mask (великі плями)
        let dustMaskSource = randomField(
            extent: extent,
            offset: CGPoint(x: p.fieldOffset.x + 313, y: p.fieldOffset.y + 701),
            scale: CGFloat(p.dustPatchScale)
        )

        let dustMask = gaussianBlurWithBleed(dustMaskSource, radius: 7.0, extent: extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.55,
                kCIInputBrightnessKey: -0.10,
                kCIInputSaturationKey: 0.0
            ])

        // 4) Dust tint layer
        let dustColorImage = CIImage(color: p.dustColor).cropped(to: extent)

        // 5) Blend dust only where mask says, and scale amount
        // Маску “приглушимо/посилимо” через brightness (simple control)
        let tunedMask = dustMask.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: CGFloat(-0.35 + 0.7 * p.dustAmount),
            kCIInputContrastKey: 1.4
        ])

        let dusted = dustColorImage
            .applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: baseWithGrain,
                kCIInputMaskImageKey: tunedMask
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: -0.05,
                kCIInputContrastKey: 1.0
            ])

        // Global tuning at the very end
        return applyGlobalTuning(dusted, params: p)
    }

    func makeRockWithDustTexture(_ p: Params) -> SKTexture {
        let extent = CGRect(x: 0, y: 0, width: p.size, height: p.size)
        let finalTuned = makeRockWithDustCIImage(p)

        guard let cg = ciContext.createCGImage(finalTuned, from: extent) else {
            Logger.game.error("Failed to create terrain texture for extent \(String(describing: extent))")
            return SKTexture()
        }
        let tex = SKTexture(cgImage: cg)
        tex.usesMipmaps = false
        tex.filteringMode = .linear
        return tex
    }
}

extension TerrainTextureFactory {
    /// Generates CGImages for all tiles on a background queue, then builds the SKTileSet on the main thread.
    static func generateTerrainTextures(tileColumns: Int, tileRows: Int, tileSize: CGFloat, completion: @escaping (SKTileSet) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let factory = TerrainTextureFactory()
            var cgImages: [CGImage?] = Array(repeating: nil, count: tileColumns * tileRows)
            let extent = CGRect(x: 0, y: 0, width: Int(tileSize), height: Int(tileSize))

            for r in 0..<tileRows {
                for c in 0..<tileColumns {
                    let seed = (c &* 73856093) ^ (r &* 19349663)
                    let normalized = Float(seed & 0xFFFF) / 65535.0
                    let dustAmount = 0.06 + 0.10 * normalized

                    var p = TerrainTextureFactory.Params(size: Int(tileSize))
                    p.dustAmount = dustAmount
                    p.fieldOffset = CGPoint(x: CGFloat(c) * tileSize, y: CGFloat(r) * tileSize)

                    let ciImage = factory.makeRockWithDustCIImage(p)
                    cgImages[r * tileColumns + c] = factory.ciContext.createCGImage(ciImage, from: extent)
                }
            }

            DispatchQueue.main.async {
                var groups: [SKTileGroup] = []
                groups.reserveCapacity(tileColumns * tileRows)

                for i in 0..<cgImages.count {
                    let texture: SKTexture
                    if let cg = cgImages[i] {
                        texture = SKTexture(cgImage: cg)
                        texture.usesMipmaps = false
                        texture.filteringMode = .linear
                    } else {
                        texture = SKTexture()
                    }
                    let def = SKTileDefinition(texture: texture)
                    let rule = SKTileGroupRule(adjacency: .adjacencyAll, tileDefinitions: [def])
                    groups.append(SKTileGroup(rules: [rule]))
                }

                completion(SKTileSet(tileGroups: groups))
            }
        }
    }

    /// Synchronous variant for callers that cannot use async.
    static func generateTerrainTextures(tileColumns: Int, tileRows: Int, tileSize: CGFloat) -> SKTileSet {
        let factory = TerrainTextureFactory()

        var groups: [SKTileGroup] = []
        groups.reserveCapacity(tileColumns * tileRows)

        for r in 0..<tileRows {
            for c in 0..<tileColumns {
                let seed = (c &* 73856093) ^ (r &* 19349663)
                let normalized = Float(seed & 0xFFFF) / 65535.0
                let dustAmount = 0.06 + 0.10 * normalized

                var p = TerrainTextureFactory.Params(size: Int(tileSize))
                p.dustAmount = dustAmount
                p.fieldOffset = CGPoint(x: CGFloat(c) * tileSize, y: CGFloat(r) * tileSize)

                let texture = factory.makeRockWithDustTexture(p)

                let def = SKTileDefinition(texture: texture)
                let rule = SKTileGroupRule(adjacency: .adjacencyAll, tileDefinitions: [def])
                groups.append(SKTileGroup(rules: [rule]))
            }
        }

        return SKTileSet(tileGroups: groups)
    }
}
