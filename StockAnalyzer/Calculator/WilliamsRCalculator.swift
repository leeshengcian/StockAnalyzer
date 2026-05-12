import Foundation

struct WilliamsRCalculator {
    
    // 根據輸入的歷史資料與天數 (參數)，計算威廉指標並回傳結果與建議
    static func calculate(prices: [DailyPrice], period: Int) -> (value: Double, advice: String)? {
        // 如果歷史資料天數不夠，就無法計算
        guard prices.count >= period else { return nil }
        
        // 取出最近 period 天的資料來計算
        let recentPrices = prices.suffix(period)
        
        // 找出這段期間的最高價與最低價，以及最後一天的收盤價
        guard let highestHigh = recentPrices.max(by: { $0.high < $1.high })?.high,
              let lowestLow = recentPrices.min(by: { $0.low < $1.low })?.low,
              let currentClose = recentPrices.last?.close else {
            return nil
        }
        
        // 避免分母為零導致程式崩潰
        if highestHigh == lowestLow { return nil }
        
        // 💡 威廉指標公式：(最高價 - 當前收盤價) / (最高價 - 最低價) * -100
        let wpr = ((highestHigh - currentClose) / (highestHigh - lowestLow)) * -100.0
        
        // 💡 產生投資建議邏輯
        let advice: String
        let formattedValue = String(format: "%.2f", wpr)
        
        if wpr >= -20 {
            advice = "目前處於「超買」區 (數值: \(formattedValue))，需留意股價可能拉回下跌。"
        } else if wpr <= -80 {
            advice = "目前處於「超賣」區 (數值: \(formattedValue))，可能有醞釀反彈的機會。"
        } else {
            advice = "目前處於「震盪」區 (數值: \(formattedValue))，建議觀望。"
        }
        
        return (wpr, advice)
    }
}
