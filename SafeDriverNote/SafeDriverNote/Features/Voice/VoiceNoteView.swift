import SwiftUI
import AVFoundation
import Speech

struct VoiceNoteView: View {
	@Environment(\.dismiss) private var dismiss

	@State private var isRecording = false
	@State private var transcript: String = ""
	@State private var recognitionAuthorized = false
	@State private var micAuthorized = false
	@State private var isSaving = false
	@State private var showError = false
	@State private var errorMessage = ""

	private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
	private let audioEngine = AVAudioEngine()
	private var inputNode: AVAudioInputNode? { audioEngine.inputNode }
	private var recordingFormat: AVAudioFormat? { audioEngine.inputNode.outputFormat(forBus: 0) }
	private var request = SFSpeechAudioBufferRecognitionRequest()
	private var task: SFSpeechRecognitionTask?

	var body: some View {
		VStack(spacing: Spacing.lg) {
			Text("语音记录")
				.font(.title2)
				.fontWeight(.semibold)
				.frame(maxWidth: .infinity, alignment: .leading)

			Card(backgroundColor: .white, shadow: true) {
				VStack(alignment: .leading, spacing: Spacing.md) {
					HStack(spacing: Spacing.md) {
						Image(systemName: isRecording ? "mic.fill" : "mic")
							.font(.title2)
							.foregroundColor(isRecording ? .brandDanger500 : .brandPrimary500)
						Text(isRecording ? "正在录音与识别…" : "点击开始录音")
							.font(.bodyLarge)
							.foregroundColor(.brandSecondary900)
						Spacer()
					}
					Divider()
					ScrollView {
						Text(transcript.isEmpty ? "转写内容会显示在这里…" : transcript)
							.font(.body)
							.foregroundColor(.brandSecondary800)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.frame(minHeight: 180)
				}
			}

			HStack(spacing: Spacing.lg) {
				Button(isRecording ? "停止" : "开始") { toggleRecording() }
					.primaryStyle()
					.disabled(!recognitionAuthorized || !micAuthorized)

				Button("保存为日志") { Task { await saveToLog() } }
					.secondaryStyle()
					.disabled(transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
			}

			Spacer()
		}
		.padding(Spacing.pagePadding)
		.background(Color.brandSecondary50)
		.onAppear { Task { await requestPermissions() } }
		.alert("错误", isPresented: $showError) {
			Button("知道了") { }
		} message: { Text(errorMessage) }
	}

	private func requestPermissions() async {
		// 语音识别权限
		let speechAuth = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
			SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
		}
		recognitionAuthorized = speechAuth == .authorized
		// 麦克风权限
		let mic = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
			AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
		}
		micAuthorized = mic
	}

	private func toggleRecording() {
		if isRecording { stopRecording() } else { startRecording() }
	}

	private func startRecording() {
		guard recognitionAuthorized, micAuthorized else { return }
		transcript = ""
		request = SFSpeechAudioBufferRecognitionRequest()
		request.shouldReportPartialResults = true
		request.requiresOnDeviceRecognition = true
		let audioSession = AVAudioSession.sharedInstance()
		try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
		try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
		let input = inputNode
		guard let format = recordingFormat, let input = input else { return }
		audioEngine.inputNode.removeTap(onBus: 0)
		input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
			self.request.append(buffer)
		}
		audioEngine.prepare()
		try? audioEngine.start()
		isRecording = true
		task = speechRecognizer?.recognitionTask(with: request) { result, error in
			if let result = result {
				DispatchQueue.main.async { self.transcript = result.bestTranscription.formattedString }
			}
			if error != nil || (result?.isFinal ?? false) {
				stopRecording()
			}
		}
	}

	private func stopRecording() {
		isRecording = false
		audioEngine.stop()
		audioEngine.inputNode.removeTap(onBus: 0)
		request.endAudio()
		task?.cancel()
		task = nil
		try? AVAudioSession.sharedInstance().setActive(false)
	}

	private func saveToLog() async {
		guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
		isSaving = true
		defer { isSaving = false }
		let fields = Summarizer.summarize(transcript: transcript)
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
			transcript: transcript
		)
		try? AppDI.shared.logRepository.add(entry)
		dismiss()
	}
}

private enum Summarizer {
	static func summarize(transcript: String) -> (type: LogType, scene: String, detail: String, cause: String?, improvement: String?, tags: [String]) {
		let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
		let lower = text.lowercased()
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
		if let firstStop = text.firstIndex(where: { "。！？!?.".contains($0) }) {
			return String(text[..<firstStop])
		}
		return String(text.prefix(30))
	}

	private static func extractCause(from text: String) -> String? {
		if let range = text.range(of: "因为") { return String(text[range.upperBound...]).split(whereSeparator: { "。！？!?.".contains($0) }).first.map(String.init) }
		if let range = text.range(of: "由于") { return String(text[range.upperBound...]).split(whereSeparator: { "。！？!?.".contains($0) }).first.map(String.init) }
		return nil
	}

	private static func extractImprovement(from text: String) -> String? {
		if let r = text.range(of: "改进") { return String(text[r.upperBound...]).split(whereSeparator: { "。！？!?.".contains($0) }).first.map(String.init) }
		if let r = text.range(of: "下次") { return String(text[r.lowerBound...]).split(whereSeparator: { "。！？!?.".contains($0) }).first.map(String.init) }
		if let r = text.range(of: "以后") { return String(text[r.lowerBound...]).split(whereSeparator: { "。！？!?.".contains($0) }).first.map(String.init) }
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


