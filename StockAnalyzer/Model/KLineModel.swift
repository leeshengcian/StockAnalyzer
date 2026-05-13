import Foundation

// 歷史股價的基本模型 (K線)
// 💡 建議加上 Identifiable，這樣在 SwiftUI 的 List 或 ForEach 裡面會更好用
struct DailyPrice: Identifiable {
    let id = UUID() // 讓每一天都有唯一識別碼
    let date: String
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
}

// --- 專門用來解析 Yahoo Finance API 的結構 ---
struct YahooChartResponse: Codable {
    let chart: ChartResult
}

struct ChartResult: Codable {
    let result: [ChartData]?
}

struct ChartData: Codable {
    let timestamp: [Int]?
    let indicators: ChartIndicators?
}

struct ChartIndicators: Codable {
    let quote: [ChartQuote]?
    // 🌟 1. 新增：告訴系統 JSON 裡有一包叫做 adjclose 的資料
    let adjclose: [ChartAdjClose]?
}

struct ChartQuote: Codable {
    // Yahoo 的資料有時候當天停牌會是 null，所以必須宣告成 [Double?]
    let open: [Double?]?
    let high: [Double?]?
    let low: [Double?]?
    let close: [Double?]?
    let volume: [Double?]?
}

// 🌟 2. 新增：用來接住「還原收盤價」的結構
struct ChartAdjClose: Codable {
    let adjclose: [Double?]?
}
