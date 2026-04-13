import SwiftUI
import SwiftData

struct SidebarContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PromptNote.createdAt, order: .reverse) private var allPrompts: [PromptNote]

    @State private var searchText = ""
    @AppStorage("sortMode") private var sortModeRaw: String = SortMode.latest.rawValue
    @AppStorage("recordingMode") private var recordingMode = false
    @ObservedObject private var sidebarManager = SidebarManager.shared

    private var sortMode: SortMode {
        SortMode(rawValue: sortModeRaw) ?? .latest
    }

    private var sidebarPosition: SidebarPosition {
        SidebarManager.shared.currentSidebarPosition()
    }

    private var slideOffset: CGFloat {
        sidebarPosition == .left ? -320 : 320
    }

    private var sidebarShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20)
    }

    var body: some View {
        Group {
            if recordingMode {
                promptListSection
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.75), in: sidebarShape)
                    .clipShape(sidebarShape)
            } else {
                GlassEffectContainer {
                    promptListSection
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .glassEffect(.regular, in: sidebarShape)
                }
                .clipShape(sidebarShape)
            }
        }
        .offset(x: sidebarManager.isVisible ? 0 : slideOffset)
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: sidebarManager.isVisible)
        .onChange(of: sidebarManager.dismissCount) {
            searchText = ""
        }
    }

    private var promptListSection: some View {
        let sorted = sortedPrompts
        let filtered = filteredPrompts(from: sorted)

        return PromptListScrollView(
            prompts: filtered,
            sidebarPosition: sidebarPosition,
            showEmptyMessage: filtered.isEmpty && !searchText.isEmpty,
            searchText: $searchText,
            sortModeRaw: $sortModeRaw,
            activeSortMode: sortMode,
            onTap: handlePromptTap,
            onEdit: handlePromptEdit,
            onAdd: handleAddPrompt
        )
    }

    // MARK: - Sorting

    private var sortedPrompts: [PromptNote] {
        switch sortMode {
        case .latest:
            return allPrompts.sorted { $0.createdAt > $1.createdAt }
        case .usage:
            return allPrompts.sorted {
                if $0.useCount != $1.useCount { return $0.useCount > $1.useCount }
                return $0.createdAt > $1.createdAt
            }
        }
    }

    private func filteredPrompts(from prompts: [PromptNote]) -> [PromptNote] {
        guard !searchText.isEmpty else { return prompts }
        let query = searchText.lowercased()
        return prompts.filter {
            $0.body.lowercased().contains(query) ||
            ($0.title?.lowercased().contains(query) ?? false) ||
            ($0.snippetTrigger?.lowercased().contains(query) ?? false)
        }
    }

    // MARK: - Actions

    private func handlePromptTap(_ prompt: PromptNote) {
        SidebarManager.shared.dismiss()
        AutoPasteService.shared.pastePrompt(prompt, context: modelContext)
    }

    private func handlePromptEdit(_ prompt: PromptNote) {
        guard let delegate = AppDelegate.shared else {
#if DEBUG
            print("handlePromptEdit aborted: AppDelegate.shared is nil")
#endif
            return
        }
        delegate.showPromptForm(mode: .edit(prompt))
    }

    private func handleAddPrompt() {
        guard let delegate = AppDelegate.shared else {
#if DEBUG
            print("handleAddPrompt aborted: AppDelegate.shared is nil")
#endif
            return
        }
        delegate.showPromptForm(mode: .create)
    }

}

/// Extracted scroll view to keep the type checker happy with simpler view bodies.
private struct PromptListScrollView: View {
    let prompts: [PromptNote]
    let sidebarPosition: SidebarPosition
    let showEmptyMessage: Bool
    @Binding var searchText: String
    @Binding var sortModeRaw: String
    let activeSortMode: SortMode
    let onTap: (PromptNote) -> Void
    let onEdit: (PromptNote) -> Void
    let onAdd: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    HeaderView(
                        searchText: $searchText,
                        sortModeRaw: $sortModeRaw,
                        activeSortMode: activeSortMode
                    )
                    .padding(.top, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if showEmptyMessage {
                        Text("Nothing found")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        ForEach(prompts) { prompt in
                            PromptCardView(
                                prompt: prompt,
                                onTap: { onTap(prompt) },
                                onEdit: { onEdit(prompt) }
                            )
                            .id(prompt.id)
                        }

                        addButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.03),
                        Color.primary.opacity(0.07)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onChange(of: prompts.count) { oldCount, newCount in
                guard newCount > oldCount, let firstID = prompts.first?.id else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    proxy.scrollTo(firstID, anchor: .top)
                }
            }
        }
    }

    private var addButton: some View {
        ButtonAddView(action: onAdd)
            .frame(
                maxWidth: .infinity,
                alignment: sidebarPosition == .left ? .leading : .trailing
            )
    }
}
