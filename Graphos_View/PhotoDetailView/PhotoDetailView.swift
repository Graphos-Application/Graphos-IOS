//
//  PhotoDetailView.swift
//  Graphos_UI
//
//  Created by Potatostore on 9/2/26.
//
//  아이폰 기본 사진 앱의 사진 상세 화면처럼 좌우로 넘기고, 핀치/더블탭으로 확대하고,
//  아래로 당겨서 닫는 전체화면 뷰어. 공유/정보/즐겨찾기 같은 부가 기능은 넣지 않음.

import SwiftUI

struct PhotoDetailView: View {
    @EnvironmentObject var mainViewModel: MainViewModel

    let photos: [DisplayPhoto]
    @State var currentIndex: Int

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var isZoomedIn = false

    private var dismissProgress: CGFloat {
        min(abs(dragOffset) / 400, 1)
    }

    var body: some View {
        ZStack {
            Color.black
                .opacity(1 - dismissProgress * 0.7)
                .ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(photos.indices, id: \.self) { index in
                    PhotoDetailPageView(photo: photos[index].photo, isZoomedIn: $isZoomedIn)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .offset(y: dragOffset)
            .scaleEffect(1 - dismissProgress * 0.15)
            .simultaneousGesture(dismissGesture)

            VStack {
                topBar
                Spacer()
            }
            .opacity(1 - dismissProgress)
        }
        .statusBarHidden(isDragging)
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard !isZoomedIn else { return }
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                isDragging = true
                dragOffset = value.translation.height
            }
            .onEnded { value in
                guard isDragging else { return }

                if abs(value.translation.height) > 120 {
                    mainViewModel.photoDetailContext = nil
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                    isDragging = false
                }
            }
    }

    // 사진 앱처럼 버튼마다 원형 배경을 넣는 대신, 상단 전체에 그라데이션 스크림을 깔고
    // 그 위에 플레인 아이콘만 올려서 가독성을 확보
    private var topBar: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [.black.opacity(0.45), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            HStack {
                Button {
                    mainViewModel.photoDetailContext = nil
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }

                Spacer()

                Button {
                    let target = photos[currentIndex]
                    mainViewModel.photoDetailContext = nil
                    mainViewModel.editingPhoto = target
                    withAnimation(.easeInOut(duration: 0.3)) {
                        mainViewModel.appStatus = .labelEditing
                    }
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
    }
}
