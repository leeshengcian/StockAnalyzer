import Foundation

struct PremiumCalculator {
    
    // 回傳：溢價率、建議文字、是否為警告狀態(用來決定UI顏色)
    static func calculate(prices: [DailyPrice]) -> (rate: Double, advice: String, isWarning: Bool)? {
        
        // 至少需要最近 3 天的資料 (今天、昨天、前天) 才能判斷「昨天的趨勢」
        guard prices.count >= 3 else { return nil }
        
        let today = prices[prices.count - 1]
        let yesterday = prices[prices.count - 2]
        let dayBeforeYesterday = prices[prices.count - 3]
        
        // 1. 計算今日開盤溢價率：(今日開盤 - 昨日收盤) / 昨日收盤 * 100
        let premiumRate = ((today.open - yesterday.close) / yesterday.close) * 100.0
        
        // 2. 計算昨日漲跌幅：(昨日收盤 - 前日收盤) / 前日收盤 * 100
        let yesterdayReturn = ((yesterday.close - dayBeforeYesterday.close) / dayBeforeYesterday.close) * 100.0
        
        var advice = ""
        var isWarning = false
        let rateString = String(format: "%.2f", premiumRate)
        
        // 3. 判斷情境與建議
        if yesterdayReturn >= 9.5 {
            // 情境 A：昨日強勢漲停
            if premiumRate > 7.0 {
                advice = "昨日漲停！今開盤溢價 \(rateString)%。\n💡 策略：若開盤半小時內維持 > 7%，建議【釋出一部分】獲利了結。"
                isWarning = false
            } else if premiumRate > 0 && premiumRate <= 2.0 {
                advice = "昨日漲停，但今開盤溢價僅 \(rateString)%。\n⚠️ 策略：動能明顯衰退，建議【果斷離開】。"
                isWarning = true
            } else if premiumRate < 0 {
                advice = "昨日漲停，今日竟開低 \(rateString)%！\n🚨 策略：買盤無力，建議【直接離開】。"
                isWarning = true
            } else {
                advice = "昨日漲停，今開盤溢價 \(rateString)%。\n🔍 策略：請密切觀察開盤半小時內走勢是否轉弱。"
                isWarning = false
            }
            
        } else if yesterdayReturn < 0 {
            // 情境 B：昨日處於跌勢
            if premiumRate >= -3.0 && premiumRate <= 0 {
                advice = "股價處於跌勢。今開低但未破底 (\(rateString)%)。\n🛡️ 策略：開盤半小時內若未跌破 3%，可能是假摔，可【續抱，等反彈】。"
                isWarning = false
            } else if premiumRate < -3.0 {
                advice = "跌勢持續，且開低超過 3% (\(rateString)%)。\n⚠️ 策略：弱勢未改，破底風險高，請謹慎應對。"
                isWarning = true
            } else {
                advice = "股價處於跌勢，但今日開盤翻紅 (\(rateString)%)。\n🔍 策略：觀察半小時內是否能站穩紅盤醞釀反彈。"
                isWarning = false
            }
            
        } else {
            // 情境 C：一般震盪盤
            advice = "昨日未有極端漲跌，今日開盤溢價率為 \(rateString)%。\n建議搭配 MACD 與威廉指標綜合判斷。"
            isWarning = false
        }
        
        return (premiumRate, advice, isWarning)
    }
}
