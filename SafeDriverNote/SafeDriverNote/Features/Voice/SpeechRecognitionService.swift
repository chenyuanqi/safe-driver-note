import Foundation
import AVFoundation
import Speech
import AVFAudio

@MainActor
final class SpeechRecognitionService: ObservableObject {
	@Published var transcript: String = ""
	@Published var isRecording: Bool = false
	@Published var recognitionAuthorized: Bool = false
	@Published var micAuthorized: Bool = false

	private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
	private let audioEngine = AVAudioEngine()
	private var request: SFSpeechAudioBufferRecognitionRequest?
	private var task: SFSpeechRecognitionTask?

	func requestPermissions() async {
		// 语音识别
		let speechAuth = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
			SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
		}
		recognitionAuthorized = (speechAuth == .authorized)
		// 麦克风
		if #available(iOS 17.0, *) {
			let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
				AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
			}
			micAuthorized = granted
		} else {
			let granted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
				AVAudioSession.sharedInstance().requestRecordPermission { cont.resume(returning: $0) }
			}
			micAuthorized = granted
		}
	}

	func start() {
		guard recognitionAuthorized, micAuthorized, !isRecording else { return }
		transcript = ""
		let request = SFSpeechAudioBufferRecognitionRequest()
		request.shouldReportPartialResults = true
		request.requiresOnDeviceRecognition = true
		self.request = request
		let audioSession = AVAudioSession.sharedInstance()
		try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
		try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
		let input = audioEngine.inputNode
		let format = input.outputFormat(forBus: 0)
		input.removeTap(onBus: 0)
		input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
			self?.request?.append(buffer)
		}
		audioEngine.prepare()
		try? audioEngine.start()
		isRecording = true
		task = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
			guard let self = self else { return }
			if let result = result {
				Task { @MainActor in self.transcript = result.bestTranscription.formattedString }
			}
			// 仅在出错时停止；正常识别过程中，即便出现 isFinal 也持续收音，直到用户点击“停止”
			if error != nil {
				self.stop()
			}
		}
	}

	func stop() {
		guard isRecording else { return }
		isRecording = false
		audioEngine.stop()
		audioEngine.inputNode.removeTap(onBus: 0)
		request?.endAudio()
		task?.cancel()
		task = nil
		request = nil
		try? AVAudioSession.sharedInstance().setActive(false)
	}
}


