import SwiftUI

struct WatchlistView: View {
    @StateObject var networkManager = StockNetworkManager()
    @StateObject var watchlistManager = WatchlistManager.shared
    
    // 篩選出只有出現在自選清單中的股票
    var favoriteStocks: [StockTicker] {
        networkManager.localStockList.filter { watchlistManager.isFavorite($0.code) }
    }
    
    var body: some View {
        VStack {
            if favoriteStocks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                    Text("目前沒有自選股票")
                        .font(.headline)
                    Text("請到台股搜尋頁面，向右滑動股票來加入。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                List(favoriteStocks) { stock in
                    NavigationLink(destination: StockDetailView(stock: stock)) {
                        WatchlistRowView(stock: stock)
                    }
                    // 在自選頁面可以提供左滑刪除功能
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
        .onAppear {
            networkManager.loadStocks() // 確保有股票基本資料可以過濾
        }
    }
}
