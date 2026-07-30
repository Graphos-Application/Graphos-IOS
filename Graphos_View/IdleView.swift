//
//  IdleView.swift
//  Graphos_UI
//
//  Created by Potatostore on 5/18/26.
//

import SwiftUI

struct IdleView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    @State var isSearching = false
    @State var searchQuery = ""
    @FocusState var isTextFieldFocused: Bool
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]
    
    private let dummys = Array(1...30).reversed()
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body : some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isSearching {
                    SearchingView(
                        isSearching: $isSearching,
                        searchQuery: $searchQuery,
                        mainViewModel: mainViewModel,
                        isTextFieldFocused: $isTextFieldFocused
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(mainViewModel.displayPhotos){ photo in
                            Button{
                                mainViewModel.editingPhoto = photo
                                withAnimation {
                                    mainViewModel.appStatus = .labelEditing
                                }
                            } label: {
                                Rectangle()
                                    .fill(Color.red)
                                    .aspectRatio(1, contentMode: .fit)
                                    .overlay(
                                        //이미지 출력 코드 작성
                                        Text(photo.id)
                                    )
                            }
                        }
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .background(mainViewModel.darkMode ? Color.black : Color.white)
            .navigationTitle(isSearching ? "사진 검색" : "보관함")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(mainViewModel.darkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isSearching {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isSearching = true
                                isTextFieldFocused = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(mainViewModel.darkMode ? .white : .black)
                        }
                    }
                }
            }
        }
    }
}
