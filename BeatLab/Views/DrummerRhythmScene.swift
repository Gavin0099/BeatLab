import SpriteKit
import BeatLabCore
import UIKit

/// Read-only musical stage. Every pose is sampled from the existing logical
/// audio position; no SKAction, timer, collision or node creates a hit or sound.
final class DrummerRhythmScene: SKScene {
    var snapshot: (() -> RhythmGameSnapshot?)?
    var elapsed: (() -> Double)?
    var pressedStroke: (() -> Stroke?)?
    var reduced = false
    var showActor = true
    private var builtSize = CGSize.zero
    private var builtActor = true
    private var targetIDs: [Int] = []
    private var notes: [Int: SKShapeNode] = [:]
    private var drumHeads: [SKShapeNode] = []
    private var halos: [SKShapeNode] = []
    private var lamps: [SKShapeNode] = []
    private var sticks: [SKNode] = []
    private var music: [SKLabelNode] = []
    private var actor: SKSpriteNode?
    private var grids: [SKShapeNode] = []
    private let ink = UIColor(named: "Ink") ?? .darkGray
    private let green = UIColor(named: "Success") ?? .systemGreen
    private let gold = UIColor(named: "HomeHero") ?? .systemYellow
    private let soft = UIColor(named: "AccentSoft") ?? .systemGray6
    private let white = UIColor(named: "OnAccent") ?? .white
    private let darkInk = (UIColor(named: "Ink") ?? .darkGray).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    private var hitY: CGFloat { 66 }
    private var topY: CGFloat { max(hitY + 80, size.height - (showActor ? 142 : 46)) }
    private func laneX(_ hand: Stroke) -> CGFloat { size.width * (hand == .left ? 0.25 : 0.75) }
    override func didMove(to view: SKView) { backgroundColor = UIColor(named: "Canvas") ?? .clear; rebuild() }
    @discardableResult private func shape(_ path: CGPath, fill: UIColor, stroke: UIColor = .clear, width: CGFloat = 0, name: String? = nil, z: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(path: path); node.fillColor = fill; node.strokeColor = stroke; node.lineWidth = width; node.name = name; node.zPosition = z; addChild(node); return node
    }
    private func label(_ text: String, x: CGFloat, y: CGFloat, font: CGFloat, color: UIColor) {
        let node = SKLabelNode(text: text); node.fontName = "Arial-BoldMT"; node.fontSize = font; node.fontColor = color
        node.position = CGPoint(x: x, y: y); node.verticalAlignmentMode = .center; node.zPosition = 8; addChild(node)
    }
    private func rebuild() {
        guard size.width > 0, size.height > 0 else { return }
        removeAllChildren(); notes = [:]; targetIDs = []; drumHeads = []; halos = []; lamps = []; sticks = []; music = []; grids = []; actor = nil
        builtSize = size; builtActor = showActor
        // One quiet world, rather than an illustration card over a second UI.
        let backdrop = SKSpriteNode(imageNamed: "RunnerIsland")
        let ratio = max(size.width / max(backdrop.size.width,1), size.height / max(backdrop.size.height,1))
        backdrop.size = CGSize(width: backdrop.size.width * ratio, height: backdrop.size.height * ratio)
        backdrop.position = CGPoint(x: size.width/2, y: size.height/2); backdrop.alpha = 0.12; backdrop.zPosition = -4; addChild(backdrop)
        let laneWidth = min(114, size.width * 0.36)
        for hand in [Stroke.left, .right] {
            let x = laneX(hand)
            shape(CGPath(roundedRect: CGRect(x: x-laneWidth/2, y: hitY, width: laneWidth, height: topY-hitY+20), cornerWidth: 14, cornerHeight: 14, transform: nil), fill: soft.withAlphaComponent(0.66), z: -2)
            let rail = CGMutablePath(); rail.move(to: CGPoint(x: x,y:hitY)); rail.addLine(to: CGPoint(x:x,y:topY+16))
            shape(rail, fill:.clear, stroke:ink.withAlphaComponent(0.14), width:1, z:-1)
            let halo = shape(CGPath(ellipseIn:CGRect(x:-57,y:-31,width:114,height:62),transform:nil),fill: .clear,stroke:green.withAlphaComponent(0.5),width:2,name:hand == .left ? "strike.left" : "strike.right",z:1)
            halo.position = CGPoint(x:x,y:hitY);halos.append(halo)
            let base = shape(CGPath(roundedRect:CGRect(x:x-46,y:16,width:92,height:48),cornerWidth:12,cornerHeight:12,transform:nil), fill:green,z:1)
            base.name = hand == .left ? "drum.left" : "drum.right"
            let head = shape(CGPath(ellipseIn:CGRect(x:-46,y:-23,width:92,height:46),transform:nil),fill:gold,stroke:darkInk.withAlphaComponent(0.6),width:2,z:2)
            head.position=CGPoint(x:x,y:hitY);drumHeads.append(head)
            shape(CGPath(ellipseIn:CGRect(x:x-36,y:hitY-16,width:72,height:32),transform:nil),fill:.clear,stroke:darkInk.withAlphaComponent(0.22),width:1,z:3)
            label(hand == .left ? "左 L" : "右 R", x:x, y:34, font:18, color:white)
        }
        for _ in 0..<10 { let grid=SKShapeNode();grid.strokeColor=ink.withAlphaComponent(0.08);grid.lineWidth=1;grid.zPosition = -1;addChild(grid);grids.append(grid) }
        if showActor { buildActor() }
        else { label("恐龍鼓手",x:size.width/2,y:size.height-20,font:18,color:ink) }
    }
    private func buildActor() {
        let center=CGPoint(x:size.width*0.27,y:size.height-73)
        let shadow=shape(CGPath(ellipseIn:CGRect(x:center.x-52,y:center.y-43,width:104,height:16),transform:nil),fill:green.withAlphaComponent(0.13),z:0)
        shadow.name="performerStage"
        let dino=SKSpriteNode(imageNamed:"HomeDinosaur");dino.name="drummer";dino.size=CGSize(width:102,height:102);dino.position=center;dino.zPosition=1;addChild(dino);actor=dino
        // The stage kit masks the running legs of the reused mascot. Sticks are
        // articulated props, not new raster poses or an autonomous run cycle.
        for index in 0..<2 {
            let x=center.x + (index == 0 ? -18 : 23)
            shape(CGPath(roundedRect:CGRect(x:x-21,y:center.y-46,width:42,height:32),cornerWidth:7,cornerHeight:7,transform:nil),fill:green,z:3)
            shape(CGPath(ellipseIn:CGRect(x:x-22,y:center.y-23,width:44,height:16),transform:nil),fill:gold,stroke:darkInk.withAlphaComponent(0.4),width:1,z:4)
            let pivot=SKNode();pivot.name=index == 0 ? "stick.left" : "stick.right";pivot.position=CGPoint(x:x+(index == 0 ? 4 : -4),y:center.y-8);pivot.zPosition=5
            let shaft=SKShapeNode(rect:CGRect(x:-2,y:0,width:4,height:33),cornerRadius:2);shaft.fillColor=darkInk;shaft.strokeColor=gold;shaft.lineWidth=1;pivot.addChild(shaft);addChild(pivot);sticks.append(pivot)
        }
        label("奏出小島的節奏",x:size.width*0.72,y:size.height-35,font:min(15,size.width/22),color:ink)
        for index in 0..<4 {
            let lamp=shape(CGPath(ellipseIn:CGRect(x:-6,y:-6,width:12,height:12),transform:nil),fill:green.withAlphaComponent(0.15),z:1)
            lamp.position=CGPoint(x:size.width*0.72+CGFloat(index)*20-30,y:size.height-62);lamp.name="lamp.\(index)";lamps.append(lamp)
        }
        label("右手 · 1 & 2 &",x:size.width*0.72,y:size.height-88,font:12,color:ink)
        for index in 0..<3 {
            let note=SKLabelNode(text:"♪");note.fontName="Arial-BoldMT";note.fontSize=16;note.fontColor=gold
            note.alpha=0;note.zPosition=8;note.name="playedMusic.\(index)";addChild(note);music.append(note)
        }
    }
    override func update(_ currentTime: TimeInterval) {
        guard let value=snapshot?(),let now=elapsed?(),now.isFinite,now >= 0,value.bpm > 0,size.width>0,size.height>0 else { return }
        if builtSize != size || builtActor != showActor { rebuild() }
        let ids=value.targets.map(\.id)
        if ids != targetIDs {
            notes.values.forEach { $0.removeFromParent() };notes=[:];targetIDs=ids
            let width=min(78,size.width*0.25)
            for target in value.targets {
                let cue=SKShapeNode(rectOf:CGSize(width:width,height:16),cornerRadius:8);cue.name="note.\(target.id)";cue.fillColor=gold;cue.strokeColor=darkInk.withAlphaComponent(0.7);cue.lineWidth=1.5;cue.zPosition=6
                let highlight=SKShapeNode(rectOf:CGSize(width:width-12,height:3),cornerRadius:1.5);highlight.fillColor=white;highlight.strokeColor = .clear;highlight.alpha=0.7;highlight.position.y=3;cue.addChild(highlight);addChild(cue);notes[target.id]=cue
            }
        }
        let travel=topY-hitY,accepted=value.accepted,missed=value.missed(at:now)
        for target in value.targets {
            guard let distance=value.distance(target,elapsed:now),let cue=notes[target.id] else { continue }
            cue.isHidden=distance>1+1e-10 || accepted.contains(target.id) || missed.contains(target.id)
            let projected=reduced ? ceil(max(0,distance)*4)/4 : max(0,distance)
            cue.position=CGPoint(x:laneX(target.stroke),y:hitY+CGFloat(projected)*travel)
            cue.alpha=reduced && distance>0.10 ? 0.65 : 1
        }
        let divisions=min(4,max(1,value.subdivisions)),beat=60/Double(value.bpm)
        let aligned=(now-value.alignment)/beat*Double(divisions)
        let phase=reduced ? 0 : aligned-floor(aligned)
        for (index,grid) in grids.enumerated() {
            let y=hitY+CGFloat((Double(index)-phase)/Double(2*divisions))*travel
            grid.isHidden=index>2*divisions+1 || y < hitY || y > topY
            let path=CGMutablePath()
            for hand in [Stroke.left,.right] { let x=laneX(hand);path.move(to:CGPoint(x:x-48,y:y));path.addLine(to:CGPoint(x:x+48,y:y)) }
            grid.path=path
        }
        let last=value.hits.last,age=last.map { value.epoch+now-$0.inputTime } ?? .infinity
        let pressing=age >= 0 && age < 0.13
        let hand=pressedStroke?() ?? last?.targetID.flatMap { id in value.targets.first(where:{$0.id==id})?.stroke } ?? .right
        for (index,head) in drumHeads.enumerated() {
            let active=pressing && ((index == 0) == (hand == .left))
            let sink=active && !reduced ? pow(sin(CGFloat(age/0.13) * .pi),2) : 0
            head.position.y=hitY-3*sink
            let glowing=age >= 0 && age < 0.3 && ((index == 0) == (hand == .left))
            let glow=glowing ? 1-CGFloat(age/0.3) : 0
            halos[index].alpha=0.45+glow*0.55
            let wave=glowing && !reduced ? pow(sin(CGFloat(age/0.3) * .pi),2) : 0
            halos[index].setScale(1+wave*0.14)
            halos[index].strokeColor=glowing && last?.grade == .extra ? ink : green
        }
        // A miss/extra cannot drive a successful strike or lamp. Read the last
        // actual match so a rapid extra does not erase its continuous rebound.
        let matched=value.hits.last(where:{$0.targetID != nil})
        let strikeAge=matched.map { value.epoch+now-$0.inputTime } ?? .infinity
        let matchedHand=matched?.targetID.flatMap { id in value.targets.first(where:{$0.id==id})?.stroke }
        // Smooth velocity at preparation, contact (90ms), and return (360ms).
        // These are visual durations, not judgement windows or latency claims.
        var motion:Double = 0
        if strikeAge >= 0 && strikeAge < 0.36 && !reduced {
            let phase=strikeAge/0.36
            let u=phase < 0.25 ? phase/0.25 : (phase-0.25)/0.75
            let eased=u*u*(3-2*u)
            motion=phase < 0.25 ? eased : 1-eased
        }
        for (index,stick) in sticks.enumerated() {
            let rest:CGFloat=index == 0 ? 0.35 : -0.35
            let direction:CGFloat=index == 0 ? 1 : -1
            stick.zRotation=rest+(((index == 0) == (matchedHand == .left)) ? direction*CGFloat(motion)*2 : 0)
        }
        actor?.setScale(1+CGFloat(motion)*0.025)
        for (index,note) in music.enumerated() {
            let visible=strikeAge >= 0 && strikeAge < 0.36
            let progress=visible ? CGFloat(strikeAge/0.36) : 0
            note.alpha=visible ? (1-progress)*(matched?.grade == .perfect ? 1 : 0.7) : 0
            note.position=CGPoint(x:size.width*0.27+48+CGFloat(index)*14+(reduced ? 0 : progress*12),
                                  y:size.height-90+(reduced ? 0 : progress*32))
        }
        for (index,lamp) in lamps.enumerated() {
            let lit=accepted.count >= max(1,Int(ceil(Double(value.targets.count)*Double(index+1)/4)))
            lamp.fillColor=lit ? gold : green.withAlphaComponent(0.15)
        }
    }
}
