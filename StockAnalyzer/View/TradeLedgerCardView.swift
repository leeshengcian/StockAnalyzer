import SwiftUI

struct TradeLedgerCardView: View {
    let stockCode: String
    let currentPrice: Double
    
    // 引入剛剛寫好的管理員
    @StateObject private var tradeManager = TradeManager()
    
    // 輸入框狀態
    @State private var buyPriceStr: String = ""
    @State private var sellPriceStr: String = ""
    @State private var quantityStr: String = "1"
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // --- 1. 總結儀表板 ---
            let tProfit = tradeManager.totalProfit(for: stockCode)
            let tROI = tradeManager.totalROI(for: stockCode)
            
            HStack {
                Text("📝 歷史交易績效")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(tProfit >= 0 ? "+$\(String(format: "%.0f", tProfit))" : "-$\(String(format: "%.0f", abs(tProfit)))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(tProfit > 0 ? .red : (tProfit < 0 ? .green : .primary))
                    
                    Text("總報酬率: \(String(format: "%.2f", tROI))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // --- 2. 新增紀錄輸入區 ---
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("買入").font(.caption).foregroundColor(.gray)
                    TextField("價格", text: $buyPriceStr).keyboardType(.decimalPad).textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 一鍵帶入現價按鈕
                    HStack {
                        Text("賣出").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Button(action: { sellPriceStr = String(format: "%.1f", currentPrice) }) {
                            Text("現價").font(.system(size: 9)).foregroundColor(.blue)
                        }
                    }
                    TextField("價格", text: $sellPriceStr).keyboardType(.decimalPad).textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("股數").font(.caption).foregroundColor(.gray)
                    TextField("數量", text: $quantityStr).keyboardType(.decimalPad).textFieldStyle(RoundedBorderTextFieldStyle()).frame(width: 60)
                }
                
                // 儲存按鈕
                Button(action: saveNewTrade) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .padding(.bottom, 4)
                }
            }
            
            // --- 3. 歷史紀錄列表 ---
            let myTrades = tradeManager.tradesFor(stockCode: stockCode)
            
            if !myTrades.isEmpty {
                Divider().padding(.vertical, 4)
                
                VStack(spacing: 12) {
                    ForEach(myTrades) { trade in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trade.date, style: .date)
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                HStack {
                                    Text("買: \(String(format: "%.1f", trade.buyPrice))")
                                    Text("賣: \(String(format: "%.1f", trade.sellPrice))")
                                }
                                .font(.caption)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(trade.profit > 0 ? "+" : "")\(String(format: "%.0f", trade.profit))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(trade.profit > 0 ? .red : .green)
                                Text("\(Int(trade.quantity)) 股")
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            
                            // 刪除按鈕
                            Button(action: { tradeManager.deleteTrade(id: trade.id) }) {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.red.opacity(0.6))
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 儲存邏輯與清空輸入框
    private func saveNewTrade() {
        guard let bPrice = Double(buyPriceStr),
              let sPrice = Double(sellPriceStr),
              let qty = Double(quantityStr),
              qty > 0 else { return }
        
        tradeManager.addTrade(stockCode: stockCode, buyPrice: bPrice, sellPrice: sPrice, quantity: qty)
        
        // 成功後清空輸入框
        buyPriceStr = ""
        sellPriceStr = ""
    }
}
