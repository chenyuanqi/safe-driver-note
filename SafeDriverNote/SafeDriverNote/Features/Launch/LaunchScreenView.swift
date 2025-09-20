import SwiftUI

struct LaunchScreenView: View {
    @State private var textOpacity = 0.0
    @State private var textScale = 0.8
    @State private var isAnimating = false
    @State private var pulseAnimation = false
    @State private var warningFlash = false
    @State private var countdown = 5
    @State private var showSkipButton = false

    let onSkip: () -> Void
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 深色警示背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.15, green: 0.0, blue: 0.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 脉冲背景动画
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.red.opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .scaleEffect(pulseAnimation ? 1.5 : 0.8)
                .opacity(pulseAnimation ? 0 : 0.8)
                .animation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: false),
                    value: pulseAnimation
                )

            VStack(spacing: 50) {
                Spacer()

                // 警示图标
                ZStack {
                    // 闪烁的警告三角形
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.yellow)
                        .opacity(warningFlash ? 1 : 0.3)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true),
                            value: warningFlash
                        )

                    // 旋转的光环
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .yellow.opacity(0.8),
                                    .orange.opacity(0.6),
                                    .clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 3)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }

                // 主标语
                VStack(spacing: 20) {
                    Text("道路千万条")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 5, x: 0, y: 2)
                        .opacity(textOpacity)
                        .scaleEffect(textScale)
                        .animation(.spring(response: 0.6, dampingFraction: 0.5), value: textOpacity)

                    Text("安全第一条")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 3)
                        .opacity(textOpacity)
                        .scaleEffect(textScale)
                        .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3), value: textOpacity)
                }

                // 副标语
                Text("慢出稳，练出精，思出透")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(textOpacity)
                    .animation(.easeOut(duration: 1).delay(0.8), value: textOpacity)

                Spacer()

                // 倒计时和汽车动画
                VStack(spacing: 30) {
                    // 道路和汽车动画
                    ZStack {
                        // 道路
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 200, height: 10)

                        // 中心线
                        HStack(spacing: 10) {
                            ForEach(0..<5) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 30, height: 3)
                            }
                        }

                        // 汽车
                        Image(systemName: "car.side.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .offset(x: isAnimating ? 80 : -80)
                            .animation(
                                .easeInOut(duration: 3)
                                .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    }
                    .opacity(textOpacity)
                    .animation(.easeOut(duration: 1).delay(1), value: textOpacity)

                    // 倒计时
                    HStack(spacing: 15) {
                        Image(systemName: "timer")
                            .foregroundColor(.white.opacity(0.7))

                        Text("\(countdown)")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .animation(.spring(), value: countdown)

                        Text("秒")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )

                    // 跳过按钮
                    Button(action: onSkip) {
                        HStack {
                            Text("跳过")
                                .font(.system(size: 16, weight: .medium))
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .opacity(showSkipButton ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: showSkipButton)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation {
                textOpacity = 1.0
                textScale = 1.0
                isAnimating = true
                pulseAnimation = true
                warningFlash = true
            }

            // 延迟显示跳过按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showSkipButton = true
            }
        }
        .onReceive(timer) { _ in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.upstream.connect().cancel()
                onSkip()
            }
        }
    }
}

#Preview {
    LaunchScreenView(onSkip: {})
}