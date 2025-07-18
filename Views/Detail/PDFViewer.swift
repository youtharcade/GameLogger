//
//  PDFViewer.swift
//  GameLogger
//
//  Created by Justin Gain on 7/11/25.
//
import SwiftUI
import PDFKit

struct PDFViewer: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No update needed
    }
}

