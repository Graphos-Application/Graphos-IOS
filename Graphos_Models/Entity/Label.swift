//
//  LabeledPhoto.swift
//  Graphos
//
//  Created by Potatostore on 7/8/26.
//
//  Using class for saved in app memory

import Foundation
import SwiftData

@Model
class Label{
    @Attribute(.unique) var id: String
    var labels: [String]
    
    init(id: String, labels: [String]){
        self.id = id
        self.labels = labels
    }
    
    init(id: String){
        self.id = id
        self.labels = []
    }
}
