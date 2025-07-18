//
//  ComponentSelectorView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/15/25.
//

import SwiftUI

struct ComponentSelectorView: View {
    let title: String
    let iconName: String
    @Binding var isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.4), lineWidth: 1.5)
        )
        .onTapGesture {
            withAnimation(.snappy) {
                isSelected.toggle()
            }
        }
    }
}
