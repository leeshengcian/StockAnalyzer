import Foundation

struct KDCalculator {
    
    // 回傳：K值、D值、建議文字、以及判斷趨勢的狀態標籤 (用來給 UI 決定顏色)
    enum TrendStatus {
        case bullish  // 偏多 (紅色)
        case bearish  // 偏空 (綠色)
        case neutral  // 中性 (灰色)
    }
    
    static func calculate(prices: [DailyPrice], period: Int = 9) -> (k: Double, d: Double, advice: String, status: TrendStatus)? {
        
        // 確保歷史資料天數大於我們需要的計算天數
        guard prices.count >= period else { return nil }
        
        // KD 的初始值業界標準通常設為 50
        var k = 50.0
        var d = 50.0
        
        // 用來記錄「昨天」的 K 和 D，以判斷黃金/死亡交叉
        var prevK = 50.0
        var prevD = 50.0
        
        // 從第 period-1 天開始，一路計算到最後一天(今天)
        for i in (period - 1)..<prices.count {
            // 擷取這 N 天的視窗資料
            let window = prices[(i - period + 1)...i]
            
            // 找出這 N 天內的最高價與最低價
            let highestHigh = window.map { $0.high }.max() ?? 0
            let lowestLow = window.map { $0.low }.min() ?? 0
            let close = prices[i].close
            
            // 計算 RSV
            let rsv: Double
            if highestHigh == lowestLow {
                rsv = 50.0 // 避免分母為 0 (例如遇到連續一字鎖死漲停/跌停)
            } else {
                rsv = ((close - lowestLow) / (highestHigh - lowestLow)) * 100.0
            }
            
            // 紀錄進入今天的運算前，昨天的 KD 值
            prevK = k
            prevD = d
            
            // 計算今日 KD
            k = (2.0 / 3.0) * prevK + (1.0 / 3.0) * rsv
            d = (2.0 / 3.0) * prevD + (1.0 / 3.0) * k
        }
        
        // 💡 產生投資建議邏輯
        var advice = ""
        var status: TrendStatus = .neutral
        
        let kString = String(format: "%.2f", k)
        let dString = String(format: "%.2f", d)
        
        // 1. 先判斷是否發生交叉 (快線穿過慢線)
        let isGoldenCross = prevK <= prevD && k > d
        let isDeathCross = prevK >= prevD && k < d
        
        // 2. 綜合判斷 (交叉優先，再判斷超買/超賣)
        if isGoldenCross && k < 30 {
            advice = "K 值低檔向上突破 D 值，形成「低檔黃金交叉」，強烈買進訊號！"
            status = .bullish
        } else if isGoldenCross {
            advice = "K 值向上突破 D 值，形成「黃金交叉」，趨勢轉強。"
            status = .bullish
        } else if isDeathCross && k > 70 {
            advice = "K 值高檔向下跌破 D 值，形成「高檔死亡交叉」，強烈賣出訊號！"
            status = .bearish
        } else if isDeathCross {
            advice = "K 值向下跌破 D 值，形成「死亡交叉」，趨勢轉弱。"
            status = .bearish
        } else if k > 80 && d > 80 {
            advice = "KD 皆進入 >80 的「超買區」，隨時可能拉回，請留意追高風險。"
            status = .bearish
        } else if k < 20 && d < 20 {
            advice = "KD 皆進入 <20 的「超賣區」，跌勢可能進入尾聲，醞釀反彈。"
            status = .bullish
        } else if k > d {
            advice = "目前 K > D，維持多頭排列 (K: \(kString), D: \(dString))。"
            status = .bullish
        } else {
            advice = "目前 K < D，維持空頭排列 (K: \(kString), D: \(dString))。"
            status = .bearish
        }
        
        return (k, d, advice, status)
    }
}
