import SpriteKit

/// Same timestamp-to-distance projection as A, with horizontal approach.
final class RunnerRhythmScene: FallingRhythmScene {
    override init(size: CGSize) { super.init(size: size); horizontal = true }
    required init?(coder: NSCoder) { super.init(coder: coder); horizontal = true }
}
