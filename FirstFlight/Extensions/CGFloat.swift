import Foundation

extension CGFloat {
    /// Deterministic, cheap fBm-ish noise in [0, 1].
    static func fbmNoise(x: Int, y: Int, seed: UInt32) -> CGFloat {
        // 3 octaves of value noise
        let n1 = valueNoise(x: x, y: y, seed: seed, scale: 1)
        let n2 = valueNoise(x: x, y: y, seed: seed &+ 101, scale: 2)
        let n3 = valueNoise(x: x, y: y, seed: seed &+ 202, scale: 4)
        
        // Weighted sum (normalized)
        let v = (0.55 * n1) + (0.30 * n2) + (0.15 * n3)
        return min(1, max(0, v))
    }
    
    /// Deterministic value noise sampled on a grid (nearest, with implicit clustering via scale).
    private static func valueNoise(x: Int, y: Int, seed: UInt32, scale: Int) -> CGFloat {
        let sx = x / max(1, scale)
        let sy = y / max(1, scale)
        
        let ux = UInt32(truncatingIfNeeded: sx)
        let uy = UInt32(truncatingIfNeeded: sy)
        
        // Hash (sx, sy, seed) -> [0,1) using wrapping 32-bit arithmetic
        var h = (ux &* 374761393) &+ (uy &* 668265263)
        h = h &+ seed &* 1442695041
        h ^= h >> 13
        h &*= 1274126177
        h ^= h >> 16
        
        return CGFloat(Double(h % 10_000) / 10_000.0)
    }
}
