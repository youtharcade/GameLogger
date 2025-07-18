//
//  SummaryBoxView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/12/25.
//
import SwiftUI

struct SummaryBoxView: View {
    let title: String
    let count: Int
    let iconName: String
    let iconColor: Color
    let backgroundColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(iconColor.gradient)
                    .clipShape(Circle())
                Spacer()
                Text("\(count)")
                    .font(.title.bold())
            }
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
        }
        .foregroundStyle(.white)
        .padding(12)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
