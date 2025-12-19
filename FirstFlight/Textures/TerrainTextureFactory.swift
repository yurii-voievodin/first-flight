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

    struct Params {
        var size: Int = 128

        // Rock
        var rockContrast: Float = 1.25
        var rockBrightness: Float = -0.05
        var rockSharpness: Float = 0.35

        // Dust
        var dustAmount: Float = 0.55        // 0..1
        var dustPatchScale: Float = 10.0    // чим більше — тим більші плями
        var dustColor: CIColor = CIColor(red: 0.62, green: 0.43, blue: 0.28, alpha: 1.0) // “Mars-ish”

        var dustOverlayOpacity: Float = 1.0
        var dustOverlaySoftness: Float = 1.0
    }

    func makeRockWithDustTexture(_ p: Params) -> SKTexture {
        let extent = CGRect(x: 0, y: 0, width: p.size, height: p.size)

        // 1) Base noise
        let baseNoise = CIFilter.randomGenerator().outputImage!
            .cropped(to: extent)

        // Зерно каменю: blur → підняти контраст
        let rockGrain = gaussianBlurWithBleed(baseNoise, radius: 1.5, extent: extent)
            .applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: p.rockSharpness])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: p.rockContrast,
                kCIInputBrightnessKey: p.rockBrightness - 0.06,
                kCIInputSaturationKey: 0.0
            ])

        // 2) “Craters”: великі м’які плями як маска
        let craterNoise = gaussianBlurWithBleed(
            CIFilter.randomGenerator().outputImage!
                .cropped(to: extent),
            radius: 6.0,
            extent: extent
        )
        .applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: 2.0,
            kCIInputBrightnessKey: -0.2,
            kCIInputSaturationKey: 0.0
        ])

        // Легко затемнимо “впадини”
        let darkened = rockGrain.applyingFilter("CIMultiplyCompositing", parameters: [
            kCIInputBackgroundImageKey: craterNoise
        ])

        // 3) Dust mask (великі плями)
        let dustMaskSource = CIFilter.randomGenerator().outputImage!
            .cropped(to: extent)
            .transformed(by: CGAffineTransform(scaleX: 1.0 / CGFloat(p.dustPatchScale),
                                               y: 1.0 / CGFloat(p.dustPatchScale)))
            .cropped(to: extent)

        let dustMask = gaussianBlurWithBleed(dustMaskSource, radius: 5.0, extent: extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 2.0,
                kCIInputBrightnessKey: -0.15,
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

        // 6) Micro speckles (дрібний шум поверх)
        let specklesSource = CIFilter.randomGenerator().outputImage!
            .cropped(to: extent)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.1,
                kCIInputBrightnessKey: -0.45,
                kCIInputSaturationKey: 0.0
            ])

        let speckles = gaussianBlurWithBleed(specklesSource, radius: 0.6, extent: extent)

        let final = speckles.applyingFilter("CIScreenBlendMode", parameters: [
            kCIInputBackgroundImageKey: dusted
        ])

        // Render → SKTexture
        guard let cg = ciContext.createCGImage(final, from: extent) else {
            return SKTexture()
        }
        let tex = SKTexture(cgImage: cg)
        tex.filteringMode = .linear
        return tex
    }

    func makeDustOverlayTexture(_ p: Params) -> SKTexture {
        let extent = CGRect(x: 0, y: 0, width: p.size, height: p.size)

        // 1) Dust mask (великі плями)
        let dustMaskSource = CIFilter.randomGenerator().outputImage!
            .cropped(to: extent)
            .transformed(by: CGAffineTransform(scaleX: 1.0 / CGFloat(p.dustPatchScale),
                                               y: 1.0 / CGFloat(p.dustPatchScale)))
            .cropped(to: extent)

        let dustMask = gaussianBlurWithBleed(
            dustMaskSource,
            radius: 5.0 * CGFloat(p.dustOverlaySoftness),
            extent: extent
        )
        .applyingFilter("CIColorControls", parameters: [
            kCIInputContrastKey: 2.0,
            kCIInputBrightnessKey: -0.15,
            kCIInputSaturationKey: 0.0
        ])

        // 2) Dust tint layer
        let dustColorImage = CIImage(color: p.dustColor).cropped(to: extent)

        // 3) Blend dust color with mask and apply opacity
        let tunedMask = dustMask.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: CGFloat(-0.35 + 0.7 * p.dustAmount),
            kCIInputContrastKey: 1.4
        ])

        let dusted = dustColorImage
            .applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 0)).cropped(to: extent),
                kCIInputMaskImageKey: tunedMask
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: -0.05,
                kCIInputContrastKey: 1.0
            ])

        // 4) Apply opacity
        let opacityFilter = CIFilter.colorMatrix()
        opacityFilter.inputImage = dusted
        opacityFilter.aVector = CIVector(x: 0, y: 0, z: 0, w: CGFloat(p.dustOverlayOpacity))
        guard let final = opacityFilter.outputImage else {
            return SKTexture()
        }

        // Render → SKTexture
        guard let cg = ciContext.createCGImage(final, from: extent) else {
            return SKTexture()
        }
        let tex = SKTexture(cgImage: cg)
        tex.filteringMode = .linear
        return tex
    }
}
