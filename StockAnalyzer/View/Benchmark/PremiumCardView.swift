import SwiftUI

struct PremiumCardView: View {
    let historicalPrices: [DailyPrice]
    var body: some View {
        // 🔔 策略雷達：開盤溢價率
        VStack(alignment: .leading, spacing: 10) {
            Text("短線當沖策略雷達")
                .font(.headline)
            
            if historicalPrices.isEmpty {
                ProgressView("等待資料...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                if let result = PremiumCalculator.calculate(prices: historicalPrices) {
                    
                    // 根據回傳的警告狀態決定顏色
                    let statusColor: Color = result.isWarning ? .red : .blue
                    
                    HStack {
                        Text("開盤溢價率:")
                        Text("\(String(format: "%.2f", result.rate))%")
                            .fontWeight(.bold)
                            .foregroundColor(result.rate > 0 ? .red : .green) // 台股習慣：正數紅，負數綠
                    }
                    .font(.subheadline)
                    
                    Text(result.advice)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineSpacing(4) // 增加行距讓說明更好讀
                        .foregroundColor(statusColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(8)
                    
                } else {
                    Text("資料不足，無法計算溢價率。")
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
