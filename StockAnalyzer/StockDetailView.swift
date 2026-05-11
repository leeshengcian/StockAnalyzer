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
                    
                    // 威廉指標控制卡片
                    VStack(alignment: .leading, spacing: 10) {
                        Text("威廉指標 (W%R)")
                            .font(.headline)
                        
                        HStack {
                            Text("計算天數: \(Int(wrPeriod)) 天")
                            Slider(value: $wrPeriod, in: 5...20, step: 1)
                        }
                        
                        // 👇 重點修改：檢查網路是不是已經抓好歷史資料了
                        if networkManager.historicalPrices.isEmpty {
                            ProgressView("正在下載歷史 K 線...")
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            // 👇 將原本的 dummyHistoryData 替換成 networkManager.historicalPrices
                            if let result = WilliamsRCalculator.calculate(prices: networkManager.historicalPrices, period: Int(wrPeriod)) {
                                let statusColor: Color = result.value <= -80 ? .red : (result.value >= -20 ? .green : .primary)
                                Text(result.advice)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(statusColor)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(statusColor.opacity(0.15))
                                    .cornerRadius(8)
                            } else {
                                Text("歷史資料不足，無法計算。")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2)
                    
                    // 📈 MACD 指標控制卡片 (接續在威廉指標下方)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MACD (平滑異同移動平均線)")
                            .font(.headline)
                        
                        HStack {
                            Text("計算參數: 12, 26, 9 (系統標準值)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        // 檢查歷史資料是否準備好
                        if networkManager.historicalPrices.isEmpty {
                            ProgressView("等待歷史資料...")
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            // 呼叫 MACDCalculator
                            if let result = MACDCalculator.calculate(prices: networkManager.historicalPrices) {
                                
                                // 定義狀態顏色：柱狀圖大於 0 顯示紅色(偏多)，小於 0 顯示綠色(偏空)
                                let macdColor: Color = result.histogram > 0 ? .red : .green
                                
                                // 顯示數據細節 (DIF, MACD, OSC)
                                HStack(spacing: 15) {
                                    Text("DIF: \(String(format: "%.2f", result.macd))")
                                    Text("MACD: \(String(format: "%.2f", result.signalLine))")
                                    Text("OSC: \(String(format: "%.2f", result.histogram))")
                                        .foregroundColor(macdColor) // 柱狀圖數值特別標色
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 2)
                                
                                // 顯示帶有背景色的投資建議框
                                Text(result.advice)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(macdColor)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(macdColor.opacity(0.15))
                                    .cornerRadius(8)
                                
                            } else {
                                Text("歷史資料天數不足，無法計算 MACD。")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 2)
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
