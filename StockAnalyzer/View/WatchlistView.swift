import SwiftUI

struct WatchlistView: View {
    @StateObject var networkManager = StockNetworkManager()
    @StateObject var watchlistManager = WatchlistManager.shared
    
    // 篩選出只有出現在自選清單中的股票
    var favoriteStocks: [StockTicker] {
        networkManager.localStockList.filter { watchlistManager.isFavorite($0.code) }
    }
    
    // 🌟 定義台股大盤指數
    let taiex = StockTicker(code: "^TWII", name: "加權指數", type: "index")
    
    var body: some View {
        VStack {
            List {
                // ==========================================
                // 🌟 第一區塊：永遠置頂的大盤指數 (不能被刪除)
                // ==========================================
                Section {
                    NavigationLink(destination: StockDetailView(stock: taiex)) {
                        WatchlistRowView(stock: taiex)
                    }
                }
                
                // ==========================================
                // 🌟 第二區塊：使用者的自選股票
                // ==========================================
                Section {
                    if favoriteStocks.isEmpty {
                        // 當沒有自選股時，在 List 裡面顯示提示
                        VStack(spacing: 12) {
                            Image(systemName: "star.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("目前沒有自選股票")
                                .font(.headline)
                            Text("請到台股搜尋頁面，向右滑動股票來加入。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        // 隱藏列的分隔線與背景，讓空狀態看起來更自然
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                    } else {
                        // 使用者自己加入的股票清單
                        ForEach(favoriteStocks) { stock in
                            NavigationLink(destination: StockDetailView(stock: stock)) {
                                WatchlistRowView(stock: stock)
                            }
                            // 提供左滑刪除功能
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    watchlistManager.toggleFavorite(stock.code)
                                } label: {
                                    Label("移除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.plain) // 讓清單樣式乾淨俐落
        }
        .onAppear {
            networkManager.loadStocks() // 確保有股票基本資料可以過濾
        }
    }
}
