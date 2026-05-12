import SwiftUI

struct BollingerBandsCardView: View {
    let historicalPrices: [DailyPrice]
    
    // 預設為業界標準的 20 天 (月線)
    @State private var bbPeriod: Double = 20.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("布林通道 (Bollinger Bands)")
                .font(.headline)
            
            HStack {
                Text("計算天數: \(Int(bbPeriod)) 天 (標準差: 2)")
                Slider(value: $bbPeriod, in: 10...60, step: 1)
            }
            
            if historicalPrices.isEmpty {
                ProgressView("等待歷史資料...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                if let result = BollingerBandsCalculator.calculate(prices: historicalPrices, period: Int(bbPeriod)) {
                    
                    // 根據狀態決定介面顏色
                    let statusColor: Color = {
                        switch result.status {
                        case .overbought: return .red    // 強勢/過熱：紅色
                        case .oversold: return .green    // 弱勢/跌深：綠色
                        case .squeeze: return .orange    // 壓縮警戒：橘色！
                        case .neutral: return .primary   // 震盪：預設顏色
                        }
                    }()
                    
                    // 顯示軌道具體數值
                    HStack(spacing: 12) {
                        Text("上軌: \(String(format: "%.1f", result.upper))")
                        Text("中軌: \(String(format: "%.1f", result.middle))")
                        Text("下軌: \(String(format: "%.1f", result.lower))")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
                    
                    // 投資建議區塊
                    Text(result.advice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .lineSpacing(4)
                        .foregroundColor(statusColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(8)
                    
                } else {
                    Text("歷史資料不足 \(Int(bbPeriod)) 天，無法計算。")
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
