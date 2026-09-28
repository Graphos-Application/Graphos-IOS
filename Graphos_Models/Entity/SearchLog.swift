//
//  SearchLog.swift
//  Graphos
//
//  Created by Potatostore on 7/8/26.
//
//  검색 사용 기록을 분석/보고서용으로 모으는 엔티티. struct로 메모리에만 들고 있으면
//  앱이 종료될 때 전부 사라지므로 SwiftData @Model로 디스크에 저장함

import Foundation
import SwiftData

@Model
final class SearchLog{
    var searchDate: Date
    var searchPrompt: String

    init(searchDate: Date, searchPrompt: String){
        self.searchDate = searchDate
        self.searchPrompt = searchPrompt
    }
}
