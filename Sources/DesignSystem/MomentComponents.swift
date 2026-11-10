import SwiftUI

struct PrivateBadge: View {
    var body: some View {
        Label("Private by default", systemImage: "lock.fill")
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.accentText)
            .padding(.vertical, 4)
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
            Image(systemName: moment.kind == .together ? "person.2.fill" : "person.fill")
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(AppColors.accentText)
                .frame(width: 42, height: 46)
                .background(AppColors.accentWash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(moment.kind.displayName)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                    if !moment.privateNote.isEmpty {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(AppColors.secondaryText)
                            .accessibilityLabel("Private note")
                    }
                }
                    .foregroundStyle(AppColors.text)
                Label(moment.mood.displayName, systemImage: moment.mood.symbol)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(AppColors.secondaryText)
                Text(dateText)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(SessionClock.durationText(moment.durationSeconds))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                    .foregroundStyle(AppColors.accentText)
                Label(AppLocalization.format("%lld of 5", moment.rating), systemImage: "star.fill")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(AppColors.secondaryText)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                .stroke(AppColors.separator.opacity(0.6), lineWidth: 0.5)
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
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(AppColors.accentText)
                .frame(width: 60, height: 60)
                .background(AppColors.accentWash, in: Circle())
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppColors.text)
            Text(message)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .background(AppColors.surface.opacity(0.88), in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

struct SelectionPill: View {
    let title: String
    let symbol: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: isSelected ? "checkmark" : symbol).accessibilityHidden(true)
            Text(title).fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(.subheadline, design: .rounded).weight(.medium))
        .foregroundStyle(isSelected ? AppColors.onAccent : AppColors.accentText)
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isSelected ? AppColors.accent : AppColors.accentWash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? AppColors.accentText : .clear, lineWidth: 1.5)
        }
    }
}

extension MomentMood {
    /// Presentation-only system symbols; persisted mood raw values stay stable.
    var symbol: String {
        switch self {
        case .calm: "leaf"
        case .connected: "heart"
        case .joyful: "sparkles"
        case .relaxed: "moon"
        case .happy: "face.smiling"
        }
    }
}

struct ErrorNotice: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.system(.footnote, design: .rounded).weight(.medium))
            .foregroundStyle(AppColors.accentText)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.accentWash.opacity(0.18), in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
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
            .tint(AppColors.accentText)
            .accessibilityHint("Attempts to load your local journal again")
        }
        .padding(12)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
    }
}
