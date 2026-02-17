//
//  ConfettiView.swift
//  Simply Filter SMS
//

import SwiftUI
import UIKit

struct ConfettiView: UIViewRepresentable {
    let birthRate: Float
    let lifetime: Float
    let velocity: CGFloat

    func makeUIView(context: Context) -> ConfettiUIView {
        ConfettiUIView(birthRate: birthRate, lifetime: lifetime, velocity: velocity)
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {}
}

final class ConfettiUIView: UIView {
    private let emitter = CAEmitterLayer()
    private let birthRate: Float
    private let lifetime: Float
    private let velocity: CGFloat

    private let colors: [UIColor] = [
        .systemRed, .systemOrange, .systemYellow,
        .systemGreen, .systemBlue, .systemPurple, .systemPink
    ]

    init(birthRate: Float, lifetime: Float, velocity: CGFloat) {
        self.birthRate = birthRate
        self.lifetime = lifetime
        self.velocity = velocity
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard emitter.superlayer == nil else { return }
        setupEmitter()
    }

    private func setupEmitter() {
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
        emitter.emitterCells = colors.map { makeCell(color: $0) }
        layer.addSublayer(emitter)

        let stopDelay = Double(lifetime) + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + stopDelay) { [weak self] in
            self?.emitter.birthRate = 0
        }
    }

    private func makeCell(color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = birthRate / Float(colors.count)
        cell.lifetime = lifetime
        cell.velocity = velocity
        cell.velocityRange = velocity * 0.3
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 4
        cell.spin = 3.5
        cell.spinRange = 1.0
        cell.scale = 0.08
        cell.scaleRange = 0.04
        cell.alphaSpeed = -1.0 / lifetime

        let size = CGSize(width: 10, height: 6)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 2).fill()
        cell.contents = UIGraphicsGetImageFromCurrentImageContext()?.cgImage
        UIGraphicsEndImageContext()

        return cell
    }
}
