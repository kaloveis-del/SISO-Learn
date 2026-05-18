import SwiftUI

struct SettingsView: View {

    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    apiKeyInputSection
                } header: {
                    Text("Gemini API Key")
                } footer: {
                    Text("Google AI Studio(aistudio.google.com)에서 무료로 발급받을 수 있어요.")
                        .font(.caption)
                }

                if viewModel.hasStoredAPIKey {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API 키가 저장되어 있어요")
                            Spacer()
                            Button("삭제", role: .destructive) {
                                viewModel.deleteAPIKey()
                            }
                        }
                    }
                }

                Section("앱 정보") {
                    LabeledContent("버전", value: "1.0.0")
                    LabeledContent("AI 모델", value: "Gemini 2.0 Flash")
                }
            }
            .navigationTitle("설정")
            .onAppear { viewModel.onAppear() }
            .alert("알림", isPresented: $viewModel.showAlert) {
                Button("확인") {}
            } message: {
                Text(viewModel.alertMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var apiKeyInputSection: some View {
        HStack {
            Group {
                if viewModel.isAPIKeyVisible {
                    TextField("AIza...", text: $viewModel.apiKeyInput)
                } else {
                    SecureField("AIza...", text: $viewModel.apiKeyInput)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .onChange(of: viewModel.apiKeyInput) { _ in
                viewModel.validateFormat()
            }
            Button {
                viewModel.isAPIKeyVisible.toggle()
            } label: {
                Image(systemName: viewModel.isAPIKeyVisible ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
            }
        }

        if !viewModel.apiKeyInput.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isAPIKeyValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(viewModel.isAPIKeyValid ? .green : .red)
                Text(viewModel.isAPIKeyValid ? "올바른 형식이에요" : "'AIza'로 시작하는 39자여야 해요")
                    .font(.caption)
                    .foregroundColor(viewModel.isAPIKeyValid ? .green : .red)
            }
        }

        Button {
            viewModel.saveAPIKey()
        } label: {
            HStack {
                if viewModel.isSaving { ProgressView().scaleEffect(0.8) }
                Text("저장하기")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isAPIKeyValid || viewModel.isSaving)
        .frame(minHeight: 44)
    }
}
