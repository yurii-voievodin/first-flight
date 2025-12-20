import SpriteKit
import CoreImage
import CoreImage.CIFilterBuiltins

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
                kCIInputSaturationKey: 1.0
            ])
            .applyingFilter("CIGammaAdjust", parameters: [
                "inputPower": CGFloat(p.globalGamma)
            ])
    }

    struct Params {
        var size: Int = 128

        /// Pixel offset into the infinite noise field (set from tile coordinate: (x*size, y*size)).
        var fieldOffset: CGPoint = .zero

        /// Layer toggles to simplify the look
        var enableCraters: Bool = true
        var enableSpeckles: Bool = false

        /// Strength 0..1 (lower = more uniform)
        var craterStrength: Float = 0.3

        // Rock
        var rockContrast: Float = 1.12
        var rockBrightness: Float = -0.05
        var rockSharpness: Float = 0.18

        // Micro detail
        var speckleOpacity: Float = 0.2   // 0..1, lower = more homogeneous

        // Dust
        var dustAmount: Float = 0.1        // 0..1
        var dustPatchScale: Float = 16    // чим більше — тим більші плями
        // Darker/less "chalky" dust so the ground doesn't read as white sand
        var dustColor: CIColor = CIColor(red: 0.45, green: 0.32, blue: 0.22, alpha: 1.0) // “Mars-ish”, toned down

        // Global (applied at the very end of texture generation)
        // These keep the noise structure intact while pushing the texture away from "white sand".
        var globalBrightness: Float = -0.35      // darker overall
        var globalContrast: Float = 0.95          // slightly lower contrast to avoid dark speckles popping too much
        var globalGamma: Float = 1.3            // > 1 darkens mid/high tones (reduces the "chalky" look)
    }

    func makeRockWithDustTexture(_ p: Params) -> SKTexture {
        let extent = CGRect(x: 0, y: 0, width: p.size, height: p.size)

        // IMPORTANT: set p.fieldOffset per tile to eliminate seams:
        // e.g. Params(fieldOffset: CGPoint(x: tileX * size, y: tileY * size), ...)

        // 1) Base noise
        let baseNoise = randomField(extent: extent, offset: p.fieldOffset)

        // Зерно каменю: blur → підняти контраст
        let rockGrain = gaussianBlurWithBleed(baseNoise, radius: 2.6, extent: extent)
            .applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: p.rockSharpness])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: p.rockContrast,
                kCIInputBrightnessKey: p.rockBrightness - 0.20,
                kCIInputSaturationKey: 0.0
            ])

        let darkened: CIImage
        if p.enableCraters {
            let craterNoise = gaussianBlurWithBleed(
                randomField(extent: extent, offset: CGPoint(x: p.fieldOffset.x + 911, y: p.fieldOffset.y + 127)),
                radius: 6.0,
                extent: extent
            )
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.35,
                kCIInputBrightnessKey: -0.12,
                kCIInputSaturationKey: 0.0
            ])

            // Control crater impact (0..1)
            let craterAlpha = craterNoise.applyingFilter("CIColorMatrix", parameters: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(p.craterStrength))
            ])

            darkened = rockGrain.applyingFilter("CIMultiplyCompositing", parameters: [
                kCIInputBackgroundImageKey: craterAlpha
            ])
        } else {
            darkened = rockGrain
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
                kCIInputBackgroundImageKey: darkened,
                kCIInputMaskImageKey: tunedMask
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: -0.05,
                kCIInputContrastKey: 1.0
            ])

        let final: CIImage
        if p.enableSpeckles {
            let specklesSource = randomField(
                extent: extent,
                offset: CGPoint(x: p.fieldOffset.x + 42, y: p.fieldOffset.y + 1337)
            )
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 0.95,
                kCIInputBrightnessKey: -0.35,
                kCIInputSaturationKey: 0.0
            ])

            let speckles = gaussianBlurWithBleed(specklesSource, radius: 1.35, extent: extent)
                // Reduce speckle contribution (alpha) to keep the surface more uniform
                .applyingFilter("CIColorMatrix", parameters: [
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(p.speckleOpacity))
                ])

            final = speckles.applyingFilter("CIScreenBlendMode", parameters: [
                kCIInputBackgroundImageKey: dusted
            ])
        } else {
            final = dusted
        }

        // Global tuning at the very end (keeps noise structure intact)
        let finalTuned = applyGlobalTuning(final, params: p)

        // Render → SKTexture
        guard let cg = ciContext.createCGImage(finalTuned, from: extent) else {
            return SKTexture()
        }
        let tex = SKTexture(cgImage: cg)
        tex.usesMipmaps = false
        tex.filteringMode = .linear
        return tex
    }
}

extension TerrainTextureFactory {
    static func generateTerrainTextures(tileColumns: Int, tileRows: Int, tileSize: CGFloat) -> SKTileSet {
        let factory = TerrainTextureFactory()
        
        // One tile group per tile coordinate so we can pass fieldOffset (removes visible seams)
        var groups: [SKTileGroup] = []
        groups.reserveCapacity(tileColumns * tileRows)
        
        let seed: UInt32 = 42
        
        for r in 0..<tileRows {
            for c in 0..<tileColumns {
                // Deterministic variation (no runtime randomness): 0.30 ... 0.70
                let n  = CGFloat.fbmNoise(x: c, y: r, seed: seed)
                let dustAmount = Float(0.30 + (0.40 * n))
                
                var p = TerrainTextureFactory.Params(size: Int(tileSize))
                p.dustAmount = dustAmount
                
                // Critical: offset into the infinite CI random field so tiles line up seamlessly
                p.fieldOffset = CGPoint(
                    x: CGFloat(c) * tileSize,
                    y: CGFloat(r) * tileSize
                )
                
                let texture = factory.makeRockWithDustTexture(p)
                
                let def = SKTileDefinition(texture: texture)
                let rule = SKTileGroupRule(adjacency: .adjacencyAll, tileDefinitions: [def])
                let group = SKTileGroup(rules: [rule])
                groups.append(group)
            }
        }
        
        return SKTileSet(tileGroups: groups)
    }
}
