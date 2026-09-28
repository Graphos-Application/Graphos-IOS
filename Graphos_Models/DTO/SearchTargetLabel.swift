//
//  SearchTargetLabelDTO.swift
//  Graphos
//
//  Created by Potatostore on 7/27/26.
//
//  when searching with prompt, there are two type results: must include labels, must exclude labels
//  this SearchTargetLabel DTO helps to return two type results

import FoundationModels

@Generable
struct SearchTargetLabel {
    @Guide(description: "이미지 검색 시 포함해야 하는 라벨 목록. 항상 영어 소문자 단수 명사로 작성 (예: cat, sunset)")
    var includedLabels: [String]

    @Guide(description: "이미지 검색 시 제외해야 하는 라벨 목록. 항상 영어 소문자 단수 명사로 작성 (예: dog, person)")
    var excludedLabels: [String]
}
