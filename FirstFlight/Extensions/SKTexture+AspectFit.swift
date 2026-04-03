import SpriteKit

extension SKTexture {
    func aspectFitSize(maxSize: CGFloat) -> CGSize {
        let textureSize = size()
        let aspectRatio = textureSize.width / textureSize.height
        if aspectRatio > 1 {
            return CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            return CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
    }
}
