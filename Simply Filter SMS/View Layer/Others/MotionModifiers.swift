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

    func shake(trigger: Int) -> some View {
        return self.modifier(ShakeModifier(trigger: trigger))
    }

    func bounceOnAppear(isShown: Bool, delay: Double, bouncesOnTap: Bool = false) -> some View {
        return self.modifier(BounceOnAppearModifier(isShown: isShown, delay: delay, bouncesOnTap: bouncesOnTap))
    }

    func motionAnimation<Value: Equatable>(_ animation: Animation?, value: Value) -> some View {
        return self.modifier(MotionAnimationModifier(animation: animation, value: value))
    }

    func motionTransaction() -> some View {
        return self.modifier(MotionTransactionModifier())
    }
}
