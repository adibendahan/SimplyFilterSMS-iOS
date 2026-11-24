//
//  MotionModifiers.swift
//  Simply Filter SMS
//

import SwiftUI


//MARK: - Timing -
enum Stagger {
    static func delay(for index: Int, step: Double, base: Double = 0, limit: Int = .max) -> Double {
        let staggerIndex = min(index, limit)
        return base + step * Double(staggerIndex)
    }
}

enum ReducedMotion {
    static let fade = Animation.easeOut(duration: 0.3)

    static var isEnabled: Bool {
        return UIAccessibility.isReduceMotionEnabled
    }
}

func withMotionAnimation<Result>(_ animation: Animation?, _ body: () throws -> Result) rethrows -> Result {
    let resolvedAnimation: Animation?
    if ReducedMotion.isEnabled {
        resolvedAnimation = nil
    } else {
        resolvedAnimation = animation
    }
    return try withAnimation(resolvedAnimation, body)
}


//MARK: - Entrance -
private struct EntranceModifier: ViewModifier {
    let isShown: Bool
    let delay: Double
    let rise: CGFloat
    let scale: CGFloat
    let blur: CGFloat
    let animation: Animation

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        let isAtRest = self.isShown || self.reduceMotion
        content
            .opacity(self.isShown ? 1 : 0)
            .scaleEffect(isAtRest ? 1 : self.scale)
            .offset(y: isAtRest ? 0 : self.rise)
            .blur(radius: isAtRest ? 0 : self.blur)
            .animation(self.resolvedAnimation, value: self.isShown)
    }

    private var resolvedAnimation: Animation {
        let result: Animation
        if self.reduceMotion {
            result = ReducedMotion.fade
        } else {
            result = self.animation.delay(self.delay)
        }
        return result
    }
}

private struct EntranceOnAppearModifier: ViewModifier {
    let delay: Double
    let rise: CGFloat
    let scale: CGFloat
    let blur: CGFloat
    let animation: Animation

    @State private var isShown = false

    func body(content: Content) -> some View {
        content
            .entrance(isShown: self.isShown, delay: self.delay, rise: self.rise, scale: self.scale, blur: self.blur, animation: self.animation)
            .onAppear {
                self.isShown = true
            }
    }
}


//MARK: - Scroll -
private struct ScrollFocusModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        let reduceMotion = self.reduceMotion
        content
            .scrollTransition(.animated(.smooth)) { view, phase in
                let isAtRest = phase.isIdentity || reduceMotion
                return view
                    .opacity(phase.isIdentity ? 1 : 0.35)
                    .scaleEffect(isAtRest ? 1 : 0.94)
                    .blur(radius: isAtRest ? 0 : 1.5)
            }
    }
}

private struct ScrollProgressModifier: ViewModifier {
    let distance: CGFloat
    @Binding var progress: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, offset in
                    self.progress = min(max(offset / self.distance, 0), 1)
                }
        } else {
            content
        }
    }
}

private struct ScrollCollapseModifier: ViewModifier {
    let progress: CGFloat

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        if self.reduceMotion {
            content
                .opacity(1 - self.progress)
        } else {
            content
                .scaleEffect(1 - 0.45 * self.progress)
                .opacity(1 - self.progress)
                .blur(radius: 8 * self.progress)
        }
    }
}


//MARK: - Feedback -
private struct ShakeModifier: ViewModifier {
    let trigger: Int

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: CGFloat.zero, trigger: self.reduceMotion ? 0 : self.trigger) { view, offset in
                view.offset(x: offset)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(-10, duration: 0.05)
                    LinearKeyframe(10, duration: 0.08)
                    LinearKeyframe(-7, duration: 0.08)
                    LinearKeyframe(7, duration: 0.08)
                    LinearKeyframe(-3, duration: 0.07)
                    LinearKeyframe(0, duration: 0.06)
                }
            }
    }
}

private enum RippleMotion {
    static let endScale: CGFloat = 1.45
    static let startOpacity: Double = 0.5
    static let duration: Double = 0.6
    static let lifetime: Double = 0.7
}

private struct StrokeRipple: View {
    let systemName: String
    let color: Color
    let reduceMotion: Bool

    @State private var isExpanded = false

    var body: some View {
        Image(systemName: self.systemName)
            .resizable()
            .scaledToFit()
            .fontWeight(.ultraLight)
            .foregroundStyle(self.color)
            .scaleEffect(self.isExpanded && !self.reduceMotion ? RippleMotion.endScale : 1)
            .opacity(self.isExpanded ? 0 : RippleMotion.startOpacity)
            .onAppear {
                withAnimation(.easeOut(duration: RippleMotion.duration)) {
                    self.isExpanded = true
                }
            }
    }
}

private struct StrokeRippleOnTapModifier: ViewModifier {
    let systemName: String
    let color: Color

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var ripples: [UUID] = []
    @State private var tapCount = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    ForEach(self.ripples, id: \.self) { _ in
                        StrokeRipple(systemName: self.systemName, color: self.color, reduceMotion: self.reduceMotion)
                    }
                }
                .allowsHitTesting(false)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: self.tapCount)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                self.addRipple()
            })
    }

    private func addRipple() {
        let ripple = UUID()
        self.tapCount += 1
        self.ripples.append(ripple)
        DispatchQueue.main.asyncAfter(deadline: .now() + RippleMotion.lifetime) {
            self.ripples.removeAll { $0 == ripple }
        }
    }
}

private struct BounceOnAppearModifier: ViewModifier {
    let isShown: Bool
    let delay: Double
    let bouncesOnTap: Bool

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var bounceTrigger = 0

    func body(content: Content) -> some View {
        content
            .symbolEffect(.bounce, value: self.bounceTrigger)
            .onChange(of: self.isShown) { _, isShown in
                guard isShown, !self.reduceMotion else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
                    self.bounceTrigger += 1
                }
            }
            .onTapGesture {
                guard self.bouncesOnTap, !self.reduceMotion else { return }
                self.bounceTrigger += 1
            }
    }
}

private enum RevealHighlightMotion {
    static let hold: TimeInterval = 0.6
    static let fade: TimeInterval = 0.8
    static let rowBleed: CGFloat = -40
}

private struct RevealHighlightModifier: ViewModifier {
    let isRevealed: Bool

    @State private var trigger = 0

    func body(content: Content) -> some View {
        content
            .background {
                Color(UIColor.systemGray4)
                    .padding(RevealHighlightMotion.rowBleed)
                    .keyframeAnimator(initialValue: Double.zero, trigger: self.trigger) { view, opacity in
                        view.opacity(opacity)
                    } keyframes: { _ in
                        KeyframeTrack {
                            MoveKeyframe(1)
                            LinearKeyframe(1, duration: RevealHighlightMotion.hold)
                            CubicKeyframe(0, duration: RevealHighlightMotion.fade)
                        }
                    }
                    .allowsHitTesting(false)
            }
            .onAppear {
                guard self.isRevealed else { return }
                self.trigger += 1
            }
            .onChange(of: self.isRevealed) { _, isRevealed in
                guard isRevealed else { return }
                self.trigger += 1
            }
    }
}


private struct BreatheModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *), !self.reduceMotion {
            content
                .symbolEffect(.breathe)
        } else {
            content
        }
    }
}

private enum PulseRingMotion {
    static let ringCount = 2
    static let period: Double = 2.4
    static let endScale: CGFloat = 1.3
    static let startOpacity: Double = 0.7
    static let room: CGFloat = 6

    static func delay(for index: Int) -> Double {
        return Stagger.delay(for: index, step: PulseRingMotion.period / Double(PulseRingMotion.ringCount))
    }
}

private struct PulseRing: View {
    let color: Color
    let delay: Double

    @State private var isExpanded = false

    var body: some View {
        Image(systemName: "circle")
            .fontWeight(.light)
            .foregroundStyle(self.color)
            .scaleEffect(self.isExpanded ? PulseRingMotion.endScale : 1)
            .opacity(self.isExpanded ? 0 : PulseRingMotion.startOpacity)
            .onAppear {
                let animation = Animation.easeOut(duration: PulseRingMotion.period)
                    .repeatForever(autoreverses: false)
                    .delay(self.delay)
                withAnimation(animation) {
                    self.isExpanded = true
                }
            }
    }
}

private struct PulseBreatheModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .symbolEffect(.breathe.plain.byLayer, isActive: self.isActive)
        } else {
            content
        }
    }
}

private struct PulseRingsModifier: ViewModifier {
    let isActive: Bool
    let color: Color

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        content
            .modifier(PulseBreatheModifier(isActive: self.isShowingRings))
            .background {
                if self.isShowingRings {
                    ZStack {
                        ForEach(0..<PulseRingMotion.ringCount, id: \.self) { index in
                            PulseRing(color: self.color, delay: PulseRingMotion.delay(for: index))
                        }
                    }
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }
            }
            .padding(PulseRingMotion.room)
    }

    private var isShowingRings: Bool {
        return self.isActive && !self.reduceMotion && !ProcessInfo.processInfo.isInTestingMode
    }
}


//MARK: - Loading -
private enum SpinnerSwapMotion {
    static let contentScale: CGFloat = 0.8
    static let contentBlur: CGFloat = 4
    static let spinnerStartScale: CGFloat = 0.4
    static let animation = Animation.spring(response: 0.35, dampingFraction: 0.75)
}

private struct SpinnerSwapModifier: ViewModifier {
    let isActive: Bool
    let tint: Color

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        let isMoving = self.isActive && !self.reduceMotion
        content
            .opacity(self.isActive ? 0 : 1)
            .scaleEffect(isMoving ? SpinnerSwapMotion.contentScale : 1)
            .blur(radius: isMoving ? SpinnerSwapMotion.contentBlur : 0)
            .overlay {
                if self.isActive {
                    ProgressView()
                        .controlSize(.regular)
                        .tint(self.tint)
                        .transition(.motion(.scale(scale: SpinnerSwapMotion.spinnerStartScale).combined(with: .opacity)))
                }
            }
            .animation(self.reduceMotion ? ReducedMotion.fade : SpinnerSwapMotion.animation, value: self.isActive)
    }
}

private enum CollapseToCircleMotion {
    static let animation = Animation.spring(response: 0.5, dampingFraction: 0.85)
}

private struct CollapseToCircleModifier: ViewModifier {
    let diameter: CGFloat

    @State private var isCollapsed = ReducedMotion.isEnabled

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: self.isCollapsed ? self.diameter : .infinity)
            .onAppear {
                guard !self.isCollapsed else { return }
                DispatchQueue.main.async {
                    withAnimation(CollapseToCircleMotion.animation) {
                        self.isCollapsed = true
                    }
                }
            }
    }
}


//MARK: - Celebration -
private enum CelebrateMotion {
    static let sparkCount = 8
    static let sparkSize: CGFloat = 6
    static let sparkTravel: CGFloat = 26
    static let burstDuration: Double = 0.6
    static let thumpScale: CGFloat = 1.18
    static let thumpRise: Double = 0.14
    static let thumpSettle: Double = 0.36

    static func angle(for index: Int) -> Angle {
        return .degrees(360 / Double(CelebrateMotion.sparkCount) * Double(index))
    }
}

private struct SparkBurst: View {
    let color: Color
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let radius = min(proxy.size.width, proxy.size.height) / 2
            ZStack {
                ForEach(0..<CelebrateMotion.sparkCount, id: \.self) { index in
                    Circle()
                        .fill(self.color)
                        .frame(width: CelebrateMotion.sparkSize, height: CelebrateMotion.sparkSize)
                        .offset(y: -(radius + CelebrateMotion.sparkTravel * self.progress))
                        .rotationEffect(CelebrateMotion.angle(for: index))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .opacity(1 - self.progress)
        }
    }
}

private struct CelebrateModifier: ViewModifier {
    let isCelebrating: Bool
    let color: Color

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var trigger = 0

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: CGFloat(1), trigger: self.trigger) { view, scale in
                view.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(CelebrateMotion.thumpScale, duration: CelebrateMotion.thumpRise)
                    SpringKeyframe(1, duration: CelebrateMotion.thumpSettle, spring: .bouncy)
                }
            }
            .overlay {
                Color.clear
                    .keyframeAnimator(initialValue: CGFloat(1), trigger: self.trigger) { view, progress in
                        view.overlay {
                            SparkBurst(color: self.color, progress: progress)
                        }
                    } keyframes: { _ in
                        KeyframeTrack {
                            MoveKeyframe(0)
                            CubicKeyframe(1, duration: CelebrateMotion.burstDuration)
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .onChange(of: self.isCelebrating) { _, isCelebrating in
                guard isCelebrating, !self.reduceMotion else { return }
                self.trigger += 1
            }
    }
}


//MARK: - Write On -
private struct WriteOnModifier: ViewModifier {
    let isShown: Bool
    let delay: Double
    let duration: Double

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        if self.reduceMotion {
            content
                .opacity(self.isShown ? 1 : 0)
                .animation(ReducedMotion.fade.delay(self.delay), value: self.isShown)
        } else {
            content
                .mask(alignment: .leading) {
                    GeometryReader { proxy in
                        Rectangle()
                            .frame(width: self.isShown ? proxy.size.width : 0)
                    }
                }
                .animation(.easeInOut(duration: self.duration).delay(self.delay), value: self.isShown)
        }
    }
}


//MARK: - Value Changes -
struct AnimatedValue<Value: Equatable, Content: View>: View {
    let value: Value
    let animation: (Value, Value) -> Animation
    let content: (Value) -> Content

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var shownValue: Value

    init(_ value: Value, animation: @escaping (Value, Value) -> Animation, @ViewBuilder content: @escaping (Value) -> Content) {
        self.value = value
        self.animation = animation
        self.content = content
        _shownValue = State(initialValue: value)
    }

    var body: some View {
        self.content(self.shownValue)
            .onChange(of: self.value) { oldValue, newValue in
                let resolvedAnimation = self.reduceMotion ? ReducedMotion.fade : self.animation(oldValue, newValue)
                withAnimation(resolvedAnimation) {
                    self.shownValue = newValue
                }
            }
    }
}

struct FadeSwapTiming {
    let fadeOut: Animation
    let fadeIn: Animation
    let update: Animation
}

struct FadeSwap<Value: Equatable, Content: View>: View {
    let value: Value
    let isSwap: (Value, Value) -> Bool
    let timing: (Value, Value) -> FadeSwapTiming
    let content: (Value) -> Content

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var shownValue: Value
    @State private var opacity: Double = 1

    init(_ value: Value, isSwap: @escaping (Value, Value) -> Bool, timing: @escaping (Value, Value) -> FadeSwapTiming, @ViewBuilder content: @escaping (Value) -> Content) {
        self.value = value
        self.isSwap = isSwap
        self.timing = timing
        self.content = content
        _shownValue = State(initialValue: value)
    }

    var body: some View {
        self.content(self.shownValue)
            .opacity(self.opacity)
            .onChange(of: self.value) { oldValue, newValue in
                self.valueChanged(from: oldValue, to: newValue)
            }
    }

    private func valueChanged(from oldValue: Value, to newValue: Value) {
        let timing = self.resolvedTiming(from: oldValue, to: newValue)
        if self.isSwap(oldValue, newValue) {
            self.swap(to: newValue, timing: timing)
        }
        else {
            withAnimation(timing.update) {
                self.shownValue = newValue
            }
        }
    }

    private func swap(to newValue: Value, timing: FadeSwapTiming) {
        withAnimation(timing.fadeOut) {
            self.opacity = 0
        } completion: {
            var swapTransaction = Transaction()
            swapTransaction.disablesAnimations = true
            withTransaction(swapTransaction) {
                self.shownValue = newValue
            }
            withAnimation(timing.fadeIn) {
                self.opacity = 1
            }
        }
    }

    private func resolvedTiming(from oldValue: Value, to newValue: Value) -> FadeSwapTiming {
        let result: FadeSwapTiming
        if self.reduceMotion {
            result = FadeSwapTiming(fadeOut: ReducedMotion.fade, fadeIn: ReducedMotion.fade, update: ReducedMotion.fade)
        } else {
            result = self.timing(oldValue, newValue)
        }
        return result
    }
}


//MARK: - Reduce Motion -
private struct MotionAnimationModifier<Value: Equatable>: ViewModifier {
    let animation: Animation?
    let value: Value

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        content
            .animation(self.reduceMotion ? nil : self.animation, value: self.value)
    }
}

private struct MotionOrFadeAnimationModifier<Value: Equatable>: ViewModifier {
    let animation: Animation
    let value: Value

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        content
            .animation(self.reduceMotion ? ReducedMotion.fade : self.animation, value: self.value)
    }
}

private struct MotionTransactionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    func body(content: Content) -> some View {
        let reduceMotion = self.reduceMotion
        content
            .transaction { transaction in
                if reduceMotion {
                    transaction.animation = nil
                }
            }
    }
}

extension AnyTransition {
    static func motion(_ transition: AnyTransition) -> AnyTransition {
        let result: AnyTransition
        if ReducedMotion.isEnabled {
            result = .opacity
        } else {
            result = transition
        }
        return result
    }
}


//MARK: - View Extensions -
extension View {
    func entrance(isShown: Bool, delay: Double = 0, rise: CGFloat = 12, scale: CGFloat = 1, blur: CGFloat = 0, animation: Animation = .spring(response: 0.55, dampingFraction: 0.62)) -> some View {
        return self.modifier(EntranceModifier(isShown: isShown, delay: delay, rise: rise, scale: scale, blur: blur, animation: animation))
    }

    func entranceOnAppear(delay: Double = 0, rise: CGFloat = 12, scale: CGFloat = 1, blur: CGFloat = 0, animation: Animation = .spring(response: 0.55, dampingFraction: 0.62)) -> some View {
        return self.modifier(EntranceOnAppearModifier(delay: delay, rise: rise, scale: scale, blur: blur, animation: animation))
    }

    func scrollFocus() -> some View {
        return self.modifier(ScrollFocusModifier())
    }

    func onScrollProgress(distance: CGFloat, progress: Binding<CGFloat>) -> some View {
        return self.modifier(ScrollProgressModifier(distance: distance, progress: progress))
    }

    func scrollCollapse(progress: CGFloat) -> some View {
        return self.modifier(ScrollCollapseModifier(progress: progress))
    }

    func shake(trigger: Int) -> some View {
        return self.modifier(ShakeModifier(trigger: trigger))
    }

    func strokeRippleOnTap(systemName: String, color: Color) -> some View {
        return self.modifier(StrokeRippleOnTapModifier(systemName: systemName, color: color))
    }

    func bounceOnAppear(isShown: Bool, delay: Double, bouncesOnTap: Bool = false) -> some View {
        return self.modifier(BounceOnAppearModifier(isShown: isShown, delay: delay, bouncesOnTap: bouncesOnTap))
    }

    func revealHighlight(isRevealed: Bool) -> some View {
        return self.modifier(RevealHighlightModifier(isRevealed: isRevealed))
    }

    func breathe() -> some View {
        return self.modifier(BreatheModifier())
    }

    func pulseRings(isActive: Bool, color: Color) -> some View {
        return self.modifier(PulseRingsModifier(isActive: isActive, color: color))
    }

    func spinnerSwap(isActive: Bool, tint: Color) -> some View {
        return self.modifier(SpinnerSwapModifier(isActive: isActive, tint: tint))
    }

    func collapseToCircle(diameter: CGFloat) -> some View {
        return self.modifier(CollapseToCircleModifier(diameter: diameter))
    }

    func celebrate(isCelebrating: Bool, color: Color) -> some View {
        return self.modifier(CelebrateModifier(isCelebrating: isCelebrating, color: color))
    }

    func writeOn(isShown: Bool, delay: Double = 0, duration: Double = 0.7) -> some View {
        return self.modifier(WriteOnModifier(isShown: isShown, delay: delay, duration: duration))
    }

    func motionAnimation<Value: Equatable>(_ animation: Animation?, value: Value) -> some View {
        return self.modifier(MotionAnimationModifier(animation: animation, value: value))
    }

    func motionOrFadeAnimation<Value: Equatable>(_ animation: Animation, value: Value) -> some View {
        return self.modifier(MotionOrFadeAnimationModifier(animation: animation, value: value))
    }

    func motionTransaction() -> some View {
        return self.modifier(MotionTransactionModifier())
    }
}
