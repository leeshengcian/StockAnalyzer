import SwiftUI

struct KDCardView: View {
    let historicalPrices: [DailyPrice]
    
    // KD 最常見的參數是 9 天，我們讓拉桿預設為 9
    @State private var kdPeriod: Double = 9.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KD 隨機指標")
                .font(.headline)
            
            HStack {
                Text("計算天數: \(Int(kdPeriod)) 天")
                Slider(value: $kdPeriod, in: 5...20, step: 1)
            }
            
            if historicalPrices.isEmpty {
                ProgressView("等待歷史資料...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                if let result = KDCalculator.calculate(prices: historicalPrices, period: Int(kdPeriod)) {
                    
                    // 根據 Calculator 回傳的狀態，決定介面的顏色
                    let statusColor: Color = {
                        switch result.status {
                        case .bullish: return .red
                        case .bearish: return .green
                        case .neutral: return .primary
                        }
                    }()
                    
                    // 顯示 K 與 D 的具體數值
                    HStack(spacing: 20) {
                        Text("K: \(String(format: "%.2f", result.k))")
                            .foregroundColor(statusColor)
                        Text("D: \(String(format: "%.2f", result.d))")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .padding(.bottom, 2)
                    
                    // 顯示建議文字
                    Text(result.advice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(statusColor.opacity(0.15)) // 狀態關聯背景色
                        .cornerRadius(8)
                    
                } else {
                    Text("歷史資料不足，無法計算 KD。")
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
