import SwiftUI

// MARK: - App Text Field
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .font(AppFont.regular(16))
        .foregroundColor(.appTextPrimary)
        .padding(.horizontal, AppSpacing.md)
        .frame(height: 52)
        .background(Color.appSurface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .cornerRadius(AppRadius.sm)
    }
}

// MARK: - Checkbox
struct AppCheckbox: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.appPrimary : Color.appBorder, lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isSelected ? Color.appPrimary : Color.clear)
                        )
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Text(title)
                    .font(AppFont.regular(14))
                    .foregroundColor(.appTextPrimary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Radio Button
struct AppRadioButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.appPrimary : Color.appBorder, lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Text(title)
                    .font(AppFont.regular(15))
                    .foregroundColor(.appTextPrimary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Progress Bar
struct AppProgressBar: View {
    let progress: Double // 0 to 1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appBorder)
                    .frame(height: 4)
                Capsule()
                    .fill(Color.appPrimary)
                    .frame(width: geo.size.width * CGFloat(progress), height: 4)
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.white)
            Text(message)
                .font(AppFont.medium(14))
                .foregroundColor(.white)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appRed)
        .cornerRadius(AppRadius.sm)
        .padding(.horizontal, AppSpacing.md)
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding(AppSpacing.xl)
                .background(Color.appPrimary.opacity(0.8))
                .cornerRadius(AppRadius.md)
        }
    }
}
