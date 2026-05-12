import SwiftUI

struct SidebarMenuView: View {
    @Binding var isMenuOpen: Bool
    @Binding var selectedOption: SidebarOption
    
    var body: some View {
        HStack(spacing: 0) {
            // 選單內容區塊
            VStack(alignment: .leading, spacing: 20) {
                // 標題區
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.red)
                    Text("台股小幫手")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding(.top, 50)
                .padding(.bottom, 30)
                
                // 選項列表
                ForEach(SidebarOption.allCases) { option in
                    Button(action: {
                        selectedOption = option
                        // 點擊後自動關閉選單
                        withAnimation(.spring()) { isMenuOpen = false }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: option.icon)
                                .foregroundColor(selectedOption == option ? .red : .gray)
                                .frame(width: 30)
                            
                            Text(option.rawValue)
                                .foregroundColor(.primary)
                                .fontWeight(selectedOption == option ? .bold : .regular)
                        }
                        .padding(.vertical, 10)
                    }
                }
                
                Spacer()
                
                Text("版本 v1.0.0")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .frame(width: 250) // 選單寬度
            .background(Color(.systemBackground))
            
            // 剩下的透明區域，點擊可用來關閉選單
            if isMenuOpen {
                Color.black.opacity(0.01)
                    .onTapGesture {
                        withAnimation(.spring()) { isMenuOpen = false }
                    }
            }
        }
    }
}
