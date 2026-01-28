//
//  WaveformView.swift
//  MorseModem
//

import SwiftUI

struct WaveformView: View {
    let data: [Float]

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let stepWidth = width / CGFloat(data.count)

            var path = Path()

            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * stepWidth
                let normalizedValue = CGFloat(min(value * 5, 1.0))
                let y = height / 2 - (normalizedValue * height / 2)
                let barHeight = normalizedValue * height

                path.addRect(CGRect(x: x, y: y, width: stepWidth * 0.8, height: barHeight))
            }

            context.fill(path, with: .color(.accentColor))
        }
    }
}
