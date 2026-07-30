//
//  DisplayPhoto.swift
//  Graphos
//
//  Created by Potatostore on 7/13/26.
//
//  DisplayPhoto struct uses for DTO displaying photos and editing labels

struct DisplayPhoto: Identifiable{
    var id: String
    var photo: Photo
    var label: Label
    
    init(photo: Photo, label: Label){
        self.photo = photo
        self.label = label
        self.id = photo.id
    }
    
}
