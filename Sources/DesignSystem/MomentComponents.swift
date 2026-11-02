import SwiftUI

struct PrivateBadge: View {
    var body: some View {
        Label("Private by default", systemImage: "lock.fill")
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.terracottaDark)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(AppColors.blush.opacity(0.18), in: Capsule())
            .accessibilityLabel("Private by default")
    }
}

struct MomentRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let moment: Moment

    private var dateText: String {
        moment.occurredAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        rowLayout {
            Circle()
                .fill(AppColors.terracotta)
                .frame(width: 10, height: 10)
                .padding(5)
                .background(AppColors.blush.opacity(0.16), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(dateText)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppColors.ink)
                Text(AppLocalization.format("%@ · %@", moment.kind.displayName, moment.mood.displayName))
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(AppColors.inkSoft)
            }

            Spacer(minLength: 8)

            Text(SessionClock.durationText(moment.durationSeconds))
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundStyle(AppColors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(AppColors.line.opacity(0.72), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var rowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 13))
    }
}

struct EmptyStateCard: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var symbol: String = "heart.text.square"

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(AppColors.terracotta)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.ink)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(AppColors.paper.opacity(0.88), in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.line, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        }
    }
}

struct ErrorNotice: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.system(.footnote, design: .rounded).weight(.medium))
            .foregroundStyle(AppColors.terracottaDark)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.blush.opacity(0.18), in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
    }
}

struct StorageRecoveryCard: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ErrorNotice(message: message)
            Button(action: onRetry) {
                Label("Try again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(AppColors.terracottaDark)
            .accessibilityHint("Attempts to load your local journal again")
        }
        .padding(12)
        .background(AppColors.paper, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
    }
}
