import SwiftUI

/// Thumbnail view for a page in the sidebar.
struct PageThumbnailView: View {
    let page: Page
    let index: Int
    let isSelected: Bool
    var onSelect: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            // Mini page preview
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                // Background pattern indicator
                backgroundPatternPreview(page.backgroundStyle)

                // Stroke count indicator
                if !page.strokes.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(page.strokes.count)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(2)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 2))
                        }
                    }
                    .padding(3)
                }
            }
            .frame(width: 90, height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        isSelected ? Color.accentColor : Color.clear,
                        lineWidth: 2
                    )
            )

            Text("Page \(index + 1)")
                .font(.caption2)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .lineLimit(1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button("Delete Page", role: .destructive, action: onDelete)
        }
    }

    @ViewBuilder
    private func backgroundPatternPreview(_ style: BackgroundStyle) -> some View {
        switch style {
        case .blank:
            EmptyView()
        case .lined:
            VStack(spacing: 8) {
                ForEach(0..<8, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 0.5)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 12)
        case .grid:
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 10
                    var x: CGFloat = spacing
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += spacing
                    }
                    var y: CGFloat = spacing
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += spacing
                    }
                }
                .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
            }
        case .dotGrid:
            GeometryReader { geo in
                Canvas { ctx, size in
                    let spacing: CGFloat = 8
                    var x: CGFloat = spacing
                    while x < size.width {
                        var y: CGFloat = spacing
                        while y < size.height {
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x - 0.5, y: y - 0.5, width: 1, height: 1)),
                                with: .color(.gray.opacity(0.3))
                            )
                            y += spacing
                        }
                        x += spacing
                    }
                }
            }
        }
    }
}
