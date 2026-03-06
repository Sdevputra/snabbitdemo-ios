import SwiftUI

struct BreakView: View {
    @State var viewModel: BreakViewModel

    var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(
                colors: [.breakGradientTop, .breakGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)

                headerSection
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)

                Spacer()

                // Switch on BreakState — each case renders its own card
                contentCard
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                    .animation(.easeInOut(duration: 0.35), value: viewModel.breakState)

                Spacer()
            }

            // Confirmation bottom sheet (only when active)
            if viewModel.showEndBreakConfirmation {
                endBreakConfirmation
            }

            // Floating error banner
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    ErrorBanner(message: error, onDismiss: { viewModel.errorMessage = nil })
                        .padding(.bottom, AppSpacing.lg)
                }
            }
        }
        .onAppear { viewModel.loadBreakSchedules() }
    }

    // MARK: - Content card — driven entirely by BreakState

    @ViewBuilder
    private var contentCard: some View {
        switch viewModel.breakState {
        case .loading:
            loadingCard

        case .idle:
            //idleCard
            breakEndedCard

        case .upcoming(let startsIn):
            breakEndedCard
            //upcomingCard(startsAt: startsIn)

        case .active:
            activeBreakCard

        case .ended:
            breakEndedCard
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { viewModel.logout() }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            Spacer()
            Button(action: {}) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "phone.fill").font(.system(size: 14))
                    Text("Help").font(AppFont.medium(14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.5), lineWidth: 1))
            }
            Button(action: {}) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .padding(AppSpacing.sm)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(AppRadius.sm)
            }
            .padding(.leading, AppSpacing.sm)
        }
    }

    // MARK: - Header
    // Subtitle changes based on break state
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Hi, \(viewModel.userName.capitalized)!")
                .font(AppFont.regular(16))
                .foregroundColor(.white.opacity(0.9))
            Text(headerTitle)
                .font(AppFont.bold(26))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerTitle: String {
        switch viewModel.breakState {
        case .active:          return "You are on break!"
        case .upcoming:        return "Break coming up"
        case .ended:           return "Break is over!"
        case .idle, .loading:  return "Welcome back!"
        }
    }

    // MARK: - Loading Card
    private var loadingCard: some View {
        VStack(spacing: AppSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            Text("Loading your schedule...")
                .font(AppFont.regular(14))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.breakCardBackground.opacity(0.5))
        .cornerRadius(AppRadius.xl)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Idle Card (no break scheduled)
    private var idleCard: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 52))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, AppSpacing.xl)

            VStack(spacing: AppSpacing.xs) {
                Text("No break scheduled")
                    .font(AppFont.semibold(18))
                    .foregroundColor(.white)
                Text("Enjoy your shift — we'll let you know\nwhen it's time to take a break.")
                    .font(AppFont.regular(14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(Color.breakCardBackground.opacity(0.7))
        .cornerRadius(AppRadius.xl)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Upcoming Card (break hasn't started yet)
    private func upcomingCard(startsAt: String) -> some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                Text("Your break starts at")
                    .font(AppFont.regular(14))
                    .foregroundColor(.white.opacity(0.7))
                Text(startsAt)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.top, AppSpacing.xl)

            // Countdown to break start
            VStack(spacing: AppSpacing.xs) {
                Text("Time until break")
                    .font(AppFont.regular(13))
                    .foregroundColor(.white.opacity(0.6))
                Text(viewModel.formattedCountdown)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(Color.breakCardBackground.opacity(0.7))
        .cornerRadius(AppRadius.xl)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Active Break Card
    private var activeBreakCard: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                Text("We value your hard work!")
                    .font(AppFont.semibold(15))
                    .foregroundColor(.white.opacity(0.9))
                Text("Take this time to relax")
                    .font(AppFont.regular(14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, AppSpacing.lg)

            timerCircle

            Text("Break ends at \(viewModel.breakEndTimeFormatted)")
                .font(AppFont.regular(14))
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, AppSpacing.xs)

            Button(action: viewModel.requestEndBreak) {
                Text("End my break")
            }
            .buttonStyle(DestructiveButtonStyle())
            .padding(.horizontal, AppSpacing.lg)
            .padding(.bottom, AppSpacing.lg)
        }
        .background(Color.breakCardBackground.opacity(0.7))
        .cornerRadius(AppRadius.xl)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - Timer Circle (used only in active state)
    private var timerCircle: some View {
        ZStack {
            Image(systemName: "star.fill")
                .foregroundColor(.white.opacity(0.3)).font(.system(size: 20)).offset(x: -70, y: -30)
            Image(systemName: "star.fill")
                .foregroundColor(.white.opacity(0.25)).font(.system(size: 16)).offset(x: 75, y: -35)
            Image(systemName: "star.fill")
                .foregroundColor(.white.opacity(0.2)).font(.system(size: 14)).offset(x: -80, y: 30)

            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 12)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: 1 - viewModel.timerProgress)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: viewModel.timerProgress)

            VStack(spacing: 4) {
                Text(viewModel.formattedCountdown)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("Break")
                    .font(AppFont.regular(14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(width: 200, height: 200)
    }

    // MARK: - Break Ended Card
    private var breakEndedCard: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                Circle().fill(Color.white.opacity(0.15)).frame(width: 100, height: 100)
                Circle().fill(Color.white.opacity(0.9)).frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.appPrimary)
            }
            .padding(.top, AppSpacing.xl)

            Text("Hope you are feeling refreshed and\nready to start working again")
                .font(AppFont.semibold(16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .background(Color.breakCardBackground.opacity(0.7))
        .cornerRadius(AppRadius.xl)
        .padding(.horizontal, AppSpacing.md)
    }

    // MARK: - End Break Confirmation sheet
    private var endBreakConfirmation: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { viewModel.cancelEndBreak() }

            VStack(alignment: .center, spacing: AppSpacing.lg) {
                Capsule()
                    .fill(Color.appBorder)
                    .frame(width: 40, height: 4)
                    .padding(.top, AppSpacing.sm)

                Text("Ending break early?")
                    .font(AppFont.bold(20))
                    .foregroundColor(.appTextPrimary)

                Text("Are you sure you want to end your break now? Take this time to recharge before your next task.")
                    .font(AppFont.regular(14))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: AppSpacing.md) {
                    Button(action: viewModel.cancelEndBreak) { Text("Continue") }
                        .buttonStyle(PrimaryButtonStyle())
                    Button(action: viewModel.confirmEndBreak) { Text("End now") }
                        .buttonStyle(OutlineButtonStyle())
                }
                .padding(.bottom, AppSpacing.lg)
            }
            .padding(.horizontal, AppSpacing.lg)
            .background(Color.appBackground)
            .cornerRadius(AppRadius.xl)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, 40)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(dampingFraction: 0.8), value: viewModel.showEndBreakConfirmation)
    }
}

// MARK: - Preview
#Preview {
    BreakCoordinatorView()
        .environment(AppCoordinator())
}
