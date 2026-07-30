//
//  LabelEditingView.swift
//  Graphos_UI
//
//  Created by Potatostore on 7/3/26.
//

import SwiftUI

struct LabelEditingView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    private var newLabelText: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. 편집 대상 이미지 가상 프리뷰
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
                    .padding(.horizontal)
                
                // 2. 태그 추가 입력창
                HStack {
                    TextField("새로운 라벨 태그 입력", text: newLabelText)
                        .padding(10)
                        .background(mainViewModel.darkMode ? Color(.systemGray6) : Color(.systemGray5))
                        .cornerRadius(8)
                    
                    Button {
                        let trimmed = newLabelText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            withAnimation(.spring()) {
                                mainViewModel.editingPhoto.id
                                newLabelText = ""
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // 3. 현재 등록된 AI 라벨 칩(Chip) 그리드 레이아웃
                VStack(alignment: .leading, spacing: 10) {
                    Text("등록된 라벨 레이블")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .bold()
                    
                    // 가변형 칩 레이아웃 (간단한 가로 스크롤 혹은 정렬 처리)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(mainViewModel.displayPhotos.label.labels, id: \.self) { label in
                                HStack(spacing: 4) {
                                    Text(label)
                                        .font(.subheadline)
                                        .foregroundColor(mainViewModel.darkMode ? .black : .white)
                                    
                                    Button {
                                        // 태그 삭제 로직
                                        withAnimation {
                                            mainViewModel.displayPhotos.label.removeAll { $0 == label }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(mainViewModel.darkMode ? .gray : .white.opacity(0.7))
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(mainViewModel.darkMode ? Color.white : Color.black)
                                .cornerRadius(15)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(mainViewModel.darkMode ? Color.black : Color.white)
            .navigationTitle("라벨 수동 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 왼쪽: 취소 버튼을 누르면 상태를 다시 .idle로 돌려보냄
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            mainViewModel.appStatus = .idle
                        }
                    }
                    .foregroundColor(.red)
                }
                
                // 오른쪽: 저장 버튼 완료 처리
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        print("수정된 라벨 데이터베이스 저장 완료")
                        withAnimation(.easeInOut(duration: 0.3)) {
                            mainViewModel.appStatus = .idle
                        }
                    }
                    .bold()
                    .foregroundColor(.blue)
                }
            }
        }
    }
}
