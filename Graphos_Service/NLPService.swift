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
    // 온디바이스 모델을 못 쓰는 상황(Apple Intelligence 꺼짐/미지원/시뮬레이터 등)이면
    // 에러를 던지는 대신 nil을 반환 - 호출부는 이걸 "검색 결과 없음"과 동일하게 처리함
    //
    // availableLabels: 현재 라이브러리에 실제로 붙어있는 라벨 전체 목록(중복 제거).
    // 이걸 프롬프트에 그대로 넘겨서 모델이 "이 중에서 고르라"는 제약을 받게 함.
    // 그냥 자유 번역시키면 "병"처럼 중의적인 단어("bottle" vs "illness")를 엉뚱하게
    // 옮기거나, 맞게 옮겨도 단수/복수·동의어가 Vision이 실제로 붙인 라벨과 정확히
    // 안 맞아서(예: "bottles" vs "bottle") 검색이 실패하는 문제가 실기기에서 확인됨
    func convertPromptToSearchTargetLabels(prompt: String, availableLabels: [String]) async -> SearchTargetLabel?{
        let vocabularyList = availableLabels.isEmpty
            ? "(없음)"
            : availableLabels.joined(separator: ", ")

        let instructions = """
        사용자의 검색 요청 문장에서 포함할 이미지 라벨(includedLabels)과 제외할 이미지 라벨(excludedLabels)을 추출하세요.

        아래는 사용자의 사진 라이브러리에 실제로 붙어있는 라벨 목록입니다. 반드시 이 목록 중에서
        문장의 의미와 가장 가깝게 일치하는 라벨을 정확히 그대로(철자, 단수형까지) 골라 사용하세요.
        목록에 있는 단어를 변형하거나(복수형으로 바꾸는 등) 새로운 단어를 지어내지 마세요.
        의미가 맞는 라벨이 목록에 전혀 없을 때만 목록 밖의 영어 소문자 단수 명사를 사용하세요.

        라벨 목록: \(vocabularyList)

        - 사용자의 문장이 어떤 언어이든(한국어 포함), 위 목록에서 뜻이 맞는 라벨을 찾아 그대로 반환하세요.
          (예: 목록에 "bottle"이 있고 사용자가 "병 사진 보여줘"라고 하면 → includedLabels: ["bottle"])
        - 기프티콘, 모바일 쿠폰, 상품권처럼 이미지 분류 모델의 일반적인 사물 카테고리로는
          표현되지 않는 개념을 찾는 요청이면, 목록에 "barcode"가 있을 때 그것을 사용하세요
          (이런 모바일 쿠폰류는 거의 항상 교환용 바코드/QR 코드가 포함되어 있습니다).
          (예: 목록에 "barcode"가 있고 사용자가 "기프티콘 찾아줘"라고 하면 → includedLabels: ["barcode"])
        - 목록에 없어 새로 만들어야 하는 경우에도 영어 소문자 단수 명사로 작성하세요.
        """

        let session = LanguageModelSession(instructions: instructions)

        let response = try? await session.respond(
            to: prompt,
            generating: SearchTargetLabel.self
        )

        return response?.content
    }
}
