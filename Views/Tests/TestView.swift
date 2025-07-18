//
//  TestView.swift
//  GameLogger
//
//  Created by Justin Gain on 7/17/25.
//
import SwiftUI
     import Markdown

     struct TestView: View {
         var body: some View {
             Markdown(content: .constant("## Heading\n* Bullet 1\n* Bullet 2"))
                 .font(.body)
                 .padding()
         }
     }
