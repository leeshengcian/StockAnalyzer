import Foundation
import Combine

class WatchlistManager: ObservableObject {
    // 使用 Singleton 模式，確保全 App 只有一份清單
    static let shared = WatchlistManager()
    
    // 存放自選股票代碼的集合 (使用 Set 可以避免重複加入)
    @Published var favoriteCodes: Set<String> = [] {
        didSet {
            save() // 每次清單變動就自動存檔
        }
    }
    
    private let saveKey = "UserWatchlist"
    
    init() {
        load()
    }
    
    // 檢查是否已在清單中
    func isFavorite(_ code: String) -> Bool {
        favoriteCodes.contains(code)
    }
    
    // 加入或移除自選
    func toggleFavorite(_ code: String) {
        if favoriteCodes.contains(code) {
            favoriteCodes.remove(code)
        } else {
            favoriteCodes.insert(code)
        }
    }
    
    // 存檔到手機硬碟
    private func save() {
        let array = Array(favoriteCodes)
        UserDefaults.standard.set(array, forKey: saveKey)
    }
    
    // 從手機硬碟讀取
    private func load() {
        if let array = UserDefaults.standard.stringArray(forKey: saveKey) {
            favoriteCodes = Set(array)
        }
    }
}
