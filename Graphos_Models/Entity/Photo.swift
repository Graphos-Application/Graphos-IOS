//
//  Photo.swift
//  Graphos
//
//  Created by Potatostore on 7/8/26.
//
//  Using Photo struct for update pictures from local photo app

import Photos

struct Photo: Identifiable{
    let id: String
    let asset: PHAsset
}
