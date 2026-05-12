import Foundation

struct MACDCalculator {
    
    // 回傳：DIF (MACD 線)、DEM (訊號線)、OSC (柱狀圖)、以及投資建議
    static func calculate(prices: [DailyPrice], fast: Int = 12, slow: Int = 26, signal: Int = 9) -> (macd: Double, signalLine: Double, histogram: Double, advice: String)? {
        
        // MACD 至少需要「慢線 + 訊號線」的天數才能算出有意義的最新數值
        guard prices.count > (slow + signal) else { return nil }
        
        let closes = prices.map { $0.close }
        
        // 內部輔助函數：計算 EMA (指數移動平均)
        func getEMA(data: [Double], period: Int) -> [Double] {
            guard data.count >= period else { return [] }
            var ema = [Double](repeating: 0.0, count: data.count)
            let k = 2.0 / Double(period + 1)
            
            // 第一筆 EMA 使用前 period 天的簡單移動平均 (SMA) 作為種子起點
            ema[period - 1] = data.prefix(period).reduce(0, +) / Double(period)
            
            // 往後計算每日 EMA
            for i in period..<data.count {
                ema[i] = (data[i] - ema[i - 1]) * k + ema[i - 1]
            }
            return ema
        }
        
        // 1. 計算快線與慢線的 EMA
        let fastEMA = getEMA(data: closes, period: fast)
        let slowEMA = getEMA(data: closes, period: slow)
        
        // 2. 計算 DIF (MACD 線) = 快線 - 慢線
        var difSeries = [Double](repeating: 0.0, count: closes.count)
        for i in slow..<closes.count {
            difSeries[i] = fastEMA[i] - slowEMA[i]
        }
        
        // 3. 計算 DEM (訊號線) = DIF 的 EMA
        let validDIF = Array(difSeries[slow...]) // 裁切掉前面 0 的無效區段
        let demSeries = getEMA(data: validDIF, period: signal)
        
        // 取得最後一天的最新數據
        guard let lastDIF = validDIF.last,
              let lastDEM = demSeries.last else { return nil }
        
        // 4. 計算 OSC (柱狀圖) = DIF - DEM
        let histogram = lastDIF - lastDEM
        
        // 💡 產生投資建議邏輯 (配合台股習慣：紅色偏多、綠色偏空)
        let advice: String
        if histogram > 0 {
            if lastDIF > 0 {
                advice = "MACD 與訊號線皆在零軸之上，且柱狀圖為紅，屬於「強勢多頭」格局。"
            } else {
                advice = "MACD 於低檔黃金交叉 (柱狀圖轉紅)，具備反彈契機，可伺機佈局。"
            }
        } else {
            if lastDIF < 0 {
                advice = "MACD 與訊號線皆在零軸之下，且柱狀圖為綠，屬於「弱勢空頭」格局。"
            } else {
                advice = "MACD 於高檔死亡交叉 (柱狀圖轉綠)，動能轉弱，留意追高風險。"
            }
        }
        
        return (lastDIF, lastDEM, histogram, advice)
    }
}
