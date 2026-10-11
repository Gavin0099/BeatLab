import SpriteKit
import BeatLabCore
import UIKit

/// Persistent, read-only rhythm lane. Display refresh never judges inputs.
class FallingRhythmScene: SKScene {
    var snapshot: (() -> RhythmGameSnapshot?)?
    var elapsed: (() -> Double)?
    var reduced = false
    var horizontal = false
    private var notes: [Int: SKShapeNode] = [:]
    private var targetIDs: [Int] = []
    private var strokes: [Stroke] = []
    private var geometrySize = CGSize.zero
    private let line = SKShapeNode()
    private let lineOutline = SKShapeNode()
    private var grids: [SKShapeNode] = []
    private let left = SKLabelNode(text: "左 L")
    private let right = SKLabelNode(text: "右 R")
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        if line.parent == nil {
            lineOutline.strokeColor = UIColor(named: "Ink") ?? .darkGray; lineOutline.lineWidth = 9; addChild(lineOutline)
            line.strokeColor = UIColor(named: "HomeHero") ?? .systemYellow; line.lineWidth = 5; line.zPosition = 1; addChild(line)
            for label in [left, right] { label.fontName = "Arial-BoldMT"; label.fontSize = 16; label.fontColor = UIColor(named: "Ink"); addChild(label) }
            for _ in 0..<10 { let grid = SKShapeNode(); grid.strokeColor = (UIColor(named: "Separator") ?? .gray).withAlphaComponent(0.6); grid.lineWidth = 1; addChild(grid); grids.append(grid) }
        }
    }
    override func update(_ currentTime: TimeInterval) {
        guard let value = snapshot?(), let now = elapsed?(), now.isFinite, size.width > 0, size.height > 0 else { return }
        let ids = value.targets.map(\.id)
        if targetIDs != ids || strokes != value.targets.map(\.stroke) {
            notes.values.forEach { $0.removeFromParent() }; notes = [:]; targetIDs = ids; strokes = value.targets.map(\.stroke); geometrySize = .zero
            for target in value.targets {
                let node = SKShapeNode(rectOf: CGSize(width: 66, height: 32), cornerRadius: 12)
                node.name = "note.\(target.id)"; node.lineWidth = 2; node.strokeColor = UIColor(named: "Ink") ?? .darkGray
                node.fillColor = UIColor(named: target.stroke == .left ? "HomeHero" : "Success") ?? .systemGreen
                let label = SKLabelNode(text: target.stroke == .left ? "L" : "R")
                label.fontName = "Arial-BoldMT"; label.fontSize = 21; label.fontColor = target.stroke == .left ? UIColor(named: "Ink")?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)) : UIColor(named: "OnAccent")
                label.verticalAlignmentMode = .center; node.addChild(label); notes[target.id] = node; addChild(node)
            }
        }
        let hitY: CGFloat = 46
        let travel = max(40, size.height - hitY - 32)
        let hitX = size.width * 0.22
        if geometrySize != size {
            geometrySize = size
            let shortest = zip(value.targets, value.targets.dropFirst()).map { $0.1.time - $0.0.time }.min() ?? (60 / Double(value.bpm))
            let fraction = shortest / (2 * 60 / Double(value.bpm))
            let width = horizontal ? min(66, max(22, (size.width - hitX - 36) * fraction * 0.82)) : 66
            let height = horizontal ? 32 : min(32, max(18, travel * fraction * 0.82))
            for node in notes.values {
                node.path = CGPath(roundedRect: CGRect(x: -width/2, y: -height/2, width: width, height: height), cornerWidth: 8, cornerHeight: 8, transform: nil)
                (node.children.first as? SKLabelNode)?.fontSize = horizontal ? 20 : min(21, height - 3)
            }
        }
        let path = CGMutablePath()
        if horizontal { path.move(to: CGPoint(x: hitX, y: 20)); path.addLine(to: CGPoint(x: hitX, y: size.height - 25)) }
        else { path.move(to: CGPoint(x: 16, y: hitY)); path.addLine(to: CGPoint(x: size.width - 16, y: hitY)) }
        line.path = path; lineOutline.path = path
        left.position = CGPoint(x: size.width * 0.25, y: 12); right.position = CGPoint(x: size.width * 0.75, y: 12)
        let missed = value.missed(at: now)
        let accepted = value.accepted
        for target in value.targets {
            guard let distance = value.distance(target, elapsed: now), let node = notes[target.id] else { continue }
            node.isHidden = distance > 1 + 1e-10 || accepted.contains(target.id) || missed.contains(target.id)
            let visualDistance = reduced ? (max(0,distance) * 4).rounded(.up) / 4 : max(0,distance)
            if horizontal { node.position = CGPoint(x: hitX + CGFloat(visualDistance) * (size.width - hitX - 36), y: target.stroke == .left ? size.height * 0.35 : size.height * 0.70) }
            else { node.position = CGPoint(x: size.width * (target.stroke == .left ? 0.25 : 0.75), y: hitY + CGFloat(visualDistance) * travel) }
            if reduced { node.alpha = distance < 0.10 ? 1 : 0.65 } else { node.alpha = 1 }
        }
        let beat = 60 / Double(value.bpm)
        let divisions = min(4, max(1, value.subdivisions))
        let aligned = (now - value.alignment) / beat * Double(divisions)
        let phase = reduced ? 0 : aligned - floor(aligned)
        for (index, grid) in grids.enumerated() {
            grid.isHidden = index > 2 * divisions + 1
            let p = CGMutablePath()
            if horizontal {
                let x = hitX + CGFloat((Double(index) - phase) / Double(2 * divisions)) * (size.width - hitX - 36)
                p.move(to: CGPoint(x: x, y: 26)); p.addLine(to: CGPoint(x: x, y: size.height - 25))
            } else {
                let y = hitY + CGFloat((Double(index) - phase) / Double(2 * divisions)) * travel
                p.move(to: CGPoint(x: 16, y: y)); p.addLine(to: CGPoint(x: size.width - 16, y: y))
            }
            grid.path = p; grid.zPosition = -1
        }
    }
}
