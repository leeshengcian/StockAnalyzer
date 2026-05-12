import SwiftUI

struct MACDCardView: View{
    
    let historicalPrices: [DailyPrice]
    // 📈 MACD 指標控制卡片 (接續在威廉指標下方)
    var body: some View{
        VStack(alignment: .leading, spacing: 10) {
            Text("MACD (平滑異同移動平均線)")
                .font(.headline)
            
            HStack {
                Text("計算參數: 12, 26, 9 (系統標準值)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // 檢查歷史資料是否準備好
            if historicalPrices.isEmpty {
                ProgressView("等待歷史資料...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // 呼叫 MACDCalculator
                if let result = MACDCalculator.calculate(prices: historicalPrices) {
                    
                    // 定義狀態顏色：柱狀圖大於 0 顯示紅色(偏多)，小於 0 顯示綠色(偏空)
                    let macdColor: Color = result.histogram > 0 ? .red : .green
                    
                    // 顯示數據細節 (DIF, MACD, OSC)
                    HStack(spacing: 15) {
                        Text("DIF: \(String(format: "%.2f", result.macd))")
                        Text("MACD: \(String(format: "%.2f", result.signalLine))")
                        Text("OSC: \(String(format: "%.2f", result.histogram))")
                            .foregroundColor(macdColor) // 柱狀圖數值特別標色
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
                    
                    // 顯示帶有背景色的投資建議框
                    Text(result.advice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(macdColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(macdColor.opacity(0.15))
                        .cornerRadius(8)
                    
                } else {
                    Text("歷史資料天數不足，無法計算 MACD。")
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
