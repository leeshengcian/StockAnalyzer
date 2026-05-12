import SwiftUI

struct SignalBadge: View {
    let name: String
    let color: Color
    
    var body: some View {
        Text(name)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            // 背景使用同色系的超淡透明色，質感會非常好
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}
