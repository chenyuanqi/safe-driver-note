import SwiftUI
import AVFoundation

struct VoiceNoteView: View {
	@Environment(\.dismiss) private var dismiss

	@StateObject private var speech = SpeechRecognitionService()
	@State private var isSaving = false
	@State private var showError = false
	@State private var errorMessage = ""

	var body: some View {
		VStack(spacing: Spacing.lg) {
			Text("语音记录")
				.font(.title2)
				.fontWeight(.semibold)
				.frame(maxWidth: .infinity, alignment: .leading)

			Card(shadow: true) {
				VStack(alignment: .leading, spacing: Spacing.md) {
					HStack(spacing: Spacing.md) {
						Image(systemName: speech.isRecording ? "mic.fill" : "mic")
							.font(.title2)
							.foregroundColor(speech.isRecording ? .brandDanger500 : .brandPrimary500)

						VStack(alignment: .leading, spacing: Spacing.xs) {
							Text(speech.isRecording ?
								(speech.isListening ? "识别中..." : "等待语音...") :
								"点击开始录音")
								.font(.bodyLarge)
								.foregroundColor(.brandSecondary900)

							// 显示录音状态和音频电平
							if speech.isRecording {
								HStack(spacing: Spacing.xs) {
									// 语音状态指示器
									Circle()
										.fill(speech.isListening ? Color.green : Color.orange)
										.frame(width: 8, height: 8)

									Text(speech.isListening ? "检测到语音" : "等待语音输入")
										.font(.caption)
										.foregroundColor(.brandSecondary500)

									Spacer()
								}

								HStack(spacing: Spacing.xs) {
									Text("音量:")
										.font(.caption)
										.foregroundColor(.brandSecondary500)

									GeometryReader { geometry in
										ZStack(alignment: .leading) {
											Rectangle()
												.fill(Color.brandSecondary200)
												.frame(height: 4)

											Rectangle()
												.fill(speech.audioLevel > 0.8 ? Color.brandDanger500 :
													  speech.audioLevel > 0.5 ? Color.brandWarning500 : Color.brandPrimary500)
												.frame(width: max(2, geometry.size.width * CGFloat(speech.audioLevel)), height: 4)
										}
									}
									.frame(height: 4)
									.clipShape(Capsule())
								}
							}
						}

						Spacer()
					}
					.contentShape(Rectangle())
					.onTapGesture { toggleRecording() }
					Divider()
					
					// 可编辑的文本区域
					TextEditor(text: $speech.transcript)
						.font(.body)
						.foregroundColor(.brandSecondary700)
						.frame(minHeight: 180)
						.disabled(speech.isRecording) // 录音时禁用编辑
				}
			}

			HStack(spacing: Spacing.lg) {
				Button("保存为日志") { Task { await saveToLog() } }
					.secondaryStyle()
					.disabled(speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
			}

			Spacer()
		}
		.padding(Spacing.pagePadding)
		.background(Color.brandSecondary50)
		.onAppear { 
			Task { await speech.requestPermissions() }
		}
		.alert("错误", isPresented: $showError) {
			Button("知道了") { }
		} message: { Text(errorMessage) }
	}

	private func toggleRecording() {
		if speech.isRecording { 
			speech.stop() 
		} else { 
			speech.start() 
		}
	}

	private func saveToLog() async {
		guard !speech.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
		isSaving = true
		defer { isSaving = false }
		let fields = Summarizer.summarize(transcript: speech.transcript)
		let locationNote = await LocationService.shared.getCurrentLocationDescription()
		let tags = fields.tags
		let entry = LogEntry(
			type: fields.type,
			locationNote: locationNote,
			scene: fields.scene,
			detail: fields.detail,
			cause: fields.cause,
			improvement: fields.improvement,
			tags: tags,
			photoLocalIds: [],
			audioFileName: nil,
			transcript: speech.transcript
		)
		try? AppDI.shared.logRepository.add(entry)
		dismiss()
	}
}

private enum Summarizer {
	static func summarize(transcript: String) -> (type: LogType, scene: String, detail: String, cause: String?, improvement: String?, tags: [String]) {
		let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
		let isMistake = ["失误","碰撞","刮擦","违章","危险","险些","差点","不小心"].contains{ text.contains($0) }
		let type: LogType = isMistake ? .mistake : .success
		let scene = extractScene(from: text)
		let cause = extractCause(from: text)
		let improvement = extractImprovement(from: text)
		let tags = extractTags(from: text)
		let detail = text
		return (type, scene, detail, cause, improvement, tags)
	}

	private static func extractScene(from text: String) -> String {
		if let firstStop = text.firstIndex(where: { "。！？!? .".contains($0) }) {
			return String(text[..<firstStop])
		}
		return String(text.prefix(30))
	}

	private static func extractCause(from text: String) -> String? {
		if let range = text.range(of: "因为") { return String(text[range.upperBound...]).split(whereSeparator: { "。！？!? .".contains($0) }).first.map(String.init) }
		if let range = text.range(of: "由于") { return String(text[range.upperBound...]).split(whereSeparator: { "。！？!? .".contains($0) }).first.map(String.init) }
		return nil
	}

	private static func extractImprovement(from text: String) -> String? {
		if let r = text.range(of: "改进") { return String(text[r.upperBound...]).split(whereSeparator: { "。！？!? .".contains($0) }).first.map(String.init) }
		if let r = text.range(of: "下次") { return String(text[r.lowerBound...]).split(whereSeparator: { "。！？!? .".contains($0) }).first.map(String.init) }
		if let r = text.range(of: "以后") { return String(text[r.lowerBound...]).split(whereSeparator: { "。！？!? .".contains($0) }).first.map(String.init) }
		return nil
	}

	private static func extractTags(from text: String) -> [String] {
		let separators = CharacterSet(charactersIn: " ，。！？,.!?:；;\n")
		let parts = text.components(separatedBy: separators).filter{ $0.count >= 2 }
		let stop = Set(["我","你","他","她","它","我们","他们","是","了","和","也","在","就","对","把","的","地","得","一个","这个","那个","然后","但是","如果","因为","所以","以及","还有"])
		var freq: [String:Int] = [:]
		for p in parts {
			let w = p.trimmingCharacters(in: .whitespaces)
			if w.isEmpty || stop.contains(w) { continue }
			freq[w, default: 0] += 1
		}
		return Array(freq.sorted{ $0.value > $1.value }.prefix(5).map{ $0.key })
	}
}