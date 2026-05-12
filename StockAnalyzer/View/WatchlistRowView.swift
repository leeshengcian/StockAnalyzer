import SwiftUI

struct WatchlistRowView: View {
    let stock: StockTicker
    
    // 🌟 關鍵：每一列都有自己的專屬管理員，獨立抓取資料，互不干擾！
    @StateObject private var networkManager = StockNetworkManager()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 上半部：股票名稱與代碼
            HStack(alignment: .bottom) {
                Text(stock.name).font(.headline)
                Text(stock.code).font(.subheadline).foregroundColor(.gray)
                Spacer()
            }
            
            // 下半部：多空訊號儀表板
            if networkManager.historicalPrices.isEmpty {
                // 資料還沒抓完時，顯示小小的轉圈圈
                HStack {
                    ProgressView().scaleEffect(0.7)
                    Text("分析中...").font(.caption).foregroundColor(.gray)
                }
            } else {
                if networkManager.historicalPrices.count >= 20 {
                    let prices = networkManager.historicalPrices
                    let today = prices[prices.count - 1]
                    let yesterday = prices[prices.count - 2]
                    
                    // 數據準備
                    let yClose = yesterday.close
                    let tOpen = today.open
                    let tClose = today.close // 今收 (現價)
                    
                    // 漲跌幅計算
                    let changePrice = tClose - yClose
                    let isUp = changePrice > 0
                    let changeColor: Color = isUp ? .red : (changePrice < 0 ? .green : .primary)
                    let changeSign = isUp ? "▲" : (changePrice < 0 ? "▼" : "-")
                    
                    // 20日均線計算
                    let recent20 = prices.suffix(20)
                    let ma20 = recent20.reduce(0) { $0 + $1.close } / 20.0
                    
                    // ==========================================
                    // 🌟 新增：計算高度差 (Y軸偏移量)
                    // ==========================================
                    let maxPrice = max(yClose, max(tOpen, tClose))
                    let minPrice = min(yClose, min(tOpen, tClose))
                    // 避免除以零 (如果三天價格都一樣停滯)
                    let priceRange = (maxPrice - minPrice == 0) ? 1.0 : (maxPrice - minPrice)
                    
                    // 設定視覺上最大的上下起伏高度 (例如 16 點)
                    let maxDrop: CGFloat = 16.0
                    
                    // 建立一個計算機：丟入價格，回傳該往上或往下移動多少距離
                    let yOffsetFor: (Double) -> CGFloat = { price in
                        let ratio = (price - minPrice) / priceRange // 算出相對位置 (0.0 ~ 1.0)
                        // SwiftUI 中，Y 往上是負值，所以最高價要回傳負數，最低價要回傳正數
                        return CGFloat(1.0 - ratio) * maxDrop - (maxDrop / 2)
                    }
                    
                    let y1 = yOffsetFor(yClose)
                    let y2 = yOffsetFor(tOpen)
                    let y3 = yOffsetFor(tClose)
                    
                    // 2. 利用三角函數 (atan2) 算出箭頭該旋轉的角度
                    // 假設兩個數字之間的水平間距大約是 45pt
                    let dx: Double = 45.0
                    let angle1 = Angle(radians: atan2(Double(y2 - y1), dx))
                    let angle2 = Angle(radians: atan2(Double(y3 - y2), dx))
                    
                    let invBgColor = colorScheme == .dark ? Color.white : Color.black
                    let invMainTextColor = colorScheme == .dark ? Color.black : Color.white
                    let invSubTextColor = colorScheme == .dark ? Color.gray : Color.gray.opacity(0.8)
                    
                    // ==========================================
                    // 2. 中間層：具備「高度差」的價格流向時間軸
                    // ==========================================
                    HStack(alignment: .center, spacing: 8) {
                        // [昨天收盤]
                        VStack(spacing: 2) {
                            Text("昨收").font(.system(size: 9)).foregroundColor(invSubTextColor)
                            Text(String(format: "%.2f", yClose)).font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(invMainTextColor)
                                .lineLimit(1)                // 👈 1. 強制單行
                                .minimumScaleFactor(0.7)     // 👈 2. 允許字體稍微縮小以塞入空間
                        }
                        .offset(y: y1) // 👈 套用高度差
                        
                        // 🌟 箭頭 1 (昨收 ➔ 今開)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(invMainTextColor.opacity(0.3))
                            .rotationEffect(angle1)       // 旋轉指向目標
                            .offset(y: (y1 + y2) / 2)     // 高度置於兩者正中間
                        
                        // [今日開盤]
                        VStack(spacing: 2) {
                            Text("今開").font(.system(size: 9)).foregroundColor(invSubTextColor)
                            Text(String(format: "%.2f", tOpen))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(tOpen > yClose ? .red : (tOpen < yClose ? .green : invMainTextColor))
                                .lineLimit(1)                // 👈 1. 強制單行
                                .minimumScaleFactor(0.7)     // 👈 2. 允許字體稍微縮小以塞入空間
                        }
                        .offset(y: y2) // 👈 套用高度差
                        
                        // 🌟 箭頭 2 (今開 ➔ 今收)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(invMainTextColor.opacity(0.3))
                            .rotationEffect(angle2)       // 旋轉指向目標
                            .offset(y: (y2 + y3) / 2)     // 高度置於兩者正中間
                        
                        // [今日收盤 / 現價]
                        VStack(spacing: 2) {
                            Text("今收").font(.system(size: 9)).foregroundColor(invSubTextColor)
                            Text(String(format: "%.2f", tClose))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(changePrice > 0 ? .red : (changePrice < 0 ? .green : invMainTextColor))
                                .lineLimit(1)                // 👈 1. 強制單行
                                .minimumScaleFactor(0.7)     // 👈 2. 允許字體稍微縮小以塞入空間
                        }
                        .offset(y: y3) // 👈 套用高度差
                        
                        Spacer()
                        
                        // [今日漲跌幅] 與 [20MA] 並排放在右側
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(changeSign) \(String(format: "%.2f", abs(changePrice)))")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(changePrice > 0 ? .red : (changePrice < 0 ? .green : invMainTextColor))
                                .lineLimit(1)                // 🌟 1. 強制規定只能有一行，絕對不准換行
                                .minimumScaleFactor(0.7)     // 🌟 2. 如果空間不夠，允許字體自動縮小（最多縮到原大小的 70%）
                                .layoutPriority(1)           // 🌟 3. 提高佈局優先限權，警告系統「不要隨便壓縮我的寬度」
                                
                            Text("20MA: \(String(format: "%.2f", ma20))")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                                .lineLimit(1)                // 順便幫 20MA 也加上單行保護
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(.horizontal, 12) // 側邊留白
                    .padding(.vertical, 16)
                    .background(invBgColor)   // 🌟 關鍵：套用相反色背景
                    .cornerRadius(10)          // 圓角讓它像一個鑲嵌在裡面的小螢幕
                    .padding(.vertical, 4)
                }
                // 資料抓完後，顯示一排指標燈號
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        
                        // 1. KD 訊號 (預設 9 天)
                        if let kd = KDCalculator.calculate(prices: networkManager.historicalPrices, period: 9) {
                            let color: Color = kd.status == .bullish ? .red : (kd.status == .bearish ? .green : .gray)
                            SignalBadge(name: "KD", color: color)
                        }
                        
                        // 2. MACD 訊號
                        if let macd = MACDCalculator.calculate(prices: networkManager.historicalPrices) {
                            let color: Color = macd.histogram > 0 ? .red : .green
                            SignalBadge(name: "MACD", color: color)
                        }
                        
                        // 3. 威廉指標 (預設 14 天)
                        if let wr = WilliamsRCalculator.calculate(prices: networkManager.historicalPrices, period: 14) {
                            let color: Color = wr.value <= -80 ? .red : (wr.value >= -20 ? .green : .gray)
                            SignalBadge(name: "W%R", color: color)
                        }
                        
                        // 4. 乖離率 BIAS (預設 20 天)
                        if let bias = BIASCalculator.calculate(prices: networkManager.historicalPrices, period: 20) {
                            // 跌深(<-7%)視為紅燈機會，漲多(>7%)視為綠燈風險
                            let color: Color = bias.bias <= -7.0 ? .red : (bias.bias >= 7.0 ? .green : .gray)
                            SignalBadge(name: "BIAS", color: color)
                        }
                        
                        // 5. 布林通道 (壓縮視為特別提醒橘色)
                        if let bb = BollingerBandsCalculator.calculate(prices: networkManager.historicalPrices) {
                            let color: Color = {
                                switch bb.status {
                                case .oversold: return .red
                                case .overbought: return .green
                                case .squeeze: return .orange
                                case .neutral: return .gray
                                }
                            }()
                            SignalBadge(name: "布林", color: color)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            // 畫面一出現，立刻叫自己的管理員去 Yahoo 抓這檔股票的歷史資料
            networkManager.fetchHistoricalData(stockNo: stock.code, type: stock.type)
        }
    }
}
