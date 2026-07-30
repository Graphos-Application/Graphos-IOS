//
//  MainViewModel.swift
//  Graphos
//
//  Created by Potatostore on 7/8/26.
//

import Foundation
import Photos
import Combine

class MainViewModel: ObservableObject {
    internal let objectWillChange: ObservableObjectPublisher
    
    private let photoToLabelService = PhotoToLabelService()
    private let nlpService = NLPService()
    
    @Published var displayPhotos: [DisplayPhoto] = []
    @Published var searchingPhotos: [DisplayPhoto]? = nil
    
    @Published var appStatus: AppStatus = .loading
    @Published var darkMode: Bool = false
    @Published var isSearching: Bool = false
    @Published var editingPhoto: DisplayPhoto? = nil
    
    init(){
        appStatus = .loading
        objectWillChange = .init()
    }
    
    func searchPhotos(prompt: String) async {
        
    }
    
    func resetSearch(){
        searchingPhotos = nil
        isSearching = false
    }
    
    func filterPhotos(target: SearchTargetLabel) -> [DisplayPhoto]{
        return self.displayPhotos.filter{photo in
            let photoLabels = Set(photo.label.labels)
            
            for excluded in target.excludedLabels {
                if photoLabels.contains(excluded) { return false }
            }
            
            if !target.includedLabels.isEmpty {
                return target.targetLabels.contains { photoLabels.contains($0) }
            }
            
            return true
        }
    }
    
}
