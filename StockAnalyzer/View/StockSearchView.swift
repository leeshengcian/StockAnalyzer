import SwiftUI

struct StockSearchView: View {
    // 綁定我們的網路與資料管理員
    @StateObject var networkManager = StockNetworkManager()
    @StateObject var watchlistManager = WatchlistManager.shared
    
    // 儲存使用者在搜尋框輸入的文字
    @State private var searchText = ""
    
    // 計算屬性：根據使用者的搜尋文字，即時過濾股票清單
    var filteredStocks: [StockTicker] {
        if searchText.isEmpty {
            // 如果搜尋框是空的，顯示全部本地股票 [cite: 40]
            return networkManager.localStockList
        } else {
            // 如果有輸入文字，檢查股票「代碼」或「名稱」是否包含該文字
            return networkManager.localStockList.filter { stock in
                stock.name.contains(searchText) || stock.code.contains(searchText)
            }
        }
    }
    
    var body: some View {
        // NavigationStack 提供頂部的導覽列與標題 (iOS 16+ 適用)
        NavigationStack {
            // 使用 List 將過濾後的陣列資料一筆一筆畫出來
            List(filteredStocks) { stock in
                NavigationLink(destination: StockDetailView(stock: stock)) {
                    HStack{
                        VStack(alignment: .leading, spacing: 4) {
                            Text(stock.name)
                                .font(.headline)
                            
                            HStack {
                                Text(stock.code)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                
                                // 顯示市場類別標籤
                                Text(stock.type == "tse" ? "上市" : "上櫃")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        Spacer()
                        if watchlistManager.isFavorite(stock.code) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                // 增加一個小動畫效果，讓出現時更生動
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        withAnimation(.spring()){
                            watchlistManager.toggleFavorite(stock.code)
                        }
                    } label: {
                        if watchlistManager.isFavorite(stock.code) {
                            Label("取消最愛", systemImage: "star.slash")
                        } else {
                            Label("加入最愛", systemImage: "star.fill")
                        }
                    }
                    .tint(.yellow) // 滑出區塊的背景顏色
                }
            }
            .navigationTitle("台股搜尋")
            // 加上這行，SwiftUI 就會自動幫你生出一個原生的搜尋框！
            .searchable(text: $searchText, prompt: "輸入股票代碼或名稱")
        }
        .onAppear {
            // 當畫面出現時，呼叫我們寫好的函數來讀取本地 JSON 檔案 [cite: 40]
//            networkManager.loadLocalStockList()
//            networkManager.fetchFullStockListFromGovernment()
            networkManager.loadStocks()
        }
    }
}
