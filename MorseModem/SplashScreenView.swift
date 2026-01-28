//
//  SplashScreenView.swift
//  MorseModem
//

import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        GeometryReader { geometry in
            Image("splash-screen")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
