import Foundation

struct BIASCalculator {
    
    // 狀態列舉：超買(正乖離過大)、超賣(負乖離過大)、偏多(一般正乖離)、偏空(一般負乖離)
    enum BIASStatus {
        case overbought
        case oversold
        case bullish
        case bearish
    }
    
    static func calculate(prices: [DailyPrice], period: Int) -> (bias: Double, ma: Double, advice: String, status: BIASStatus)? {
        
        // 確保歷史資料足夠計算 N 日的移動平均線 (MA)
        guard prices.count >= period else { return nil }
        
        // 取出最近 N 天的資料
        let recentPrices = prices.suffix(period)
        
        // 計算 N 日簡單移動平均價 (SMA)
        let sum = recentPrices.reduce(0) { $0 + $1.close }
        let ma = sum / Double(period)
        
        // 取得今日收盤價，並確保均線不為 0 (防呆)
        guard let currentClose = prices.last?.close, ma != 0 else { return nil }
        
        // 💡 乖離率公式
        let bias = ((currentClose - ma) / ma) * 100.0
        
        var advice = ""
        var status: BIASStatus = .bullish
        
        let biasString = String(format: "%.2f", bias)
        let maString = String(format: "%.2f", ma)
        
        // 💡 產生投資建議邏輯
        // 這裡設定的閾值 (±7%) 是較為通用的抓轉折標準，實務上會依據天數長短有所不同
        if bias >= 7.0 {
            advice = "正乖離擴大 (\(biasString)%)，股價偏離 \(period)日均線 (\(maString)) 過大。\n⚠️ 隨時有拉回獲利了結的壓力，切勿盲目追高！"
            status = .overbought
        } else if bias <= -7.0 {
            advice = "負乖離擴大 (\(biasString)%)，股價偏離 \(period)日均線 (\(maString)) 過深。\n💡 跌深反彈契機浮現，可留意低接買點。"
            status = .oversold
        } else if bias > 0 {
            advice = "目前為正乖離 (\(biasString)%)，股價運行於 \(period)日均線之上，趨勢偏多。"
            status = .bullish
        } else {
            advice = "目前為負乖離 (\(biasString)%)，股價運行於 \(period)日均線之下，趨勢偏弱。"
            status = .bearish
        }
        
        return (bias, ma, advice, status)
    }
}
