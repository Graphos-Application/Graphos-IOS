//
//  LabelEditingView.swift
//  Graphos_UI
//
//  Created by Potatostore on 7/3/26.
//

import SwiftUI

struct LabelEditingView: View {
    @EnvironmentObject var mainViewModel: MainViewModel

    @State private var newLabelText: String = ""
    @State private var workingLabels: [String] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. 편집 대상 이미지 프리뷰
                Group {
                    if let editingPhoto = mainViewModel.editingPhoto {
                        PhotoThumbnailView(
                            photo: editingPhoto.photo,
                            targetSize: CGSize(width: 800, height: 800)
                        )
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // 2. 태그 추가 입력창
                HStack {
                    TextField("새로운 라벨 태그 입력", text: $newLabelText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .submitLabel(.done)
                        .onSubmit(addLabel)

                    Button(action: addLabel) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                // 3. 현재 등록된 라벨 칩(Chip) 그리드 레이아웃
                VStack(alignment: .leading, spacing: 10) {
                    Text("등록된 라벨 레이블")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .bold()

                    // 가변형 칩 레이아웃 (간단한 가로 스크롤 혹은 정렬 처리)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(workingLabels, id: \.self) { label in
                                HStack(spacing: 4) {
                                    Text(label)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)

                                    Button {
                                        withAnimation {
                                            workingLabels.removeAll { $0 == label }
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemFill))
                                .cornerRadius(15)
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationTitle("라벨 수동 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 왼쪽: 취소 버튼을 누르면 상태를 다시 .idle로 돌려보냄
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            mainViewModel.editingPhoto = nil
                            mainViewModel.appStatus = .idle
                        }
                    }
                    .foregroundColor(.red)
                }

                // 오른쪽: 저장 버튼 - StorageManager를 통해 실제 저장 진행
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        let labelsToSave = workingLabels
                        Task {
                            await mainViewModel.saveEditingPhotoLabels(labelsToSave)
                        }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            mainViewModel.appStatus = .idle
                        }
                    }
                    .bold()
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            workingLabels = mainViewModel.editingPhoto?.label.labels ?? []
        }
    }

    private func addLabel() {
        let trimmed = newLabelText.trimmingCharacters(in: .whitespacesAndNewlines)
        newLabelText = ""

        guard !trimmed.isEmpty, !workingLabels.contains(trimmed) else { return }

        withAnimation(.spring()) {
            workingLabels.append(trimmed)
        }
    }
}
