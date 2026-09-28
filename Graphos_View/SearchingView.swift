import SwiftUI

struct SearchingView: View {
    @Binding var isSearching: Bool
    @Binding var searchQuery: String

    @ObservedObject var mainViewModel: MainViewModel

    @FocusState.Binding var isTextFieldFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
    ]
    private let gridSpacing: CGFloat = 2
    private let columnCount = 3

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            resultsContent
        }
        .background(Color(.systemBackground))
    }

    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("어떤 사진을 찾으시나요?", text: $searchQuery)
                    .focused($isTextFieldFocused)
                    .submitLabel(.search)
                    .foregroundColor(.primary)
                    .onSubmit {
                        Task {
                            await mainViewModel.searchPhotos(prompt: searchQuery)
                        }
                        Task{
                            await mainViewModel.saveSearchLog(searchPrompt: searchQuery, searchDate: Date())
                        }
                    }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        mainViewModel.resetSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            Button("취소") {
                withAnimation(.easeOut(duration: 0.2)) {
                    isSearching = false
                    searchQuery = ""
                    isTextFieldFocused = false // 키보드 내림
                    mainViewModel.resetSearch()
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
    }

    @ViewBuilder
    private var resultsContent: some View {
        if mainViewModel.isSearching {
            Spacer()
            ProgressView()
            Spacer()
        } else if let results = mainViewModel.searchingPhotos {
            if results.isEmpty {
                Spacer()
                if let status = mainViewModel.searchUnavailableStatus {
                    VStack(spacing: 8) {
                        Image(systemName: "apple.intelligence")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(status.unavailableMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 32)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("검색 결과가 없습니다")
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            } else {
                GeometryReader { geometry in
                    let totalSpacing = gridSpacing * CGFloat(columnCount - 1)
                    let cellSide = (geometry.size.width - totalSpacing) / CGFloat(columnCount)

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: gridSpacing) {
                            ForEach(results) { photo in
                                PhotoGridCell(photo: photo, size: cellSide)
                            }
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
        } else {
            Spacer()
        }
    }
}
