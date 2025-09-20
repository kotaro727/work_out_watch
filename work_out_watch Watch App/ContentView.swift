//
//  ContentView.swift
//  work_out_watch Watch App
//
//  Created by 鈴木光太郎 on 2025/09/06.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: "bolt.heart")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accentGradient)
                    .shadow(color: Theme.accent.opacity(0.45), radius: 12, y: 6)
                Text("Ready to Train")
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
                Text("ダーク&オレンジ基調")
                    .font(.footnote)
                    .foregroundColor(Theme.textSecondary)
            }
            .padding()
            .background(Theme.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.border)
            )
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
