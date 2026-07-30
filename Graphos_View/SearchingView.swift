import SwiftUI

struct SearchingView: View {
    @Binding var isSearching: Bool
    @Binding var searchQuery: String
    
    @ObservedObject var mainViewModel: MainViewModel
    
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("어떤 사진을 찾으시나요?", text: $searchQuery)
                    .focused($isTextFieldFocused)
                    .submitLabel(.search)
                    .foregroundColor(mainViewModel.darkMode ? .white : .black)
                    .onSubmit {
                        print("검색어 제출: \(searchQuery)")
                    }
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(mainViewModel.darkMode ? Color(.systemGray5) : Color(.systemGray6))
            .cornerRadius(10)
            
            Button("취소") {
                withAnimation(.easeOut(duration: 0.2)) {
                    isSearching = false
                    searchQuery = ""
                    isTextFieldFocused = false // 키보드 내림
                }
            }
            .foregroundColor(.blue)
        }
        .padding()
        .background(mainViewModel.darkMode ? Color.black : Color.white)
    }
}
