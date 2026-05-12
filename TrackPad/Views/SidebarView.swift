import SwiftUI

/// Sidebar showing page thumbnails for navigation.
struct SidebarView: View {
    @ObservedObject var document: NotebookDocument
    var onAddPage: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Pages")
                    .font(.headline)
                Spacer()
                Button(action: onAddPage) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
                .help("Add Page")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Page list
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 12) {
                    ForEach(Array(document.pages.enumerated()), id: \.element.id) { index, page in
                        PageThumbnailView(
                            page: page,
                            index: index,
                            isSelected: index == document.currentPageIndex,
                            onSelect: {
                                document.currentPageIndex = index
                            },
                            onDelete: {
                                document.deletePage(at: index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 120)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
