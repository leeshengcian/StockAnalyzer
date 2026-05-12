import Foundation

struct BollingerBandsCalculator {
    
    // 狀態列舉：超買(觸碰上軌)、超賣(觸碰下軌)、震盪(通道內)、壓縮(醞釀變盤)
    enum BBStatus {
        case overbought
        case oversold
        case neutral
        case squeeze
    }
    
    // 業界標準參數：20 天，2 倍標準差
    static func calculate(prices: [DailyPrice], period: Int = 20, multiplier: Double = 2.0) -> (upper: Double, middle: Double, lower: Double, bandwidth: Double, advice: String, status: BBStatus)? {
        
        // 確保歷史資料足夠
        guard prices.count >= period else { return nil }
        
        // 取出最近 N 天的收盤價
        let recentPrices = prices.suffix(period).map { $0.close }
        
        // 1. 計算中軌 (N日 SMA)
        let sum = recentPrices.reduce(0, +)
        let middleBand = sum / Double(period)
        
        // 2. 計算標準差 (Standard Deviation)
        // (1) 計算變異數：先算出每個價格與平均值差值的平方和，再除以天數
        let varianceSum = recentPrices.reduce(0) { total, price in
            total + pow(price - middleBand, 2)
        }
        let variance = varianceSum / Double(period)
        // (2) 變異數開根號即為標準差
        let standardDeviation = sqrt(variance)
        
        // 3. 計算上下軌
        let upperBand = middleBand + (multiplier * standardDeviation)
        let lowerBand = middleBand - (multiplier * standardDeviation)
        
        // 4. 計算通道寬度 (帶寬) = (上軌 - 下軌) / 中軌 * 100
        // 帶寬越小，代表波動越小，越可能醞釀大行情
        let bandwidth = ((upperBand - lowerBand) / middleBand) * 100.0
        
        guard let currentClose = prices.last?.close else { return nil }
        
        var advice = ""
        var status: BBStatus = .neutral
        
        // 💡 產生投資建議邏輯
        // 帶寬 < 8% 通常被視為布林壓縮 (實務上可依據個股股性調整)
        if bandwidth < 8.0 {
            advice = "布林通道極度壓縮 (帶寬僅 \(String(format: "%.2f", bandwidth))%)！\n⚠️ 股價正在醞釀波段大行情，請密切留意即將出現的帶量突破方向。"
            status = .squeeze
        } else if currentClose >= upperBand {
            advice = "股價觸碰/突破上軌 ($\(String(format: "%.2f", upperBand)))。\n🔥 短線處於極度強勢的「超買區」，若未帶量易拉回，強勢股則可能沿上軌飆漲。"
            status = .overbought
        } else if currentClose <= lowerBand {
            advice = "股價觸碰/跌破下軌 ($\(String(format: "%.2f", lowerBand)))。\n💧 短線處於極度弱勢的「超賣區」，乖離過大，隨時醞釀跌深反彈。"
            status = .oversold
        } else {
            advice = "股價於通道內震盪。目前中軌位置約為 $\(String(format: "%.2f", middleBand))。\n🔍 可將中軌視為短期多空分水嶺與重要支撐/壓力線。"
            status = .neutral
        }
        
        return (upperBand, middleBand, lowerBand, bandwidth, advice, status)
    }
}
