//
//  NLPService.swift

//  Graphos
//
//  Created by Potatostore on 7/8/26.
//

import Foundation
import FoundationModels
import NaturalLanguage

struct NLPService{
    func convertPromptToSearchTargetLabels(prompt: String) async throws -> SearchTargetLabel{
        let instructions = """
        사용자의 검색 요청 문장에서 포함할 이미지 라벨(targetLabels)과 제외할 이미지 라벨(excludedLabels)을 명사 단어로 구분하여 추출하세요.
        """
        
        
        let session = LanguageModelSession(instructions: instructions)
        
        let response = try await session.respond(
            to: prompt,
            generating: SearchTargetLabel.self
        )
        
        return response.content
    }
}
