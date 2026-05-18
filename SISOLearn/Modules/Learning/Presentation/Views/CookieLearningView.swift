import SwiftUI

struct CookieLearningView: View {
    @Bindable var viewModel: LearningSessionViewModel
    @Environment(NetworkMonitor.self) private var networkMonitor

    var body: some View {
        VStack(spacing: 0) {
            CookieBubbleView(cookieVM: viewModel.cookieVM).padding(.top, 8)
            ScrollView {
                VStack(spacing: 16) {
                    switch viewModel.currentPhase {
                    case .explanation:
                        explanationCard
                        Button("문제 풀기 🐾") { viewModel.proceedToQuiz() }
                            .buttonStyle(.borderedProminent).tint(.orange).frame(minHeight: 44)
                    case .quiz, .answering, .hintRequested:
                        quizCard
                        answerInputCard
                    case .feedback:
                        if let feedback = viewModel.currentFeedback { feedbackCard(feedback) }
                    case .sessionComplete:
                        sessionCompleteCard
                    default:
                        if viewModel.isLoading { loadingCard }
                    }
                }
                .padding()
            }
            progressBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay { if viewModel.isLoading { loadingOverlay } }
        .onAppear { viewModel.startSession() }
    }

    private var explanationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("쿠키의 설명", systemImage: "book.fill").font(.headline).foregroundColor(.orange)
            Text(viewModel.explanation).font(.body)
        }
        .padding().background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }

    private var quizCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("문제 \(viewModel.currentQuizIndex + 1)/\(viewModel.quizzes.count)", systemImage: "questionmark.circle.fill")
                    .font(.headline).foregroundColor(.orange)
                Spacer()
            }
            Text(viewModel.currentQuiz?.question ?? "").font(.body)
        }
        .padding().background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }

    private var answerInputCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { Label("쿠키에게 답변하기", systemImage: "pencil").font(.headline).foregroundColor(.orange); Spacer(); SpeechButton(text: $viewModel.userAnswer) }
            TextEditor(text: $viewModel.userAnswer)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: viewModel.userAnswer) { _ in
                    if viewModel.currentPhase == .quiz { viewModel.currentPhase = .answering }
                }
            HStack {
                Text("\(viewModel.userAnswer.count)/\(GeminiAPILimits.answerMaxChars)자")
                    .font(.caption).foregroundColor(viewModel.isAnswerOverLimit ? .red : .secondary)
                Spacer()
                Button("💡 힌트 (\(GeminiAPILimits.maxHintLevel - viewModel.hintCount)회 남음)") {
                    viewModel.requestHint()
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canRequestHint || viewModel.isLoading)
                .frame(minHeight: 44)
                Button("제출 →") { viewModel.submitAnswer() }
                    .buttonStyle(.borderedProminent).tint(.orange)
                    .disabled(viewModel.isAnswerEmpty || viewModel.isAnswerOverLimit || viewModel.isLoading)
                    .frame(minHeight: 44)
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }

    private func feedbackCard(_ feedback: AnswerFeedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: feedback.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(feedback.isCorrect ? .green : .red).font(.title2)
                Text(feedback.isCorrect ? "정답! 🎉" : "아쉽지만 괜찮아! 🥺")
                    .font(.headline)
                Spacer()
                Text("\(feedback.score)점").font(.title3).fontWeight(.bold).foregroundColor(.orange)
            }
            Text(feedback.explanation).font(.body)
            if !feedback.correctAnswer.isEmpty {
                Divider()
                Text("정답 설명: \(feedback.correctAnswer)").font(.body).foregroundColor(.secondary)
            }
            Button("다음 문제 →") { viewModel.proceedToNextQuiz() }
                .buttonStyle(.borderedProminent).tint(.orange).frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding().background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }

    private var sessionCompleteCard: some View {
        VStack(spacing: 16) {
            Text("🎉 학습 완료!").font(.largeTitle).fontWeight(.bold)
            Text("정답률: \(Int(viewModel.accuracyRate * 100))%")
                .font(.title).foregroundColor(.orange)
            Text("\(viewModel.sessionResults.filter { $0.isCorrect }.count) / \(viewModel.sessionResults.count) 문제 정답")
                .font(.body).foregroundColor(.secondary)
        }
        .padding().background(Color(.systemBackground)).cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 4)
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: viewModel.progress)
                .tint(.orange).padding(.horizontal)
            Text("진행: \(viewModel.currentQuizIndex)/\(viewModel.quizzes.count)")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var loadingCard: some View {
        HStack { ProgressView(); Text("쿠키가 생각하는 중... 🤔").font(.body) }
            .padding().background(Color(.systemBackground)).cornerRadius(16)
    }

    private var loadingOverlay: some View {
        Color.black.opacity(0.2).ignoresSafeArea()
            .overlay(ProgressView().scaleEffect(1.5).tint(.orange))
    }
}
