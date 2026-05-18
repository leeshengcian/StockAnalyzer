import SwiftUI
import Combine

// 1. 定義單筆交易紀錄的模型 (必須遵守 Codable 才能存入 UserDefaults)
struct TradeRecord: Identifiable, Codable {
    let id: UUID
    let stockCode: String // 綁定股票代號，確保台積電的紀錄不會跑到鴻海去
    let buyPrice: Double
    let sellPrice: Double
    let quantity: Double
    let date: Date
    
    // 計算屬性：單筆的成本、營收與損益
    var cost: Double { buyPrice * quantity }
    var revenue: Double { sellPrice * quantity }
    var profit: Double { revenue - cost }
}

// 2. 交易紀錄管理員
class TradeManager: ObservableObject {
    @Published var trades: [TradeRecord] = []
    
    // 每次初始化時，自動從手機載入舊紀錄
    init() {
        loadTrades()
    }
    
    // MARK: - CRUD 資料操作
    
    func addTrade(stockCode: String, buyPrice: Double, sellPrice: Double, quantity: Double) {
        let newTrade = TradeRecord(id: UUID(), stockCode: stockCode, buyPrice: buyPrice, sellPrice: sellPrice, quantity: quantity, date: Date())
        trades.insert(newTrade, at: 0) // 把新紀錄插在最前面
        saveTrades()
    }
    
    func deleteTrade(id: UUID) {
        trades.removeAll { $0.id == id }
        saveTrades()
    }
    
    // 存檔與讀檔
    private func saveTrades() {
        if let data = try? JSONEncoder().encode(trades) {
            UserDefaults.standard.set(data, forKey: "SavedTrades")
        }
    }
    
    private func loadTrades() {
        if let data = UserDefaults.standard.data(forKey: "SavedTrades"),
           let decoded = try? JSONDecoder().decode([TradeRecord].self, from: data) {
            self.trades = decoded
        }
    }
    
    // MARK: - 統計計算邏輯
    
    // 篩選出「特定股票」的所有紀錄
    func tradesFor(stockCode: String) -> [TradeRecord] {
        return trades.filter { $0.stockCode == stockCode }
    }
    
    // 計算總利潤
    func totalProfit(for stockCode: String) -> Double {
        tradesFor(stockCode: stockCode).reduce(0) { $0 + $1.profit }
    }
    
    // 計算總報酬率
    func totalROI(for stockCode: String) -> Double {
        let totalCost = tradesFor(stockCode: stockCode).reduce(0) { $0 + $1.cost }
        guard totalCost > 0 else { return 0.0 }
        return (totalProfit(for: stockCode) / totalCost) * 100.0
    }
}
