import SwiftUI
import BeatLabCore
import AVFoundation
import Darwin
import UIKit

struct MetronomeView: View {
    @EnvironmentObject private var store: ConfigurationStore
    @EnvironmentObject private var audio: MetronomeAudio
    @EnvironmentObject private var practice: PracticeStore
    @Environment(\.dynamicTypeSize) private var textSize
    @ScaledMetric(relativeTo: .largeTitle) private var tempoSize = 76.0
    @State private var confirmReset = false
    @State private var tapTempo = TapTempo()
    @State private var tempoFeedback: String?
    @State private var showSettings = false
    let openPractice: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let notice = store.notice {
                    BLStatusMessage(text: message(for: notice), symbol: "exclamationmark.circle.fill")
                        .accessibilityIdentifier("settingsNotice")
                    if notice == .unsupportedSchema {
                        Button("重設節拍器設定", role: .destructive) { confirmReset = true }.frame(minHeight: 44)
                    }
                }
                BLCard {
                    VStack(spacing: 16) {
                        Text("找到舒服的速度").font(.subheadline.weight(.semibold)).foregroundStyle(BeatLabStyle.muted)
                        HStack {
                            Spacer()
                            Button { tapTempo.reset(); tempoFeedback = nil; store.undoTempo() } label: { Image(systemName: "arrow.uturn.backward") }
                                .disabled(store.undoTempos.isEmpty).accessibilityLabel("復原速度").accessibilityIdentifier("undoTempo")
                            Button { tapTempo.reset(); tempoFeedback = nil; store.redoTempo() } label: { Image(systemName: "arrow.uturn.forward") }
                                .disabled(store.redoTempos.isEmpty).accessibilityLabel("重做速度").accessibilityIdentifier("redoTempo")
                        }.buttonStyle(BLSecondaryButtonStyle())
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(store.configuration.tempo.bpm)")
                                .font(.system(size: tempoSize, weight: .bold, design: .rounded)).monospacedDigit()
                                .lineLimit(1).minimumScaleFactor(0.5).accessibilityIdentifier("tempoValue")
                                .accessibilityLabel("速度 \(store.configuration.tempo.bpm) BPM")
                            Text("BPM").font(.headline).foregroundStyle(BeatLabStyle.muted).accessibilityHidden(true)
                        }
                        Slider(value: Binding(get: { Double(store.configuration.tempo.bpm) }, set: { manualTempo(Int($0.rounded())) }), in: 30...240, step: 1,
                               onEditingChanged: { if $0 { store.beginTempoGesture() } else { store.endTempoGesture() } })
                            .accessibilityLabel("每分鐘拍數").accessibilityValue("\(store.configuration.tempo.bpm)").accessibilityIdentifier("tempoSlider")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: textSize.isAccessibilitySize ? 2 : 4), spacing: 8) {
                            tempoButton(-5, identifier: "tempoMinusFive")
                            tempoButton(-1, identifier: "tempoMinusOne")
                            tempoButton(1, identifier: "tempoPlusOne")
                            tempoButton(5, identifier: "tempoPlusFive")
                        }
                        Button {
                            let now = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                            if let tempo = tapTempo.tap(at: now) {
                                store.setTempo(tempo.bpm); tempoFeedback = "已設為 \(tempo.bpm) BPM"
                            } else { tempoFeedback = "繼續跟著拍，至少連續點 3 下" }
                        } label: { Label("跟著拍，設定速度", systemImage: "hand.tap") }
                        .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("tapTempo")
                        if let tempoFeedback { Text(tempoFeedback).font(.subheadline).foregroundStyle(BeatLabStyle.muted) }
                    }.disabled(!store.canEdit)
                }
                BLCard {
                    VStack(alignment: .leading, spacing: 16) {
                        BLSectionHeading(title: "看著大拍，跟上節奏")
                        BeatVisualizer(interactive: true)
                        if audio.preparingVoice {
                            ProgressView("準備數拍語音…")
                            Button("先用節拍聲開始") { audio.selectSound(.click) }.buttonStyle(BLSecondaryButtonStyle())
                        }
                        if let status = audio.status { BLStatusMessage(text: status, symbol: "speaker.slash.fill") }
                    }
                }
                BLCard {
                    VStack(alignment: .leading, spacing: 16) {
                        DisclosureGroup(isExpanded: $showSettings) {
                            VStack(alignment: .leading, spacing: 16) {
                                ConfigurationSummary(configuration: store.configuration)
                                Picker("拍號", selection: Binding(get: { store.configuration.timeSignature }, set: { tapTempo.reset(); store.setTimeSignature($0) })) {
                                    ForEach(TimeSignature.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }.pickerStyle(.menu).accessibilityIdentifier("signaturePicker")
                                Picker("細分", selection: Binding(get: { store.configuration.subdivision }, set: { store.setSubdivision($0) })) {
                                    ForEach(Subdivision.supported(for: store.configuration.timeSignature), id: \.self) { Text($0.displayName).tag($0) }
                                }.pickerStyle(.menu).accessibilityIdentifier("subdivisionPicker")
                                Toggle("第一拍重音", isOn: Binding(get: { store.configuration.accentEnabled }, set: { store.setAccentEnabled($0) }))
                                    .accessibilityIdentifier("accentToggle")
                                if store.configuration.timeSignature.isCompound {
                                    Text("6/8 有兩個大拍，每拍分成三下：1-la-li、2-la-li。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                                }
                            }.padding(.top, 16).disabled(!store.canEdit)
                        } label: {
                            Label("節奏設定 · \(store.configuration.timeSignature.rawValue)", systemImage: "music.note.list").font(.headline)
                                .accessibilityIdentifier("rhythmSettings")
                        }
                        Divider()
                        Picker("節拍音色", selection: Binding(get: { store.configuration.clickTimbre }, set: { store.setClickTimbre($0) })) {
                            ForEach(ClickTimbre.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }.pickerStyle(.segmented).disabled(!store.canEdit).accessibilityIdentifier("clickTimbrePicker")
                        Picker("數拍聲音", selection: Binding(get: { audio.sound }, set: { audio.selectSound($0) })) {
                            Text("節拍聲").tag(CountSound.click)
                            Text("數拍").tag(CountSound.voice)
                            Text("兩種都要").tag(CountSound.both)
                        }.pickerStyle(.menu).accessibilityIdentifier("countSoundPicker")
                        if audio.sound != .click {
                            Text("八分音符數 1 & 2 &；其他細分數大拍。快速度可改用節拍聲。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("聲音大小").font(.subheadline.weight(.semibold))
                            Slider(value: Binding(get: { Double(audio.volume) }, set: { audio.setGain(Float($0)) }), in: 0...1)
                                .accessibilityLabel("節拍音量").accessibilityValue("\(Int(audio.volume * 100))%")
                                .accessibilityIdentifier("volumeSlider")
                        }
                        Toggle(isOn: Binding(get: { store.configuration.screenPulseEnabled }, set: { store.setScreenPulseEnabled($0) })) {
                            Label("畫面閃光提示", systemImage: "sun.max")
                        }.disabled(!store.canEdit).accessibilityIdentifier("screenPulseToggle")
                        Toggle(isOn: Binding(get: { store.configuration.hapticsEnabled }, set: { store.setHapticsEnabled($0) })) {
                            Label("震動提示", systemImage: "iphone.radiowaves.left.and.right")
                        }.disabled(!store.canEdit || UIDevice.current.userInterfaceIdiom != .phone).accessibilityIdentifier("hapticsToggle")
                        Text("將音量拉到零，可只用畫面或震動跟拍。震動依裝置能力提供；提示不作精準度量測。").font(.subheadline).foregroundStyle(BeatLabStyle.muted)
                    }
                }
                BLCard {
                    VStack(alignment: .leading, spacing: 16) {
                        BLSectionHeading(title: "顯示模式", subtitle: "入門看大拍，標準多一些練習工具。")
                        BLModePicker()
                        if practice.mode == .standard { challenges }
                    }
                }
                Button(action: openPractice) { Label("試試跟拍小挑戰", systemImage: "arrow.right") }
                    .buttonStyle(BLSecondaryButtonStyle()).accessibilityIdentifier("openPractice")
            }.padding(20).frame(maxWidth: BeatLabStyle.maxWidth, alignment: .leading).frame(maxWidth: .infinity)
        }
        .background(BeatLabStyle.canvas).foregroundStyle(BeatLabStyle.ink)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                if audio.isPlaying { audio.stop() } else { audio.start(configuration: store.configuration) }
            } label: { Label(audio.isPlaying ? "停止節拍" : "開始節拍", systemImage: audio.isPlaying ? "stop.fill" : "play.fill") }
            .buttonStyle(BLPrimaryButtonStyle()).disabled((!store.canEdit || audio.preparingVoice) && !audio.isPlaying)
            .accessibilityIdentifier("transportButton")
            .padding(.horizontal, 20).padding(.vertical, 12).frame(maxWidth: BeatLabStyle.maxWidth)
            .frame(maxWidth: .infinity).background(BeatLabStyle.canvas)
        }
        .navigationTitle("節拍器").navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("重設會清除節拍器設定，課程進度會保留。", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("重設設定", role: .destructive) { store.resetSettings() }
        }
    }

    private var challenges: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()
            BLSectionHeading(title: "內心節拍挑戰", subtitle: "靜音時繼續數拍，等聲音回來。")
            Picker("Gap Click", selection: Binding(get: { audio.gapBars }, set: { audio.setGap($0) })) {
                Text("關閉").tag(0); Text("出聲 4 小節，靜音 1 小節").tag(1); Text("出聲 4 小節，靜音 2 小節").tag(2)
            }.pickerStyle(.menu).accessibilityIdentifier("gapPicker")
            BLSectionHeading(title: "慢慢加快", subtitle: "每幾小節加 5 BPM，手動改速度就結束升速。")
            Picker("Tempo Ladder", selection: Binding(get: { audio.ladderBars }, set: { audio.setLadder($0) })) {
                Text("關閉").tag(0); Text("每 2 小節 +5").tag(2); Text("每 4 小節 +5").tag(4); Text("每 8 小節 +5").tag(8)
            }.pickerStyle(.menu).accessibilityIdentifier("ladderPicker")
        }
    }
    private func manualTempo(_ bpm: Int) {
        tapTempo.reset(); tempoFeedback = nil; store.setTempo(min(240, max(30, bpm)))
    }
    private func tempoButton(_ delta: Int, identifier: String) -> some View {
        Button(delta > 0 ? "+\(delta)" : "−\(-delta)") { manualTempo(store.configuration.tempo.bpm + delta) }
            .buttonStyle(BLSecondaryButtonStyle())
            .disabled(delta < 0 ? store.configuration.tempo.bpm == 30 : store.configuration.tempo.bpm == 240)
            .accessibilityLabel(delta > 0 ? "增加 \(delta) BPM" : "減少 \(-delta) BPM").accessibilityIdentifier(identifier)
    }
    private func message(for notice: ConfigurationStore.Notice) -> String {
        switch notice {
        case .corruptSettings: return "上次設定無法讀取，先使用 80 BPM。調整速度就能重新保存。"
        case .unsupportedSchema: return "設定需要較新版 BeatLab。請更新 App，或重設節拍器設定。"
        case .invalidSetting: return "這個設定無法使用，已保留原本設定。"
        case .saveFailed: return "設定沒有保存，請再試一次。"
        }
    }
}
