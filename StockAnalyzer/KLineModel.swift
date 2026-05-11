import Foundation

// 歷史股價的基本模型 (K線)
struct DailyPrice {
    let date: String
    let high: Double
    let low: Double
    let close: Double
}

// --- 新增：專門用來解析 Yahoo Finance API 的結構 ---
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
}

struct ChartQuote: Codable {
    // Yahoo 的資料有時候當天停牌會是 null，所以必須宣告成 [Double?] (有問號)
    let high: [Double?]?
    let low: [Double?]?
    let close: [Double?]?
}
