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

	private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
	private let audioEngine = AVAudioEngine()
	private var request: SFSpeechAudioBufferRecognitionRequest?
	private var task: SFSpeechRecognitionTask?
	private var baseTextAtStart: String = ""
	private var accumulatedText: String = ""
	private var lastUpdateTime = Date()
	private var silenceTimer: Timer?

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
		
		// 保存当前 transcript 内容，防止在初始化过程中被清空
		let savedTranscript = transcript
		print("Saved transcript: '\(savedTranscript)'")
		
		// 记录启动时已有文本，后续快照基于它叠加；同时保存累计文本
		// 确保 baseTextAtStart 始终包含当前 transcript 内容
		baseTextAtStart = savedTranscript.isEmpty ? "" : (savedTranscript + " ")
		accumulatedText = savedTranscript
		print("Set baseTextAtStart: '\(baseTextAtStart)', accumulatedText: '\(accumulatedText)'")
		
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
		self.request = request
		let audioSession = AVAudioSession.sharedInstance()
		do {
			// 使用专门的语音录制模式，提高录音质量
			try audioSession.setCategory(.record, mode: .spokenAudio, options: [.duckOthers, .allowBluetooth])
			try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

			// 设置首选的采样率，提高识别准确性
			try audioSession.setPreferredSampleRate(44100.0)

			// 设置首选输入数据源（如果可用）
			if let preferredInput = audioSession.availableInputs?.first {
				try audioSession.setPreferredInput(preferredInput)
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

		// 使用更大的缓冲区大小以获得更好的音频质量和识别准确性
		let bufferSize: AVAudioFrameCount = 4096
		input.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
			guard let self = self else { return }

			// 监控音频电平，帮助用户了解录音质量
			Task { @MainActor in
				self.updateAudioLevel(from: buffer)
			}

			self.request?.append(buffer)
		}
		audioEngine.prepare()
		try? audioEngine.start()
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
					// 保存当前 transcript 内容
					let previousTranscript = self.transcript
					print("Previous transcript: '\(previousTranscript)'")
					
					if result.isFinal {
						// 句子完成：累加并更新基线
						// 只有当快照不为空时才更新 accumulatedText
						if !snapshot.isEmpty {
							self.accumulatedText = self.baseTextAtStart + snapshot
							print("Final result. Base text: '\(self.baseTextAtStart)', snapshot: '\(snapshot)', accumulated: '\(self.accumulatedText)'")
						} else {
							// 如果快照为空，保留之前的 accumulatedText
							print("Final result but empty snapshot. Keeping accumulatedText: '\(self.accumulatedText)'")
						}
						
						// 使用 accumulatedText 更新 transcript
						if !self.accumulatedText.isEmpty {
							self.transcript = self.improvePunctuation(self.accumulatedText)
							self.baseTextAtStart = self.transcript + " "
							print("Updated transcript to: '\(self.transcript)'")
						} else {
							// 如果 accumulatedText 也为空，保留之前的 transcript
							print("Keeping previous transcript as both snapshot and accumulatedText are empty")
						}
					} else {
						// 进行中：显示累计 + 当前快照
						let newText = self.baseTextAtStart + snapshot
						print("Partial result. Base text: '\(self.baseTextAtStart)', snapshot: '\(snapshot)', new text: '\(newText)'")
						
						// 只有当新文本不为空时才更新 transcript
						if !newText.isEmpty {
							self.transcript = self.improvePunctuation(newText)
							print("Updated transcript to: '\(self.transcript)'")
						} else {
							// 如果新文本为空，保留之前的 transcript
							print("Skipped update - new text is empty, keeping previous transcript: '\(self.transcript)'")
						}
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

		// 停止停顿检测定时器
		silenceTimer?.invalidate()
		silenceTimer = nil

		audioEngine.stop()
		audioEngine.inputNode.removeTap(onBus: 0)
		request?.endAudio()
		task?.cancel()
		task = nil
		request = nil
		try? AVAudioSession.sharedInstance().setActive(false)
		// 停止后保留 transcript 内容（不清空）
		// 确保 transcript 内容被保留并优化标点
		// 保存当前 transcript 内容，以防后续处理中被清空
		let currentTranscript = transcript
		print("Stopping recording. Current transcript: '\(currentTranscript)'")
		
		// 只有当 transcript 不为空时才更新 accumulatedText
		if !currentTranscript.isEmpty {
			accumulatedText = currentTranscript
			print("Updated accumulatedText: '\(accumulatedText)'")
		}
		
		// 对 transcript 进行标点优化，但不改变其内容
		let improvedTranscript = improvePunctuation(currentTranscript)
		print("Improved transcript: '\(improvedTranscript)'")
		
		// 确保即使优化后的文本也不为空时才更新
		if !improvedTranscript.isEmpty {
			transcript = improvedTranscript
			print("Set transcript to improved version")
		}
		// 如果 transcript 为空但 accumulatedText 不为空，恢复 accumulatedText
		else if currentTranscript.isEmpty && !accumulatedText.isEmpty {
			transcript = accumulatedText
			print("Restored transcript from accumulatedText")
		}
		// 如果当前 transcript 不为空但优化后为空，保留当前 transcript
		else if !currentTranscript.isEmpty && improvedTranscript.isEmpty {
			transcript = currentTranscript
			print("Kept original transcript as improved version was empty")
		}
		
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
	
	// 清空 transcript 内容
	func clearTranscript() {
		transcript = ""
		accumulatedText = ""
		baseTextAtStart = ""
		silenceTimer?.invalidate()
		silenceTimer = nil
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
}