//
//  SearchLogManager.swift
//  Graphos
//
//  Created by Potatostore on 9/3/26.
//
//  검색 기록(SearchLog)을 저장하고, 분석/보고서용으로 꺼내볼 수 있게 CSV 파일로 내보냄

import Foundation
import SwiftData

@MainActor
struct SearchLogManager {
    private let modelContext: ModelContext = ModelContext(MainView.modelContainer)

    // autosaveEnabled가 켜져 있어도 언제 저장될지 보장되지 않아서, insert만 해두면 저장 전에
    // 앱이 종료됐을 때 기록이 유실됨 - 검색은 빈도가 낮으니 기록할 때마다 바로 save()함
    func saveSearchLog(searchLog: SearchLog) async{
        modelContext.insert(searchLog)
        try? modelContext.save()
    }

    // 오래된 기록부터 시간순으로 반환
    func loadAllSearchLogs() async -> [SearchLog]{
        let fetchDescriptor = FetchDescriptor<SearchLog>(
            sortBy: [SortDescriptor(\.searchDate)]
        )
        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }

    // 전체 기록을 앱 Documents 폴더의 search_logs.csv로 저장하고 파일 URL을 반환함.
    // 매번 전체 기록을 다시 쓰기 때문에 같은 파일을 덮어써도 이전에 내보낸 내용이 사라지지 않음
    func exportSearchLogsAsCSV() async -> URL?{
        let searchLogs = await loadAllSearchLogs()

        // 기기의 달력/12시간제 설정과 상관없이 스프레드시트가 날짜로 인식하는 고정 형식을
        // 쓰기 위해 en_US_POSIX로 고정함. 시간은 기기 현지 시간 기준
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        var csv = "searchDate,searchPrompt\n"
        for searchLog in searchLogs{
            csv += "\(dateFormatter.string(from: searchLog.searchDate)),\(escapeCSVField(searchLog.searchPrompt))\n"
        }

        let fileURL = URL.documentsDirectory.appending(path: "search_logs.csv")

        do{
            // Excel은 BOM이 없는 UTF-8 CSV를 시스템 인코딩으로 읽어서 한글 검색어가 깨짐 -
            // 맨 앞에 BOM을 붙여 UTF-8임을 알려줌 (Numbers, 구글 시트는 BOM이 있어도 문제없음)
            try ("\u{FEFF}" + csv).write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch{
            return nil
        }
    }

    // 검색어에 쉼표, 큰따옴표, 줄바꿈이 들어가도 열이 밀리지 않도록 큰따옴표로 감싸고
    // 안쪽 큰따옴표는 두 번 써서 이스케이프함 (RFC 4180)
    private func escapeCSVField(_ field: String) -> String{
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
