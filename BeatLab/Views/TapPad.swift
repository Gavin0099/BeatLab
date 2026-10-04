import SwiftUI
import UIKit
import AVFoundation
import Darwin

private final class TouchPad: UIView {
    var tapped: ((Double, Bool) -> Void)?
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityLabel = "跟拍區"
        accessibilityHint = "跟著節拍點一下"
        accessibilityIdentifier = "practiceTapPad"
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        // UITouch.timestamp is uptime; map its observed age to the audio host clock.
        let hostNow = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let age = max(0, ProcessInfo.processInfo.systemUptime - touch.timestamp)
        tapped?(hostNow - age, false)
    }
    override func accessibilityActivate() -> Bool {
        tapped?(AVAudioTime.seconds(forHostTime: mach_absolute_time()), true)
        return true
    }
}

struct TapPad: UIViewRepresentable {
    var feedback: String = "跟著拍，點這裡"
    let onTap: (Double, Bool) -> Void
    func makeUIView(context: Context) -> UIView {
        let view = TouchPad(); view.tapped = onTap; view.accessibilityValue = feedback; return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        (uiView as? TouchPad)?.tapped = onTap; uiView.accessibilityValue = feedback
    }
}
