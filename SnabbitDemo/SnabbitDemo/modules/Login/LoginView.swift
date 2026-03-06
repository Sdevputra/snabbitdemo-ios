import SwiftUI

struct LoginView: View {
    // @Observable ViewModels owned by a view use @State
    @State var viewModel: LoginViewModel
    @FocusState private var focusedField: LoginField?

    enum LoginField { case username, password, referral }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                // @Bindable lets us derive bindings from @Observable stored in @State
                @Bindable var vm = viewModel
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerSection

                    // Form Fields
                    VStack(spacing: AppSpacing.md) {
                        usernameField(vm: $vm)
                        passwordField(vm: $vm)
                        referralToggle

                        if viewModel.showReferralField {
                            referralField(vm: $vm)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.xl)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.showReferralField)

                    Spacer(minLength: AppSpacing.xxl)

                    // Footer
                    footerSection
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Error Banner
            if let error = viewModel.errorMessage {
                VStack {
                    ErrorBanner(message: error, onDismiss: viewModel.clearError)
                        .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: viewModel.errorMessage)
            }

            // Loading
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        Text("Login or Sign up to continue")
            .font(AppFont.bold(22))
            .foregroundColor(.appTextPrimary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.xxl)
    }

    // MARK: - Username
    private func usernameField(vm: Bindable<LoginViewModel>) -> some View {
        AppTextField(
            placeholder: "Enter your username",
            text: vm.username
        )
        .focused($focusedField, equals: .username)
        .submitLabel(.next)
        .onSubmit { focusedField = .password }
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }

    // MARK: - Password
    private func passwordField(vm: Bindable<LoginViewModel>) -> some View {
        AppTextField(
            placeholder: "Enter password",
            text: vm.password,
            isSecure: true
        )
        .focused($focusedField, equals: .password)
        .submitLabel(.done)
        .onSubmit { focusedField = nil }
    }

    // MARK: - Referral Toggle
    private var referralToggle: some View {
        Button(action: viewModel.toggleReferralCode) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(
                            viewModel.hasReferralCode ? Color.appPrimary : Color.appBorder,
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)
                    if viewModel.hasReferralCode {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Text("I have a referral code (optional)")
                    .font(AppFont.regular(15))
                    .foregroundColor(.appTextSecondary)
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Referral Field
    private func referralField(vm: Bindable<LoginViewModel>) -> some View {
        AppTextField(
            placeholder: "Enter referral code",
            text: vm.referralCode
        )
        .focused($focusedField, equals: .referral)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.characters)
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: AppSpacing.md) {
            termsText

            Button(action: viewModel.continueAction) {
                Text("Continue")
            }
            .buttonStyle(PrimaryButtonStyle(isEnabled: viewModel.canContinue))
            .disabled(!viewModel.canContinue)
            .padding(.horizontal, AppSpacing.md)

            Color.clear.frame(height: AppSpacing.md)
        }
    }

    private var termsText: some View {
        HStack(spacing: 4) {
            Text("By clicking, I accept the ")
                .font(AppFont.regular(13))
                .foregroundColor(.appTextSecondary)
            Button("Terms of Use") {}
                .font(AppFont.regular(13))
                .foregroundColor(.appPrimary)
                .underline()
            Text("& ")
                .font(AppFont.regular(13))
                .foregroundColor(.appTextSecondary)
            Button("Privacy Policy") {}
                .font(AppFont.regular(13))
                .foregroundColor(.appPrimary)
                .underline()
        }
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Preview
#Preview {
    LoginCoordinatorView()
        .environment(AppCoordinator())
}
