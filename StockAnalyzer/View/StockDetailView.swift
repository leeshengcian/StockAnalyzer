import SwiftUI

struct StockDetailView: View {
    let stock: StockTicker
    @StateObject var networkManager = StockNetworkManager()
    
    // 🔴 1. 新增狀態：用來綁定拉桿的參數 (威廉指標預設常用 14 天)
    @State private var wrPeriod: Double = 14.0
    
    var body: some View {
        ScrollView { // 使用 ScrollView 避免內容太多被裁切
            VStack(spacing: 20) {
                
                // --- 原本的即時股價區塊 ---
                VStack {
                    Text(stock.name).font(.largeTitle).fontWeight(.bold)
                    Text(stock.code).font(.title2).foregroundColor(.gray)
                    
                    if let info = networkManager.stockData {
                        Text("$\(info.z)")
                            .font(.system(size: 60, weight: .heavy))
                            .foregroundColor(.red)
                        Text("累積成交量: \(info.v) 張")
                            .font(.title3).foregroundColor(.gray)
                    } else {
                        ProgressView("正在向證交所抓取最新股價...")
                    }
                }
                .padding(.bottom, 20)
                
                Divider() // 分隔線
                
                // --- 🔴 新增的指標分析區塊 ---
                VStack(alignment: .leading, spacing: 15) {
                    Text("📊 技術指標分析")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // KD 指標控制卡片
                    KDCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // MACD 指標控制卡片
                    MACDCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // BIAS 指標
                    BIASCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // Bollinger Bands 指標
                    BollingerBandsCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // 開盤溢價率
                    PremiumCardView(historicalPrices: networkManager.historicalPrices)
                    
                    // 威廉指標控制卡片
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
            networkManager.startFetchingRealTimeData(stockNo: stock.code, type: stock.type)
            networkManager.fetchHistoricalData(stockNo: stock.code, type: stock.type)
        }
        .onDisappear {
            networkManager.stopFetching()
        }
    }
}
