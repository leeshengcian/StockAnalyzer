import SwiftUI

struct StockDetailView: View {
    let stock: StockTicker
    @StateObject var networkManager = StockNetworkManager()
    
    // 用來綁定拉桿的參數 (威廉指標預設常用 14 天)
    @State private var wrPeriod: Double = 14.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // --- 🌟 同步後的即時行情區塊 ---
                VStack(spacing: 8) {
                    Text(stock.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(stock.code)
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    // 🌟 核心同步：使用與 WatchListRowView 一樣的 tClose 邏輯
                    if let lastKLine = networkManager.historicalPrices.last {
                        let currentPrice = lastKLine.close
                        
                        VStack(spacing: 4) {
                            Text("現價") // 👈 明確標示
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 10)
                            
                            Text("$\(String(format: "%.2f", currentPrice))")
                                .font(.system(size: 60, weight: .heavy, design: .rounded))
                                .foregroundColor(getPriceColor(currentPrice: currentPrice)) // 動態顏色
                        }
                        
                        // 顯示成交量 (從最後一根 K 線抓取最新累積量)
                        Text("累積成交量: \(Int(lastKLine.volume)) 張")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    } else {
                        // 資料載入中
                        VStack(spacing: 15) {
                            ProgressView()
                            Text("正在計算最新技術指標...")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.bottom, 10)
                
                Divider()
                
                // --- 指標分析區塊 (保持模組化) ---
                VStack(alignment: .leading, spacing: 15) {
                    Text("📊 技術指標分析")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // KD 指標
                    KDCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // MACD 指標
                    MACDCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // BIAS 指標
                    BIASCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // Bollinger Bands 指標
                    BollingerBandsCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // 開盤溢價率
                    PremiumCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // 威廉指標
                    WilliamsRCardView(historicalPrices: networkManager.historicalPrices)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle(stock.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 同時啟動歷史數據抓取 (用於指標計算與現價顯示)
//            networkManager.fetchHistoricalData(stockNo: stock.code, type: stock.type)
            networkManager.startAutoRefresh(stockNo: stock.code, type: stock.type)
        }
        .onDisappear {
            // 🌟 離開詳情頁時停止更新
            networkManager.stopAutoRefresh()
        }
    }
    
    // 💡 漲跌顏色判斷函數：與昨收比
    func getPriceColor(currentPrice: Double) -> Color {
        // 確保至少有兩天的資料 (今天與昨天) 才能比對
        guard networkManager.historicalPrices.count >= 2 else { return .primary }
        
        let yesterdayClose = networkManager.historicalPrices[networkManager.historicalPrices.count - 2].close
        
        if currentPrice > yesterdayClose {
            return .red
        } else if currentPrice < yesterdayClose {
            return .green
        } else {
            return .primary // 平盤
        }
    }
}
