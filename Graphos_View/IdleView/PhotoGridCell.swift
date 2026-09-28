//
//  PhotoGridCell.swift
//  Graphos_UI
//
//  Created by Potatostore on 8/24/26.
//

import SwiftUI

struct PhotoGridCell: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    let photo: DisplayPhoto
    let size: CGFloat

    // 셀마다 GeometryReader를 두면 LazyVGrid가 계산하는 레이아웃 크기와 실제
    // 탭 히트 테스트 영역이 한 박자씩 어긋나서(위쪽을 눌러야 이 사진이 열리고
    // 아래쪽을 누르면 다음 행 사진이 열리는 증상) 그리드 전체에서 계산한 고정
    // 크기를 그대로 받아 씀
    private var cellSize: CGSize { CGSize(width: size, height: size) }

    var body: some View {
        PhotoThumbnailView(
            photo: photo.photo,
            targetSize: cellSize,
            onDeleted: {
                Task { await mainViewModel.removePhoto(id: photo.id) }
            }
        )
        .frame(width: size, height: size)
        .clipped()
        .contentShape(Rectangle())
        .onAppear { PhotoImageLoader.startCaching(for: photo.photo, targetSize: cellSize) }
        .onDisappear { PhotoImageLoader.stopCaching(for: photo.photo, targetSize: cellSize) }
        .onTapGesture {
            mainViewModel.openPhotoDetail(photo: photo)
        }
        .contextMenu(menuItems: {
            Button {
                mainViewModel.editingPhoto = photo
                withAnimation {
                    mainViewModel.appStatus = .labelEditing
                }
            } label: {
                SwiftUI.Label("사진 편집", systemImage: "pencil")
            }
        })
    }
}
