import Foundation
import Combine

class StockNetworkManager: ObservableObject {
    
    // 1. 新增這行：讓 UI 可以監聽的股票資料變數
    @Published var stockData: StockInfo?
    @Published var localStockList: [StockTicker] = []
    
    var timer: Timer?
    
    func startFetchingRealTimeData(stockNo: String) {
        fetchRealTimeData(stockNo: stockNo)
        timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            self?.fetchRealTimeData(stockNo: stockNo)
        }
    }
    
    func stopFetching() {
        timer?.invalidate()
        timer = nil
    }
    
    private func fetchRealTimeData(stockNo: String) {
        let urlString = "https://mis.twse.com.tw/stock/api/getStockInfo.jsp?ex_ch=tse_\(stockNo).tw&json=1&delay=0"
        
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
        func fetchFullStockListFromGovernment() {
            // 1. 準備好兩個政府 API 的網址
            let twseUrlString = "https://openapi.twse.com.tw/v1/opendata/t187ap03_L"
            let tpexUrlString = "https://www.tpex.org.tw/openapi/v1/mopsfin_t187ap03_O"
            
            guard let twseUrl = URL(string: twseUrlString),
                  let tpexUrl = URL(string: tpexUrlString) else { return }
            
            print("開始從政府網站下載上市與上櫃股票清單...")
            
            // 2. 建立一個 DispatchGroup 來管理多個非同步任務
            let group = DispatchGroup()
            
            // 準備兩個暫存陣列，用來分別存放抓下來的資料 (避免同時寫入同一個陣列發生衝突)
            var tseList: [StockTicker] = []
            var otcList: [StockTicker] = []
            
            // --- 任務 A：抓取上市 (tse) 股票 ---
            group.enter() // 告訴群組：有一個新任務開始了
            URLSession.shared.dataTask(with: twseUrl) { data, response, error in
                defer { group.leave() } // 無論成功或失敗，離開區塊時一定要告訴群組：這個任務結束了
                
                if let data = data {
                    do {
                        let openDataList = try JSONDecoder().decode([OpenDataStock].self, from: data)
                        tseList = openDataList.compactMap { stock in
                                guard let validCode = stock.code, let validName = stock.name else { return nil }
                                return StockTicker(code: validCode, name: validName, type: "tse")
                            }
                    } catch {
                        print("❌ 上市資料解析失敗: \(error)")
                    }
                }
            }.resume()
            
            // --- 任務 B：抓取上櫃 (otc) 股票 ---
            group.enter() // 告訴群組：有第二個新任務開始了
            URLSession.shared.dataTask(with: tpexUrl) { data, response, error in
                defer { group.leave() } // 同樣必須標記任務結束
                
                if let data = data {
                    do {
                        // 放棄嚴格的 Codable，改用靈活的 JSON 字典解析
                        if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                            
                            // 💡 偷看第一筆資料到底長怎樣，印出來確認政府的真實欄位名稱
                            if let firstItem = jsonArray.first {
                                print("🔍 上櫃第一筆資料的真實欄位是：\(firstItem.keys)")
                            }
                            
                            // 靈活抓取：同時支援中文與英文欄位名
                            otcList = jsonArray.compactMap { dict in
                                // 嘗試抓中文，如果抓不到就改抓英文的 SecuritiesCompanyCode
                                let code = (dict["公司代號"] as? String) ?? (dict["SecuritiesCompanyCode"] as? String)
                                let name = (dict["公司名稱"] as? String) ?? (dict["CompanyName"] as? String)
                                
                                guard let validCode = code, let validName = name else { return nil }
                                return StockTicker(code: validCode, name: validName, type: "otc")
                            }
                            print("✅ 成功解析 \(otcList.count) 筆上櫃資料！")
                        }
                    } catch {
                        print("❌ 上櫃資料解析失敗: \(error)")
                    }
                }
            }.resume()
            
            // --- 3. 等待兩個任務都完成 ---
            // group.notify 會一直等，直到上面兩次的 group.enter() 都對應到了 group.leave() 才會執行
            group.notify(queue: .main) {
                // 將上市與上櫃的陣列合併
                let combinedList = tseList + otcList
                self.localStockList = combinedList
                print("✅ 成功從政府網站下載並合併了 \(self.localStockList.count) 檔股票！")
                
                // 👉 新增這行：抓完之後，立刻存進手機的置物櫃裡備份！
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
}
