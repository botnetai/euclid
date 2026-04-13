import EuclidCore
import SwiftUI

struct PermissionChecklistAction {
  enum Style {
    case primary
    case secondary
  }

  let title: String
  var style: Style = .secondary
  let action: () -> Void
}

struct PermissionChecklistRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  var subtitle: String? = nil
  let status: PermissionStatus
  var primaryAction: PermissionChecklistAction? = nil
  var secondaryAction: PermissionChecklistAction? = nil

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(status == .granted ? .secondary : iconColor)
        .frame(width: 18)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.callout.weight(.medium))
          .foregroundStyle(.primary)

        if let subtitle {
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      Spacer(minLength: 12)

      if status == .granted {
        PermissionGrantedBadge()
      } else {
        HStack(spacing: 6) {
          if let primaryAction {
            PermissionChecklistButton(action: primaryAction)
          }

          if let secondaryAction {
            PermissionChecklistButton(action: secondaryAction)
          }
        }
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(Color(nsColor: .controlBackgroundColor))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
    )
  }
}

private struct PermissionGrantedBadge: View {
  var body: some View {
    HStack(spacing: 5) {
      Circle()
        .fill(.green)
        .frame(width: 7, height: 7)

      Text("Granted")
        .font(.caption.weight(.semibold))
        .foregroundStyle(.green)
    }
  }
}

private struct PermissionChecklistButton: View {
  let action: PermissionChecklistAction

  var body: some View {
    Button(action.title, action: action.action)
      .buttonStyle(.plain)
      .font(.caption.weight(.semibold))
      .foregroundStyle(foregroundStyle)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(background)
      .overlay(border)
      .clipShape(Capsule())
  }

  private var foregroundStyle: Color {
    switch action.style {
    case .primary:
      return .white
    case .secondary:
      return .primary
    }
  }

  @ViewBuilder
  private var background: some View {
    switch action.style {
    case .primary:
      Capsule()
        .fill(Color.accentColor)
    case .secondary:
      Capsule()
        .fill(Color(nsColor: .windowBackgroundColor))
    }
  }

  @ViewBuilder
  private var border: some View {
    switch action.style {
    case .primary:
      EmptyView()
    case .secondary:
      Capsule()
        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
    }
  }
}
