import SwiftUI
import SwiftData

struct QuestionDetailView: View {
    @Bindable var question: Question
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // 1. Question Header Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundStyle(Color.sage500)
                        Text(question.category.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.sage500)
                        Spacer()
                    }
                    
                    Text(question.text)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.ink900)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .background(Color.surfaceWhite)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                
                // 2. The Answer Input Section (Expanded)
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR ANSWER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.ink600)
                        .padding(.leading, 4)
                    
                    ZStack(alignment: .bottomTrailing) {
                        // The Text Editor Container
                        ZStack(alignment: .topLeading) {
                            // Placeholder Text
                            if question.answerText.isEmpty {
                                Text("Tap here to type your full answer, or use the microphone button to dictate...")
                                    .font(.body)
                                    .foregroundStyle(Color.ink400)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .allowsHitTesting(false)
                            }
                            
                            // The Actual Input Field
                            TextEditor(text: $question.answerText)
                                .font(.body)
                                .foregroundStyle(Color.ink900)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                // CHANGE: Increased from 200 to 400 for a spacious writing experience
                                .frame(minHeight: 400)
                        }
                        .background(Color.surfaceWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.ink200, lineWidth: 1)
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color.cream50)
        .tapToDismissKeyboard()
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if !question.answerText.isEmpty {
                question.dateAnswered = Date()
                question.isAnswered = true
            } else {
                question.isAnswered = false
            }
        }
    }
}
