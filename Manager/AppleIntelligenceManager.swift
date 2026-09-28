//
//  AppleIntelligenceManager.swift
//  Graphos
//
//  Created by Potatostore on 9/2/26.
//
//  자연어 검색(NLPService)이 쓰는 온디바이스 모델(Apple Intelligence)이 실제로 쓸 수 있는 상태인지 확인함.
//  이건 카메라/사진 권한과 달리 앱이 시스템 팝업을 띄워달라고 요청할 수 있는 대상이 아니라,
//  설정 앱의 토글이라 앱은 "지금 상태가 어떤지"만 알려줄 수 있음

import FoundationModels

// 가능, 불가능, 디바이스에 깔려 있지 않음, 모델이 준비되지 않음, 모름
enum AppleIntelligenceStatus: Equatable {
    case available
    case notEnabled
    case deviceNotEligible
    case modelNotReady
    case unknown
}

extension AppleIntelligenceStatus {
    var unavailableMessage: String {
        switch self {
        case .available:
            return ""
        case .notEnabled:
            return "사진을 자연어로 검색하려면 Apple Intelligence가 필요해요. 설정에서 켜주시겠어요?"
        case .deviceNotEligible:
            return "이 기기는 Apple Intelligence를 지원하지 않아요. 사진 검색 기능은 사용할 수 없어요."
        case .modelNotReady:
            return "Apple Intelligence 모델을 아직 준비하는 중이에요. 잠시 후 다시 시도해주세요."
        case .unknown:
            return "지금은 사진 검색을 사용할 수 없어요. Apple Intelligence 상태를 확인해주세요."
        }
    }
}

struct AppleIntelligenceManager {
    func checkAvailability() -> AppleIntelligenceStatus {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return .notEnabled
            case .deviceNotEligible:
                return .deviceNotEligible
            case .modelNotReady:
                return .modelNotReady
            @unknown default:
                return .unknown
            }
        @unknown default:
            return .unknown
        }
    }
}
