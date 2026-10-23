import SwiftUI

/// Title bar of each popup screen, styled after an iOS sheet header.
struct SheetHeader<Leading: View, Trailing: View>: View {
    let title: LocalizedStringKey
    let leading: Leading
    let trailing: Trailing

    init(
        _ title: LocalizedStringKey,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                HStack {
                    leading
                    Spacer()
                    trailing
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            Divider().opacity(0.5)
        }
    }
}

struct CircleIconButton: View {
    let systemImage: String
    let help: LocalizedStringKey
    let action: () -> Void

    init(_ systemImage: String, help: LocalizedStringKey, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.help = help
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 30, height: 30)
                .background(Theme.field, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(Text(help))
        .accessibilityLabel(Text(help))
    }
}

/// A labelled block in the editor ("Name", "Date", …).
struct FieldSection<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
    }
}

/// Slight shrink on press, used by cards and the add button.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

/// Tiled, slightly rotated copies of a symbol: the card background texture.
struct SymbolPattern: View {
    let symbol: String

    var body: some View {
        Canvas { context, size in
            guard let resolved = context.resolveSymbol(id: 0) else { return }
            let step: CGFloat = 46
            var row = 0
            for y in stride(from: CGFloat(8), through: size.height + step, by: step * 0.8) {
                let shift = row.isMultiple(of: 2) ? 0 : step / 2
                var column = 0
                for x in stride(from: shift + 8, through: size.width + step, by: step) {
                    var cell = context
                    cell.translateBy(x: x, y: y)
                    cell.rotate(by: .degrees(Double((row * 7 + column * 13) % 5) * 9 - 18))
                    cell.draw(resolved, at: .zero)
                    column += 1
                }
                row += 1
            }
        } symbols: {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white.opacity(0.14))
                .tag(0)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
