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

			// 检查权限状态
			if !speech.recognitionAuthorized || !speech.micAuthorized {
				// 权限未授予时显示引导卡片
				Card(backgroundColor: Color.brandWarning500.opacity(0.1), shadow: true) {
					VStack(alignment: .leading, spacing: Spacing.lg) {
						HStack(spacing: Spacing.md) {
							Image(systemName: "exclamationmark.triangle.fill")
								.font(.title2)
								.foregroundColor(.brandWarning500)

							VStack(alignment: .leading, spacing: Spacing.xs) {
								Text("需要授权")
									.font(.bodyLarge)
									.fontWeight(.semibold)
									.foregroundColor(.brandSecondary900)

								Text("使用语音记录功能需要麦克风和语音识别权限")
									.font(.body)
									.foregroundColor(.brandSecondary700)
							}

							Spacer()
						}

						VStack(alignment: .leading, spacing: Spacing.md) {
							if !speech.micAuthorized {
								HStack(spacing: Spacing.sm) {
									Image(systemName: "mic.slash")
										.font(.body)
										.foregroundColor(.brandDanger500)
									Text("麦克风权限未授予")
										.font(.body)
										.foregroundColor(.brandSecondary700)
								}
							}

							if !speech.recognitionAuthorized {
								HStack(spacing: Spacing.sm) {
									Image(systemName: "waveform.slash")
										.font(.body)
										.foregroundColor(.brandDanger500)
									Text("语音识别权限未授予")
										.font(.body)
										.foregroundColor(.brandSecondary700)
								}
							}
						}

						HStack(spacing: Spacing.md) {
							Button("立即授权") {
								Task { await speech.requestPermissions() }
							}
							.primaryStyle()

							Button("前往设置") {
								if let url = URL(string: UIApplication.openSettingsURLString) {
									UIApplication.shared.open(url)
								}
							}
							.secondaryStyle()
						}
					}
				}
			} else {
				// 权限已授予时显示正常内容
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
		let type: LogType = detectMistake(in: text) ? .mistake : .success
		let scene = extractScene(from: text)
		let cause = extractCause(from: text)
		let improvement = extractImprovement(from: text)
		let tags = extractTags(from: text)
		let detail = text
		return (type, scene, detail, cause, improvement, tags)
	}

	private static func extractScene(from text: String) -> String {
		let separators = CharacterSet(charactersIn: "。！？!? .\n\r")
		if let range = text.rangeOfCharacter(from: separators) {
			return String(text[..<range.lowerBound])
		}
		return String(text.prefix(30))
	}

	private static func extractCause(from text: String) -> String? {
		let separators = CharacterSet(charactersIn: "。！？!? .\n\r")
		if let range = text.range(of: "因为") { return String(text[range.upperBound...]).components(separatedBy: separators).first?.trimmingCharacters(in: .whitespacesAndNewlines) }
		if let range = text.range(of: "由于") { return String(text[range.upperBound...]).components(separatedBy: separators).first?.trimmingCharacters(in: .whitespacesAndNewlines) }
		return nil
	}

	private static func extractImprovement(from text: String) -> String? {
		let separators = CharacterSet(charactersIn: "。！？!? .\n\r")
		if let r = text.range(of: "改进") { return String(text[r.upperBound...]).components(separatedBy: separators).first?.trimmingCharacters(in: .whitespacesAndNewlines) }
		if let r = text.range(of: "下次") { return String(text[r.lowerBound...]).components(separatedBy: separators).first?.trimmingCharacters(in: .whitespacesAndNewlines) }
		if let r = text.range(of: "以后") { return String(text[r.lowerBound...]).components(separatedBy: separators).first?.trimmingCharacters(in: .whitespacesAndNewlines) }
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

	private static let negativeKeywords: [String] = [
		"撞", "碰撞", "刮擦", "剐蹭", "追尾", "失误", "违章", "超速", "闯红灯", "扣分",
		"罚款", "险情", "危险", "险些", "差点", "没看", "忘记", "没打灯",
		"忘记打灯", "走神", "熄火", "打滑", "侧滑", "翻车", "受伤", "事故", "抱怨"
	]
	private static let negativePhrases: [String] = [
		"发生事故", "撞到", "追尾了", "刮到了", "碰到了", "被扣分", "被罚款", "出了问题",
		"差点出事", "险些发生", "没有看见红灯", "没注意到前车", "忘记检查", "差点撞上"
	]
	private static let positiveKeywords: [String] = [
		"顺利", "安全", "平稳", "顺畅", "顺利完成", "没有问题", "一切正常", "表现不错",
		"成功", "很好", "良好", "状态不错", "无事故", "没有出问题", "平安", "顺利到达", "放心"
	]
	private static let positivePhrases: [String] = [
		"没有发生事故", "没有出问题", "没有任何问题", "一路顺利", "保持安全", "安全到达", "一切良好", "顺利结束"
	]
	private static let negationPrefixes: [String] = ["没有", "未", "不", "并无", "毫无", "无", "没再", "未曾", "没再发生", "没出现"]

	private static func detectMistake(in text: String) -> Bool {
		let sentences = text.components(separatedBy: CharacterSet(charactersIn: "。！？!?\n")).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
		var negativeScore = 0
		var positiveScore = 0

		for sentence in sentences {
			let normalized = sentence.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
			negativeScore += scoreNegative(in: normalized)
			positiveScore += scorePositive(in: normalized)
		}

		if negativeScore == 0 && positiveScore == 0 {
			let normalized = text.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
			negativeScore = scoreNegative(in: normalized)
			positiveScore = scorePositive(in: normalized)
		}

		return negativeScore > max(0, positiveScore)
	}

	private static func scoreNegative(in text: String) -> Int {
		var score = 0
		for keyword in negativeKeywords {
			score += occurrenceCount(of: keyword, in: text)
		}
		for phrase in negativePhrases where text.contains(phrase) {
			score += 2
		}
		return score
	}

	private static func scorePositive(in text: String) -> Int {
		var score = 0
		for keyword in positiveKeywords where text.contains(keyword) {
			score += 1
		}
		for phrase in positivePhrases where text.contains(phrase) {
			score += 2
		}
		return score
	}

	private static func occurrenceCount(of keyword: String, in text: String) -> Int {
		var count = 0
		var searchStart = text.startIndex
		while let range = text.range(of: keyword, options: [], range: searchStart..<text.endIndex) {
			if !hasNegation(before: range, in: text) {
				count += 1
			}
			searchStart = range.upperBound
		}
		return count
	}

	private static func hasNegation(before range: Range<String.Index>, in text: String) -> Bool {
		let maxLookBehind = 4
		let start = text.index(range.lowerBound, offsetBy: -maxLookBehind, limitedBy: text.startIndex) ?? text.startIndex
		let prefix = String(text[start..<range.lowerBound])
		return negationPrefixes.contains(where: { prefix.hasSuffix($0) })
	}
}
