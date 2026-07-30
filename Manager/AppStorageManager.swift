//
//  AppStorageManager.swift
//  Graphos
//
//  Created by Potatostore on 7/15/26.
//

import SwiftData
import Foundation

@MainActor
struct AppStorageManager{
    private var modelContext: ModelContext{
        return ModelContext(MainView.modelContainer)
    }
    
    func loadAllLabels() async -> [Label]{
        let fetchDescriptor = FetchDescriptor<Label>()
        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
    
    func findByPhotoId(id: String) async -> Label{
        var fetchDescriptor = FetchDescriptor<Label>(
            predicate: #Predicate<Label>{label in
                label.id == id
            }
        )
        
        fetchDescriptor.fetchLimit = 1
        
        return (try? modelContext.fetch(fetchDescriptor).first) ?? Label(id: id)
    }
    
    func saveLabel(label: Label) async{
        modelContext.insert(label)
        try? modelContext.save()
    }
    
    func updateLabels(id: String, labels: [String]) async{
        var existLabel: Label = await findByPhotoId(id: id)
        
        existLabel.labels = labels
        
        try? modelContext.save()
    }
    
    func deleteLabels(id: String) async{
        let existLabel: Label = await findByPhotoId(id: id)
        modelContext.delete(existLabel)
        try? modelContext.save()
    }
    
    func deleteOrphanedLabels(activatePhotoIds: [String]) async{
        let allLabels = await loadAllLabels()
        
        let photoIds = Set(activatePhotoIds)
        
        let orphanedLabels = allLabels.filter{!photoIds.contains($0.id)}
        
        for label in orphanedLabels{
            modelContext.delete(label)
        }
    }
}
