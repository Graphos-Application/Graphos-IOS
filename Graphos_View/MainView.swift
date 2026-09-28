//
//  MainView.swift
//  Graphos_UI
//
//  Created by Potatostore on 7/3/26.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @StateObject var mainViewModel: MainViewModel = MainViewModel()
    
    static let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Label.self, SearchLog.self)
        } catch {
            fatalError("데이터베이스를 열 수 없습니다: \(error)")
        }
    }()
    
    var body: some View {
        ZStack {
            switch mainViewModel.appStatus {
            case .loading:
                LoadingView()
                
            case .idle:
                IdleView()
                
            case .labelEditing:
                LabelEditingView()
            }
        }.environmentObject(mainViewModel)
    }
}

#Preview {
    MainView().environmentObject(MainViewModel())
}
