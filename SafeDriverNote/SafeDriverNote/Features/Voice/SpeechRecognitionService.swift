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
	private var baseTextAtStart: String = ""
	private var accumulatedText: String = ""

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
		// 记录启动时已有文本，后续快照基于它叠加；同时保存累计文本
		baseTextAtStart = transcript.isEmpty ? "" : (transcript + " ")
		accumulatedText = transcript
		let request = SFSpeechAudioBufferRecognitionRequest()
		request.shouldReportPartialResults = true
		// 为更好的标点效果，允许云端并提示口述场景
		request.requiresOnDeviceRecognition = false
		request.taskHint = .dictation
		request.addsPunctuation = true // 启用标点符号添加
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
				let snapshot = result.bestTranscription.formattedString
				Task { @MainActor in
					if result.isFinal {
						// 句子完成：累加并更新基线
						self.accumulatedText = self.baseTextAtStart + snapshot
						self.transcript = self.improvePunctuation(self.accumulatedText)
						self.baseTextAtStart = self.transcript + " "
					} else {
						// 进行中：显示累计 + 当前快照
						self.transcript = self.improvePunctuation(self.baseTextAtStart + snapshot)
					}
				}
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
		// 停止后保留 transcript 内容（不清空）
		// 确保 transcript 内容被保留并优化标点
		accumulatedText = transcript
		transcript = improvePunctuation(transcript)
	}
	
	// 改进标点符号的智能处理
	private func improvePunctuation(_ text: String) -> String {
		// 如果文本为空，直接返回
		guard !text.isEmpty else { return text }
		
		var result = text
		
		// 1. 处理句末标点符号
		// 将连续的逗号替换为适当的句号或问号
		result = replaceConsecutiveCommas(result)
		
		// 2. 处理常见的句式结尾
		result = processCommonSentenceEndings(result)
		
		// 3. 处理常见的疑问句式
		result = processQuestionPatterns(result)
		
		// 4. 处理常见的感叹句式
		result = processExclamationPatterns(result)
		
		// 5. 清理多余的标点符号
		result = cleanExtraPunctuation(result)
		
		return result
	}
	
	// 替换连续的逗号
	private func replaceConsecutiveCommas(_ text: String) -> String {
		var result = text
		// 匹配连续的逗号（可能带有空格）
		let pattern = "[，,]+"
		let regex = try? NSRegularExpression(pattern: pattern)
		let range = NSRange(location: 0, length: result.utf16.count)
		
		// 从后往前替换，避免索引问题
		if let matches = regex?.matches(in: result, range: range).reversed() {
			for match in matches {
				let matchRange = Range(match.range, in: result)!
				let matchText = String(result[matchRange])
				
				// 如果连续逗号超过3个，替换为句号
				if matchText.count > 3 {
					result.replaceSubrange(matchRange, with: "。")
				} else if matchText.count > 1 {
					// 如果连续逗号2-3个，替换为单个逗号
					result.replaceSubrange(matchRange, with: "，")
				}
			}
		}
		
		return result
	}
	
	// 处理常见的句式结尾
	private func processCommonSentenceEndings(_ text: String) -> String {
		var result = text
		
		// 定义常见的句式结尾词
		let sentenceEndings = ["完毕", "结束", "完成", "好了", "可以了", "行了", "就这样"]
		
		for ending in sentenceEndings {
			let pattern = "\(ending)[，,]*"
			let regex = try? NSRegularExpression(pattern: pattern)
			let range = NSRange(location: 0, length: result.utf16.count)
			
			if let match = regex?.firstMatch(in: result, range: range) {
				let matchRange = Range(match.range, in: result)!
				result.replaceSubrange(matchRange, with: ending + "。")
			}
		}
		
		return result
	}
	
	// 处理常见的疑问句式
	private func processQuestionPatterns(_ text: String) -> String {
		var result = text
		
		// 定义常见的疑问词
		let questionWords = ["什么", "怎么", "为什么", "哪里", "何时", "谁", "是否", "能不能", "可不可以"]
		
		// 检查句子是否以疑问词开头且以逗号结尾
		for questionWord in questionWords {
			let pattern = "\(questionWord)[^？?。.]*[，,]"
			let regex = try? NSRegularExpression(pattern: pattern)
			let range = NSRange(location: 0, length: result.utf16.count)
			
			if let match = regex?.firstMatch(in: result, range: range) {
				let matchRange = Range(match.range, in: result)!
				let matchText = String(result[matchRange])
				// 将结尾的逗号替换为问号
				let newtext = matchText.replacingOccurrences(of: "[，,]$", with: "？", options: .regularExpression)
				result.replaceSubrange(matchRange, with: newtext)
			}
		}
		
		return result
	}
	
	// 处理常见的感叹句式
	private func processExclamationPatterns(_ text: String) -> String {
		var result = text
		
		// 定义常见的感叹词
		let exclamationWords = ["太好了", "真棒", "不错", "很好", "完美", "厉害", " amazing", " great"]
		
		for word in exclamationWords {
			let pattern = "\(word)[^！!。.]*[，,]"
			let regex = try? NSRegularExpression(pattern: pattern)
			let range = NSRange(location: 0, length: result.utf16.count)
			
			if let match = regex?.firstMatch(in: result, range: range) {
				let matchRange = Range(match.range, in: result)!
				let matchText = String(result[matchRange])
				// 将结尾的逗号替换为感叹号
				let newtext = matchText.replacingOccurrences(of: "[，,]$", with: "！", options: .regularExpression)
				result.replaceSubrange(matchRange, with: newtext)
			}
		}
		
		return result
	}
	
	// 清理多余的标点符号
	private func cleanExtraPunctuation(_ text: String) -> String {
		var result = text
		
		// 替换多个连续的标点符号为单个
		let patterns = [
			"[。.]{2,}": "。",
			"[！!]{2,}": "！",
			"[？?]{2,}": "？",
			"[，,]{2,}": "，"
		]
		
		for (pattern, replacement) in patterns {
			result = result.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
		}
		
		return result
	}
}