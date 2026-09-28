//
//  IdleView.swift
//  Graphos_UI
//
//  Created by Potatostore on 5/18/26.
//

import SwiftUI

// 헤더가 실제로 차지하는 높이를 측정해서 그리드 콘텐츠의 상단 여백으로 씀
private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// 블러가 상태바/다이나믹 아일랜드 영역까지 뻗어나가도록 안전 영역 상단 높이를 측정
private struct SafeAreaTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct IdleView: View {
    @EnvironmentObject var mainViewModel: MainViewModel

    @State var isSearching = false
    @State var searchQuery = ""
    @FocusState var isTextFieldFocused: Bool
    @State private var headerHeight: CGFloat = 0
    @State private var topSafeAreaInset: CGFloat = 0
    private let headerFadeDistance: CGFloat = 24

    private let gridSpacing: CGFloat = 2
    private let columnCount = 3

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body : some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                Group {
                    if isSearching {
                        SearchingView(
                            isSearching: $isSearching,
                            searchQuery: $searchQuery,
                            mainViewModel: mainViewModel,
                            isTextFieldFocused: $isTextFieldFocused
                        )
                    } else {
                        photoGrid
                    }
                }

                if !isSearching {
                    header
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(key: SafeAreaTopKey.self, value: geometry.safeAreaInsets.top)
                }
            )
            .onPreferenceChange(SafeAreaTopKey.self) { topSafeAreaInset = $0 }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(item: $mainViewModel.photoDetailContext) { context in
            PhotoDetailView(photos: context.photos, currentIndex: context.initialIndex)
                .environmentObject(mainViewModel)
        }
    }

    // 아이폰 기본 사진 앱처럼 타이틀이 위치를 바꾸지 않고 고정된 채로 있다가,
    // 사진이 그 밑으로 스크롤되어 지나가면 배경이 반투명하게 비치는 헤더.
    // 블러에 그라데이션 마스크를 씌워서 경계선 없이 서서히 옅어지게 함
    private var header: some View {
        let solidHeight = topSafeAreaInset + headerHeight
        let totalHeight = solidHeight + headerFadeDistance

        return ZStack(alignment: .top) {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .black, location: solidHeight / max(totalHeight, 1)),
                            .init(color: .clear, location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: totalHeight)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

            titleRow
        }
    }

    private var titleRow: some View {
        HStack {
            Text("보관함")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isSearching = true
                    isTextFieldFocused = true
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            GeometryReader { geometry in
                Color.clear.preference(key: HeaderHeightKey.self, value: geometry.size.height)
            }
        )
        .onPreferenceChange(HeaderHeightKey.self) { headerHeight = $0 }
    }

    private var photoGrid: some View {
        GeometryReader { geometry in
            let totalSpacing = gridSpacing * CGFloat(columnCount - 1)
            let cellSide = (geometry.size.width - totalSpacing) / CGFloat(columnCount)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVGrid(columns: columns, spacing: gridSpacing) {
                        ForEach(mainViewModel.displayPhotos) { photo in
                            PhotoGridCell(photo: photo, size: cellSide)
                                .id(photo.id)
                        }
                    }
                    .padding(.top, headerHeight)
                }
                // 사진 앱처럼 최신 사진(그리드 맨 아래)이 보이는 상태로 시작
                .onAppear {
                    if let lastId = mainViewModel.displayPhotos.last?.id {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}
