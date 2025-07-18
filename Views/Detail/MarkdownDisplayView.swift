import SwiftUI
import Markdown

struct MarkdownDisplayView: View {
    let text: String

    var body: some View {
        ScrollView {
            Markdown(content: .constant(text))
                .font(.body)
                .padding()
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
    }
} 
