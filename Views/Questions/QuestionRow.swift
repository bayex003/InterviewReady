import SwiftUI

struct QuestionRow: View {
    let question: Question
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 1. Status Icon
            Image(systemName: question.isAnswered ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(question.isAnswered ? SwiftUI.Color.sage500 : SwiftUI.Color.ink400)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                // 2. Question Text
                Text(question.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(SwiftUI.Color.ink900)
                    .lineLimit(2)
                
                // 3. Metadata (Category + Answer preview)
                HStack {
                    Text(question.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SwiftUI.Color.ink900.opacity(0.05))
                        .cornerRadius(6)
                        .foregroundColor(SwiftUI.Color.ink600)
                    
                    if question.isAnswered {
                        Text("• Answered")
                            .font(.caption)
                            .foregroundColor(SwiftUI.Color.sage500)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
