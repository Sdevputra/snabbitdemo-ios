import SwiftUI

struct QuestionnaireView: View {
    @State var viewModel: OnboardingQuestionnaireViewModel

    // 2-column grid for tasks
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        // @Bindable derives two-way bindings from an @Observable stored in @State
        @Bindable var vm = viewModel

        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Progress bar
                    AppProgressBar(progress: 0.33)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.sm)

                    // Header
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Skills")
                            .font(AppFont.bold(22))
                            .foregroundColor(.appTextPrimary)
                        Text("Tell us a bit more about yourself")
                            .font(AppFont.regular(14))
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.lg)

                    // Question 1: Tasks
                    tasksSection
                        .padding(.top, AppSpacing.lg)

                    Divider()
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.md)

                    // Question 2: Smartphone
                    smartphoneSection

                    // Conditional: Can get phone
                    if viewModel.showCanGetPhone {
                        Divider()
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.md)
                        canGetPhoneSection
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Divider()
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.md)

                    // Question 3: Google Maps
                    googleMapsSection

                    Divider()
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.md)

                    // Question 4: Date of Birth
                    dobSection(vm: $vm)

                    Color.clear.frame(height: 100)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.showCanGetPhone)

            // Sticky Continue Button
            continueButton

            // Error Banner
            if let error = viewModel.errorMessage {
                VStack {
                    ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                        .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }

    // MARK: - Tasks Section
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("How many of these tasks have you done before?")
                    .font(AppFont.semibold(15))
                    .foregroundColor(.appTextPrimary)
                Text("(select all that apply)")
                    .font(AppFont.regular(13))
                    .foregroundColor(.appTextSecondary)
            }
            .padding(.horizontal, AppSpacing.md)

            LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.md) {
                ForEach(viewModel.allTasks) { task in
                    AppCheckbox(
                        title: task.rawValue,
                        isSelected: viewModel.selectedTasks.contains(task.rawValue)
                    ) {
                        viewModel.toggleTask(task.rawValue)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Smartphone Section
    private var smartphoneSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Do you have your own smartphone?")
                .font(AppFont.semibold(15))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, AppSpacing.md)

            HStack(spacing: AppSpacing.xl) {
                AppRadioButton(title: "Yes", isSelected: viewModel.hasSmartphone == true) {
                    viewModel.setSmartphone(true)
                }
                AppRadioButton(title: "No", isSelected: viewModel.hasSmartphone == false) {
                    viewModel.setSmartphone(false)
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Can Get Phone Section
    private var canGetPhoneSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Will you be able to get a phone for the job?")
                .font(AppFont.semibold(15))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, AppSpacing.md)

            HStack(spacing: AppSpacing.xl) {
                AppRadioButton(title: "Yes", isSelected: viewModel.canGetPhone == true) {
                    viewModel.canGetPhone = true
                }
                AppRadioButton(title: "No", isSelected: viewModel.canGetPhone == false) {
                    viewModel.canGetPhone = false
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Google Maps Section
    private var googleMapsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Have you ever used google maps?")
                .font(AppFont.semibold(15))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, AppSpacing.md)

            HStack(spacing: AppSpacing.xl) {
                AppRadioButton(title: "Yes", isSelected: viewModel.hasUsedGoogleMaps == true) {
                    viewModel.hasUsedGoogleMaps = true
                }
                AppRadioButton(title: "No", isSelected: viewModel.hasUsedGoogleMaps == false) {
                    viewModel.hasUsedGoogleMaps = false
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Date of Birth Section
    // Receives @Bindable so DOBField can bind to vm properties directly
    private func dobSection(vm: Bindable<OnboardingQuestionnaireViewModel>) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Date of birth")
                .font(AppFont.semibold(15))
                .foregroundColor(.appTextPrimary)
                .padding(.horizontal, AppSpacing.md)

            HStack(spacing: AppSpacing.sm) {
                DOBField(placeholder: "DD", text: vm.dobDay, maxLength: 2)
                DOBField(placeholder: "MM", text: vm.dobMonth, maxLength: 2)
                DOBField(placeholder: "YYYY", text: vm.dobYear, maxLength: 4)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    // MARK: - Continue Button
    private var continueButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: viewModel.submit) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canContinue))
            .disabled(!viewModel.canContinue)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.md)
            .background(Color.appBackground)
        }
    }
}

// MARK: - DOB Field
struct DOBField: View {
    let placeholder: String
    @Binding var text: String
    let maxLength: Int

    var body: some View {
        TextField(placeholder, text: $text)
            .font(AppFont.regular(16))
            .foregroundColor(.appTextPrimary)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .frame(width: placeholder == "YYYY" ? 70 : 52, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .onChange(of: text) { _, newValue in
                let filtered = String(newValue.filter { $0.isNumber }.prefix(maxLength))
                if filtered != newValue { text = filtered }
            }
    }
}

// MARK: - Preview
#Preview {
    QuestionnaireCoordinatorView()
        .environment(AppCoordinator())
}
