import SwiftUI

struct ContentView: View {
    @State private var isMenuOpen = false
    @State private var selectedOption: SidebarOption = .watchlist
    
    var body: some View {
        ZStack(alignment: .leading) {
            // 主內容區域
            NavigationStack {
                Group {
                    switch selectedOption {
                    case .search:
                        // 👇 直接呼叫我們剛拆出去的檔案
                        StockSearchView()
                    case .watchlist:
                        WatchlistView()
                    case .settings:
                        Text("設定頁面").font(.title)
                    }
                }
                .navigationTitle(selectedOption.rawValue)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation(.spring()) { isMenuOpen.toggle() }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .overlay(isMenuOpen ? Color.black.opacity(0.3).ignoresSafeArea() : nil)
            
            // 側邊選單
            SidebarMenuView(isMenuOpen: $isMenuOpen, selectedOption: $selectedOption)
                .offset(x: isMenuOpen ? 0 : -250)
                .ignoresSafeArea()
        }
    }
}
