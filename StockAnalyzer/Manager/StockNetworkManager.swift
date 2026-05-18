import Foundation
import Combine

class StockNetworkManager: ObservableObject {
    
    // MARK: - Published Properties (UI 監聽的變數)
    @Published var localStockList: [StockTicker] = []
    @Published var historicalPrices: [DailyPrice] = []
    
    // MARK: - Private State (內部狀態與計時器)
    static var hasFetchedListThisSession = false
    private var refreshTimer: AnyCancellable?
    
    // 判斷：現在是否為台灣股市盤中時間？
    private var isMarketOpen: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let now = Date()
        
        // 判斷星期幾 (1=週日, 7=週六) -> 週末不開盤
        let weekday = calendar.component(.weekday, from: now)
        if weekday == 1 || weekday == 7 { return false }
        
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let timeInMinutes = hour * 60 + minute
        
        // 台股盤中時間：09:00 (540分) ~ 13:30 (810分)
        return timeInMinutes >= 540 && timeInMinutes <= 810
    }
    
    // MARK: - Auto Refresh Logic (自動輪詢機制)
    
    func startAutoRefresh(stockNo: String, type: String) {
        // 進畫面時先手動抓第一次
        fetchHistoricalData(stockNo: stockNo, type: type)
        
        // 為了避免過度消耗 API，設定每 30 秒更新一次
        refreshTimer = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // 只有在盤中時段才發送 API 請求
                if self.isMarketOpen {
                    print("🔄 [盤中] 自動更新 \(stockNo) 數據...")
                    self.fetchHistoricalData(stockNo: stockNo, type: type)
                } else {
                    print("⏸️ [非盤中] \(stockNo) 暫停發送請求。")
                    self.stopAutoRefresh()
                }
            }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.cancel()
        refreshTimer = nil
    }
    
    // MARK: - Stock List Management (市場清單管理)
    
    func loadStocks() {
        // 先查快取，沒有才上網抓
        if let cachedData = UserDefaults.standard.data(forKey: "CachedStockList") {
            do {
                let decodedList = try JSONDecoder().decode([StockTicker].self, from: cachedData)
                self.localStockList = decodedList
                print("⚡️ 瞬間從手機載入快取的 \(self.localStockList.count) 檔股票！")
                
                // 背景靜默更新最新清單
                fetchFullStockListFromGovernment()
            } catch {
                print("❌ 讀取快取失敗，改為重新上網抓取")
                fetchFullStockListFromGovernment()
            }
        } else {
            print("🌍 手機內沒有快取，準備上網下載...")
            fetchFullStockListFromGovernment()
        }
    }
    
    func fetchFullStockListFromGovernment() {
        guard !StockNetworkManager.hasFetchedListThisSession else { return }
        StockNetworkManager.hasFetchedListThisSession = true
        
        let twseUrlString = "https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL" // 上市
        let tpexUrlString = "https://www.tpex.org.tw/openapi/v1/tpex_mainboard_quotes"   // 上櫃
        
        guard let twseUrl = URL(string: twseUrlString),
              let tpexUrl = URL(string: tpexUrlString) else { return }
        
        let group = DispatchGroup()
        var tseList: [StockTicker] = []
        var otcList: [StockTicker] = []
        
        // 抓取上市
        group.enter()
        URLSession.shared.dataTask(with: twseUrl) { data, _, _ in
            defer { group.leave() }
            if let data = data, let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                tseList = jsonArray.compactMap { dict in
                    let code = (dict["Code"] as? String) ?? (dict["公司代號"] as? String)
                    let name = (dict["Name"] as? String) ?? (dict["公司名稱"] as? String)
                    guard let validCode = code, let validName = name else { return nil }
                    return StockTicker(code: validCode, name: validName, type: "tse")
                }
            }
        }.resume()
        
        // 抓取上櫃
        group.enter()
        URLSession.shared.dataTask(with: tpexUrl) { data, _, _ in
            defer { group.leave() }
            if let data = data, let jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                otcList = jsonArray.compactMap { dict in
                    let code = (dict["SecuritiesCompanyCode"] as? String) ?? (dict["Code"] as? String) ?? (dict["公司代號"] as? String)
                    let name = (dict["CompanyName"] as? String) ?? (dict["Name"] as? String) ?? (dict["公司名稱"] as? String)
                    guard let validCode = code, let validName = name else { return nil }
                    return StockTicker(code: validCode, name: validName, type: "otc")
                }
            }
        }.resume()
        
        // 合併並存入快取
        group.notify(queue: .main) {
            let combinedList = tseList + otcList
            self.localStockList = combinedList
            print("✅ 成功下載並合併了 \(self.localStockList.count) 檔股票與 ETF！")
            self.saveToCache(list: combinedList)
        }
    }
    
    private func saveToCache(list: [StockTicker]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: "CachedStockList")
        }
    }
    
    // MARK: - Yahoo Finance Historical Data (K線與指標資料)
    
    func fetchHistoricalData(stockNo: String, type: String) {
        let symbol: String
        if type == "index" {
            symbol = stockNo
        } else {
            let suffix = type == "tse" ? ".TW" : ".TWO"
            symbol = "\(stockNo)\(suffix)"
        }
        
        // 🌟 優化 1：改為抓取 1 年 (1y)，確保 MACD 指標暖機充足
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?range=1y&interval=1d"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            
            do {
                let yahooData = try JSONDecoder().decode(YahooChartResponse.self, from: data)
                
                guard let result = yahooData.chart.result?.first,
                      let timestamps = result.timestamp,
                      let quote = result.indicators?.quote?.first,
                      let opens = quote.open,
                      let highs = quote.high,
                      let lows = quote.low,
                      // 🌟 優化 2：抓取 adjclose (還原權息收盤價)
                      let adjCloses = result.indicators?.adjclose?.first?.adjclose,
                      let volumes = quote.volume else { return }
                
                var parsedPrices: [DailyPrice] = []
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd"
                
                for i in 0..<timestamps.count {
                    // 🌟 確保所有欄位都有值，且改用 adjClose
                    if let open = opens[i], let high = highs[i], let low = lows[i], let adjClose = adjCloses[i], let vol = volumes[i] {
                        let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
                        let dateString = dateFormatter.string(from: date)
                        let volumeInSheets = Double(vol) / 1000.0
                        
                        let dailyPrice = DailyPrice(date: dateString, open: open, high: high, low: low, close: adjClose, volume: volumeInSheets)
                        parsedPrices.append(dailyPrice)
                    }
                }
                
                DispatchQueue.main.async {
                    self.historicalPrices = parsedPrices
                }
                
            } catch {
                print("❌ 歷史資料解析失敗: \(error)")
            }
        }.resume()
    }
}
