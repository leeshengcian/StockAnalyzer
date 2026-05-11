import Foundation

// 最外層的 JSON 結構
struct StockResponse: Codable {
    let msgArray: [StockInfo]? // 證交所把資料包在 msgArray 裡面
}

// 單檔股票的詳細資訊
struct StockInfo: Codable {
    let c: String // 股票代號 (Code)
    let n: String // 公司簡稱 (Name)
    let z: String // 當盤成交價 (Price) - 注意：證交所回傳的是字串，例如 "800.0"
    let v: String // 累積成交量 (Volume)
}

// 用來解析本地 stock_list.json 的資料結構
struct StockTicker: Codable, Identifiable {
    var id: String { code } // 讓 SwiftUI 列表好辨識
    let code: String
    let name: String
    let type: String
}

// 專門用來解析政府 OpenAPI 回傳的 JSON 格式
struct OpenDataStock: Codable {
    let code: String?
    let name: String?
    
    // 將政府的中文 JSON Key 對應到我們的 Swift 變數
    enum CodingKeys: String, CodingKey {
        case code = "公司代號"
        case name = "公司名稱"
    }
}
