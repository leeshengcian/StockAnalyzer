import SwiftUI

enum SidebarOption: String, CaseIterable, Identifiable {
    case search = "台股搜尋"
    case watchlist = "自選清單"
    case settings = "設定"
    
    var id: String { self.rawValue }
    
    // 對應的圖示
    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .watchlist: return "star.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
