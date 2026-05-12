import SwiftUI

struct BIASCardView: View {
    let historicalPrices: [DailyPrice]
    
    // 預設常見的中線參數：20天 (月線)
    @State private var biasPeriod: Double = 20.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BIAS 乖離率指標")
                .font(.headline)
            
            HStack {
                // 自動幫使用者翻譯常見的均線俗稱
                let periodName: String = {
                    switch Int(biasPeriod) {
                    case 5: return " (週線)"
                    case 10: return " (雙週線)"
                    case 20: return " (月線)"
                    case 60: return " (季線)"
                    default: return ""
                    }
                }()
                
                Text("基準均線: \(Int(biasPeriod)) 天\(periodName)")
                Slider(value: $biasPeriod, in: 5...60, step: 1)
            }
            
            if historicalPrices.isEmpty {
                ProgressView("等待歷史資料...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                if let result = BIASCalculator.calculate(prices: historicalPrices, period: Int(biasPeriod)) {
                    
                    // 根據狀態決定介面顏色 (使用立即執行的閉包)
                    let statusColor: Color = {
                        switch result.status {
                        case .overbought: return .red    // 漲太多，紅色警戒
                        case .oversold: return .green    // 跌太深，綠色機會
                        case .bullish: return .red.opacity(0.7)
                        case .bearish: return .green.opacity(0.7)
                        }
                    }()
                    
                    // 顯示乖離率與目前均價
                    HStack(spacing: 20) {
                        Text("乖離率: \(String(format: "%.2f", result.bias))%")
                            .foregroundColor(statusColor)
                        Text("均價: $\(String(format: "%.2f", result.ma))")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.bottom, 2)
                    
                    Text(result.advice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineSpacing(4) // 增加行距，讓兩行文字更好讀
                        .foregroundColor(statusColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(8)
                    
                } else {
                    Text("歷史資料不足 \(Int(biasPeriod)) 天，無法計算。")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2)
    }
}
