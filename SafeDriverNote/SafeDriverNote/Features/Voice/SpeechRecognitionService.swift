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
	@Published var audioLevel: Float = 0.0 // 新增：音频电平监控
	@Published var isListening: Bool = false // 新增：是否检测到语音输入

	private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
	private let audioEngine = AVAudioEngine()
	private var request: SFSpeechAudioBufferRecognitionRequest?
	private var task: SFSpeechRecognitionTask?
	private var initialTranscript: String = ""
	private var finalizedSegments: [String] = []
	private var lastUpdateTime = Date()
	private var silenceTimer: Timer?
	private var voiceDetectionTimer: Timer? // 新增：语音检测定时器
	private let voiceThreshold: Float = 0.02 // 语音检测阈值
	private let silenceThreshold: Float = 0.005 // 静音检测阈值

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
		print("Starting recording. Current transcript: '\(transcript)'")

		let savedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
		initialTranscript = savedTranscript
		finalizedSegments = []
		print("Saved transcript baseline: '\(savedTranscript)'")
		
		let request = SFSpeechAudioBufferRecognitionRequest()
		request.shouldReportPartialResults = true
		// 为更好的标点效果，允许云端并提示口述场景
		request.requiresOnDeviceRecognition = false
		request.taskHint = .dictation
		request.addsPunctuation = true // 启用标点符号添加

		// 优化识别配置
		if #available(iOS 16.0, *) {
			request.addsPunctuation = true
			request.requiresOnDeviceRecognition = false // 使用云端识别获得更好效果
		}

		// 优化识别参数以提高敏感度
		if #available(iOS 13.0, *) {
			// 设置更短的语音检测超时
			request.interactionIdentifier = UUID().uuidString
		}
		self.request = request
		let audioSession = AVAudioSession.sharedInstance()
		do {
			// 使用专门的语音录制模式，提高录音质量
			try audioSession.setCategory(.record, mode: .spokenAudio, options: [.duckOthers, .allowBluetooth, .defaultToSpeaker])
			try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

			// 设置更高的采样率，提高识别准确性
			try audioSession.setPreferredSampleRate(48000.0) // 提高到48kHz

			// 设置更短的I/O缓冲时长，提高响应性
			try audioSession.setPreferredIOBufferDuration(0.005) // 5ms缓冲

			// 设置首选输入数据源和增益
			if let preferredInput = audioSession.availableInputs?.first {
				try audioSession.setPreferredInput(preferredInput)
			}

			// 设置输入增益以提高敏感度（如果支持）
			do {
				try audioSession.setInputGain(0.8) // 设置较高的输入增益
			} catch {
				print("设置输入增益失败: \(error)")
			}
		} catch {
			print("音频会话配置失败: \(error)")
			// 回退到基本配置
			try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
			try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
		}
		let input = audioEngine.inputNode
		let format = input.outputFormat(forBus: 0)
		input.removeTap(onBus: 0)

		// 使用更小的缓冲区以获得更快的响应速度
		let bufferSize: AVAudioFrameCount = 1024 // 降低缓冲区大小提高响应性
		input.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
			guard let self = self else { return }

			// 监控音频电平和语音活动，帮助用户了解录音质量
			Task { @MainActor in
				self.updateAudioLevel(from: buffer)
				self.detectVoiceActivity(from: buffer)
			}

			self.request?.append(buffer)
		}
		audioEngine.prepare()
		do {
			try audioEngine.start()
		} catch {
			print("音频引擎启动失败: \(error)")
			isRecording = false
			return
		}
		isRecording = true
		task = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
			guard let self = self else { return }
			print("Recognition task callback. isFinal: \(result?.isFinal ?? false), hasError: \(error != nil)")
			
			if let result = result {
				let snapshot = result.bestTranscription.formattedString
				print("Received snapshot: '\(snapshot)'")

				// 更新最后识别时间，用于停顿检测
				Task { @MainActor in
					self.lastUpdateTime = Date()
					self.resetSilenceTimer()
				}

				Task { @MainActor in
					if result.isFinal {
						if !snapshot.isEmpty {
							self.finalizedSegments.append(self.improvePunctuation(snapshot))
						}
						self.transcript = self.combinedTranscript(includePartial: nil)
						print("Final transcript: \(self.transcript)")
					} else {
						let partial = snapshot.isEmpty ? nil : self.improvePunctuation(snapshot)
						self.transcript = self.combinedTranscript(includePartial: partial)
						print("Partial transcript: \(self.transcript)")
					}
				}
			}
			
			// 仅在出错时停止；正常识别过程中，即便出现 isFinal 也持续收音，直到用户点击"停止"
			if error != nil {
				print("Recognition error: \(error!.localizedDescription)")
				self.stop()
			}
		}
	}

	func stop() {
		guard isRecording else { return }
		isRecording = false
		isListening = false

		// 停止所有定时器
		silenceTimer?.invalidate()
		silenceTimer = nil
		voiceDetectionTimer?.invalidate()
		voiceDetectionTimer = nil

		audioEngine.stop()
		audioEngine.inputNode.removeTap(onBus: 0)
		request?.endAudio()
		task?.cancel()
		task = nil
		request = nil
		do {
			try AVAudioSession.sharedInstance().setActive(false)
		} catch {
			print("Deactivate session failed: \(error)")
		}

		finalizedSegments = finalizedSegments.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
		transcript = combinedTranscript(includePartial: nil)
		print("Final transcript: '\(transcript)'")
	}
	
	// 改进标点符号的智能处理
	private func improvePunctuation(_ text: String) -> String {
		print("Improving punctuation for text: '\(text)'")

		// 如果文本为空，直接返回原文本
		guard !text.isEmpty else {
			print("Text is empty, returning as is")
			return text
		}

		var result = text

		// 1. 首先清理多余的标点符号（避免重复处理）
		result = cleanExtraPunctuation(result)

		// 2. 处理语音识别中常见的逗号过多问题
		result = replaceConsecutiveCommas(result)

		// 3. 智能识别句子类型并添加合适的标点符号
		result = addIntelligentPunctuation(result)

		// 4. 处理常见的句式结尾
		result = processCommonSentenceEndings(result)

		// 5. 处理常见的疑问句式
		result = processQuestionPatterns(result)

		// 6. 处理常见的感叹句式
		result = processExclamationPatterns(result)

		// 7. 最后再次清理多余的标点符号
		result = cleanExtraPunctuation(result)

		print("Improved punctuation result: '\(result)'")
		return result
	}

	// 新增：智能标点符号添加
	private func addIntelligentPunctuation(_ text: String) -> String {
		var result = text

		// 检查文本是否已经以合适的标点符号结尾
		let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.isEmpty { return result }

		let lastChar = String(trimmed.last!)
		let punctuations = Set(["。", "！", "？", ".", "!", "?"])

		// 如果没有适当的结束标点，根据语境添加
		if !punctuations.contains(lastChar) {
			// 检查是否是疑问句的特征
			let questionIndicators = ["什么", "怎么", "为什么", "哪里", "何时", "谁", "是否", "能不能", "可不可以", "吗", "呢", "吧"]
			let isQuestion = questionIndicators.contains { trimmed.contains($0) }

			// 检查是否是感叹句的特征
			let exclamationIndicators = ["太", "真的", "好棒", "厉害", "不错", "很好", "完美", "糟糕", "天哪"]
			let isExclamation = exclamationIndicators.contains { trimmed.contains($0) }

			if isQuestion {
				result = trimmed + "？"
			} else if isExclamation {
				result = trimmed + "！"
			} else {
				result = trimmed + "。"
			}
		}

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
		
		// 处理不以疑问词开头但可能是疑问句的情况
		let questionPatterns = [
			"([^？?。.！!]{5,})[，,]$",  // 长句子以逗号结尾可能是疑问句
			"(.*[吗呢吧啊么嘛])[，,]$",   // 以疑问语气词结尾的句子
		]
		
		for pattern in questionPatterns {
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
		
		// 处理感叹语气词
		let exclamationPatterns = [
			"(.*[啊呀哇哦嘿])[，,]$",  // 以感叹语气词结尾的句子
		]
		
		for pattern in exclamationPatterns {
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

	private func combinedTranscript(includePartial partial: String?) -> String {
		var segments: [String] = []
		let cleanedInitial = initialTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
		if !cleanedInitial.isEmpty {
			segments.append(cleanedInitial)
		}
		let finalized = finalizedSegments.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
		segments.append(contentsOf: finalized)
		if let partial = partial?.trimmingCharacters(in: .whitespacesAndNewlines), !partial.isEmpty {
			segments.append(partial)
		}
		if segments.isEmpty { return "" }
		return segments.joined(separator: segments.count > 1 ? "\n" : "")
	}

	// 清空 transcript 内容
	func clearTranscript() {
		transcript = ""
		initialTranscript = ""
		finalizedSegments = []
		silenceTimer?.invalidate()
		silenceTimer = nil
		voiceDetectionTimer?.invalidate()
		voiceDetectionTimer = nil
		isListening = false
	}

	// MARK: - 停顿检测和智能标点

	/// 重置停顿检测定时器
	private func resetSilenceTimer() {
		silenceTimer?.invalidate()

		// 设置2秒的停顿检测定时器
		silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
			Task { @MainActor in
				self?.handleSilencePause()
			}
		}
	}

	/// 处理停顿暂停，添加适当的标点符号
	private func handleSilencePause() {
		guard !transcript.isEmpty else { return }

		print("检测到2秒停顿，添加句号")

		// 检查最后一个字符是否已经是标点符号
		let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
		if !trimmed.isEmpty {
			let lastChar = String(trimmed.last!)
			let punctuations = Set(["。", "！", "？", ".", "!", "?", "，", ","])

			if !punctuations.contains(lastChar) {
				// 如果没有标点符号，添加句号
				transcript = trimmed + "。"
				print("添加句号后的文本: '\(transcript)'")
			}
		}
	}

	// MARK: - 音频质量监控

	/// 更新音频电平，用于监控录音质量
	private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
		guard let channelData = buffer.floatChannelData?[0] else { return }

		// 计算音频电平
		let frameCount = Int(buffer.frameLength)
		var sum: Float = 0
		for i in 0..<frameCount {
			let sample = channelData[i]
			sum += sample * sample
		}

		let rms = sqrt(sum / Float(frameCount))
		let avgPower = 20 * log10(max(rms, 0.000001)) // 避免log(0)
		let meterLevel = (avgPower + 60) / 60 // 转换到0-1范围

		DispatchQueue.main.async {
			self.audioLevel = max(0.0, min(1.0, meterLevel))
		}
	}

	// MARK: - 语音活动检测

	/// 检测语音活动，提高识别敏感度
	private func detectVoiceActivity(from buffer: AVAudioPCMBuffer) {
		guard let channelData = buffer.floatChannelData?[0] else { return }

		// 计算RMS音频电平
		let frameCount = Int(buffer.frameLength)
		var sum: Float = 0
		for i in 0..<frameCount {
			let sample = channelData[i]
			sum += sample * sample
		}
		let rms = sqrt(sum / Float(frameCount))

		// 检测是否有语音活动
		let hasVoiceActivity = rms > voiceThreshold

		if hasVoiceActivity && !isListening {
			// 检测到语音开始
			print("检测到语音活动开始，RMS: \(rms)")
			isListening = true
			// 重置停顿检测
			resetSilenceTimer()
		} else if !hasVoiceActivity && isListening {
			// 可能语音停止，启动延迟检测
			startVoiceActivityTimeout()
		} else if hasVoiceActivity && isListening {
			// 持续语音活动，重置停顿检测
			resetSilenceTimer()
		}
	}

	/// 启动语音活动超时检测
	private func startVoiceActivityTimeout() {
		voiceDetectionTimer?.invalidate()
		voiceDetectionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
			Task { @MainActor in
				self?.handleVoiceActivityEnd()
			}
		}
	}

	/// 处理语音活动结束
	private func handleVoiceActivityEnd() {
		print("语音活动结束检测")
		isListening = false
		// 不立即停止识别，而是等待更长的停顿时间
		resetSilenceTimer()
	}
}
