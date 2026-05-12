import SwiftUI

struct WilliamsRCardView: View {
    // 接收從外部傳進來的歷史資料
    let historicalPrices: [DailyPrice]
    
    // 把拉桿的狀態封裝在這個卡片自己裡面
    @State private var wrPeriod: Double = 14.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("威廉指標 (W%R)")
                .font(.headline)
            
            HStack {
                Text("計算天數: \(Int(wrPeriod)) 天")
                Slider(value: $wrPeriod, in: 5...20, step: 1)
            }
            
            if historicalPrices.isEmpty {
                ProgressView("正在下載歷史 K 線...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                if let result = WilliamsRCalculator.calculate(prices: historicalPrices, period: Int(wrPeriod)) {
                    let statusColor: Color = result.value <= -80 ? .red : (result.value >= -20 ? .green : .primary)
                    
                    Text(result.advice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(8)
                } else {
                    Text("歷史資料不足，無法計算。")
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
