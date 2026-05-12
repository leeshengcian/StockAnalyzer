import Foundation
import Combine

class StockNetworkManager: ObservableObject {
    
    // 1. 新增這行：讓 UI 可以監聽的股票資料變數
    @Published var stockData: StockInfo?
    @Published var localStockList: [StockTicker] = []
    @Published var historicalPrices: [DailyPrice] = []
    
    var timer: Timer?
    
    func startFetchingRealTimeData(stockNo: String, type: String) {
        fetchRealTimeData(stockNo: stockNo, type: type)
        
        timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            self?.fetchRealTimeData(stockNo: stockNo, type: type)
        }
    }
    
    func stopFetching() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchRealTimeData(stockNo: String, type: String) {
        let urlString = "https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=\(type)_\(stockNo).tw&json=1&delay=0"
        
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(StockResponse.self, from: data)
                
                // 檢查是否有抓到資料
                if let fetchedData = result.msgArray?.first {
                    
                    // 2. 重要修改：因為是更新 UI 相關的變數，必須回到「主執行緒 (Main Thread)」執行
                    DispatchQueue.main.async {
                        self.stockData = fetchedData
                    }
                }
            } catch {
                print("❌ JSON 解析失敗: \(error)")
            }
        }
        task.resume()
    }
    
    func loadLocalStockList() {
            // 1. 尋找打包在 App 內的檔案路徑
            guard let url = Bundle.main.url(forResource: "stock_list", withExtension: "json") else {
                print("❌ 找不到 stock_list.json 檔案")
                return
            }
            
            do {
                // 2. 將檔案內容讀取為 Data
                let data = try Data(contentsOf: url)
                // 3. 解析 JSON
                let decoder = JSONDecoder()
                let decodedList = try decoder.decode([StockTicker].self, from: data)
                
                // 4. 放進我們的變數中更新 UI
                DispatchQueue.main.async {
                    self.localStockList = decodedList
                    print("✅ 成功載入 \(self.localStockList.count) 檔本地股票資料！")
                }
            } catch {
                print("❌ 讀取或解析本地清單失敗: \(error)")
            }
    }
    
    // 從政府開放資料平台同時抓取「上市」與「上櫃」股票清單
    // 從政府開放資料平台同時抓取「全市場 (含 ETF)」清單
    func fetchFullStockListFromGovernment() {
        // 1. 改用「每日收盤行情」API，涵蓋所有交易商品 (股票 + ETF)
        let twseUrlString = "https://openapi.twse.com.tw/v1/exchangeReport/STOCK_DAY_ALL" // 上市
        let tpexUrlString = "https://www.tpex.org.tw/openapi/v1/tpex_mainboard_quotes"   // 上櫃
        
        guard let twseUrl = URL(string: twseUrlString),
              let tpexUrl = URL(string: tpexUrlString) else { return }
        
        print("🌍 開始下載包含 ETF 的全市場清單...")
        
        let group = DispatchGroup()
        var tseList: [StockTicker] = []
        var otcList: [StockTicker] = []
        
        // --- 任務 A：抓取上市 (TWSE) ---
        group.enter()
        URLSession.shared.dataTask(with: twseUrl) { data, response, error in
            defer { group.leave() }
            if let data = data {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        tseList = jsonArray.compactMap { dict in
                            // 萬用欄位解析：自動比對中英文鍵值
                            let code = (dict["Code"] as? String) ?? (dict["公司代號"] as? String)
                            let name = (dict["Name"] as? String) ?? (dict["公司名稱"] as? String)
                            
                            guard let validCode = code, let validName = name else { return nil }
                            return StockTicker(code: validCode, name: validName, type: "tse")
                        }
                    }
                } catch {
                    print("❌ 上市資料解析失敗: \(error)")
                }
            }
        }.resume()
        
        // --- 任務 B：抓取上櫃 (TPEx) ---
        group.enter()
        URLSession.shared.dataTask(with: tpexUrl) { data, response, error in
            defer { group.leave() }
            if let data = data {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        otcList = jsonArray.compactMap { dict in
                            // 萬用欄位解析：涵蓋上櫃各種可能的鍵值名稱
                            let code = (dict["SecuritiesCompanyCode"] as? String) ?? (dict["Code"] as? String) ?? (dict["公司代號"] as? String)
                            let name = (dict["CompanyName"] as? String) ?? (dict["Name"] as? String) ?? (dict["公司名稱"] as? String)
                            
                            guard let validCode = code, let validName = name else { return nil }
                            return StockTicker(code: validCode, name: validName, type: "otc")
                        }
                    }
                } catch {
                    print("❌ 上櫃資料解析失敗: \(error)")
                }
            }
        }.resume()
        
        // --- 3. 等待兩個任務都完成 ---
        group.notify(queue: .main) {
            // 將上市與上櫃的陣列合併
            let combinedList = tseList + otcList
            self.localStockList = combinedList
            
            print("✅ 成功下載並合併了 \(self.localStockList.count) 檔股票與 ETF！")
            
            // 抓完之後，立刻存進手機的置物櫃裡覆蓋舊的名單！
            self.saveToCache(list: combinedList)
        }
    }
    
    // --------------------------------------------------------
        // 新增 1：將陣列轉換為 Data，並存入手機的 UserDefaults
        // --------------------------------------------------------
    private func saveToCache(list: [StockTicker]) {
        do {
            // 使用 JSONEncoder 將 Swift 陣列編碼成二進位資料
            let data = try JSONEncoder().encode(list)
            // 存入 UserDefaults，並給它一個專屬的鑰匙名稱 "CachedStockList"
            UserDefaults.standard.set(data, forKey: "CachedStockList")
            print("💾 成功將 \(list.count) 檔股票存入手機快取！")
        } catch {
            print("❌ 存檔失敗: \(error)")
        }
    }
        
        // --------------------------------------------------------
        // 新增 2：App 啟動時的統一載入入口 (先查快取，沒有才上網抓)
        // --------------------------------------------------------
    func loadStocks() {
        // 1. 拿著鑰匙 "CachedStockList" 去檢查手機置物櫃有沒有東西
        if let cachedData = UserDefaults.standard.data(forKey: "CachedStockList") {
            do {
                // 如果有東西，就把它解碼還原成 [StockTicker] 陣列
                let decodedList = try JSONDecoder().decode([StockTicker].self, from: cachedData)
                self.localStockList = decodedList
                print("⚡️ 瞬間從手機載入快取的 \(self.localStockList.count) 檔股票！")
                
                // 💡 進階技巧：雖然已經瞬間顯示了舊名單，但我們還是可以在「背景」偷偷上網抓一次最新版，確保資料是最新的
                fetchFullStockListFromGovernment()
                
            } catch {
                print("❌ 讀取快取失敗，改為重新上網抓取")
                fetchFullStockListFromGovernment()
            }
        } else {
            // 2. 如果置物櫃是空的（代表使用者是第一次打開 App），就直接上網下載
            print("🌍 手機內沒有快取，準備上網下載...")
            fetchFullStockListFromGovernment()
        }
    }
    
    // 2. 抓取歷史 K 線的函數 (設定抓取最近 3 個月)
    func fetchHistoricalData(stockNo: String, type: String) {
        // Yahoo API 規則：上市股票代碼後加 .TW，上櫃加 .TWO
        let suffix = type == "tse" ? ".TW" : ".TWO"
        let symbol = "\(stockNo)\(suffix)"
        
        // 設定網址：range=3mo 代表抓最近三個月，interval=1d 代表日 K 線
        let urlString = "https://query1.finance.yahoo.com/v8/finance/chart/\(symbol)?range=6mo&interval=1d"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                let yahooData = try decoder.decode(YahooChartResponse.self, from: data)
                
                // 像剝洋蔥一樣把需要的陣列拿出來
                guard let result = yahooData.chart.result?.first,
                      let timestamps = result.timestamp,
                      let quote = result.indicators?.quote?.first,
                      let opens = quote.open,
                      let highs = quote.high,
                      let lows = quote.low,
                      let closes = quote.close else { return }
                
                var parsedPrices: [DailyPrice] = []
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd" // 把時間戳轉換成 05/11 這樣的格式
                
                // 將三個獨立的陣列 (高、低、收) 合併成我們 App 專用的 DailyPrice 陣列
                for i in 0..<timestamps.count {
                    // 確保高、低、收盤價都有數字 (排除停牌日的空資料)
                    if let open = opens[i], let high = highs[i], let low = lows[i], let close = closes[i] {
                        let date = Date(timeIntervalSince1970: TimeInterval(timestamps[i]))
                        let dateString = dateFormatter.string(from: date)
                        
                        let dailyPrice = DailyPrice(date: dateString, open: open, high: high, low: low, close: close)
                        parsedPrices.append(dailyPrice)
                    }
                }
                
                // 切換回主執行緒更新 UI
                DispatchQueue.main.async {
                    self.historicalPrices = parsedPrices
                    print("✅ 成功抓取並解析了 \(self.historicalPrices.count) 天的歷史資料！")
//                    print("🔍 --- Yahoo 歷史資料檢查開始 ---")
//                    // 使用 suffix(5) 只取陣列最後面的 5 筆資料
//                    for price in self.historicalPrices.suffix(5) {
//                        print("📅 日期: \(price.date) | 🔴 收盤: \(String(format: "%.2f", price.close)) | 📈 最高: \(String(format: "%.2f", price.high)) | 📉 最低: \(String(format: "%.2f", price.low))")
//                    }
//                    print("🔍 --- Yahoo 歷史資料檢查結束 ---")
                }
                
            } catch {
                print("❌ 歷史資料解析失敗: \(error)")
            }
        }.resume()
    }
}
