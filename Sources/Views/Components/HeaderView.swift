import SwiftUI

/// Sidebar header with search bar and sort popup button.
/// Figma 47:4200 / 47:4201
struct HeaderView: View {
    @Binding var searchText: String
    @Binding var sortModeRaw: String
    let activeSortMode: SortMode
    @AppStorage("recordingMode") private var recordingMode = false

    var body: some View {
        HStack(spacing: 12) {
            searchBar
            sortButton
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var searchBar: some View {
        let content = HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 16)
            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular))
        }
        .padding(.horizontal, 10)
        .frame(height: 36)

        if recordingMode {
            content.background(Color.primary.opacity(0.06), in: Capsule())
        } else {
            content.glassEffect(.regular, in: Capsule())
        }
    }

    private var sortButtonLabel: some View {
        HStack(spacing: 4) {
            Text(activeSortMode.displayName)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color(nsColor: .secondaryLabelColor))
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(Color(nsColor: .secondaryLabelColor))
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }

    @ViewBuilder
    private var sortButton: some View {
        let label = sortButtonLabel
        if recordingMode {
            label
                .background(Color.primary.opacity(0.06), in: Capsule())
                .overlay {
                    SortPopUpButton(
                        sortModeRaw: $sortModeRaw,
                        activeSortMode: activeSortMode
                    )
                }
                .fixedSize()
        } else {
            label
                .glassEffect(.regular, in: Capsule())
                .overlay {
                    SortPopUpButton(
                        sortModeRaw: $sortModeRaw,
                        activeSortMode: activeSortMode
                    )
                }
                .fixedSize()
        }
    }
}
