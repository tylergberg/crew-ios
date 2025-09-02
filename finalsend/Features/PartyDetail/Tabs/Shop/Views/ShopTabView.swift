import SwiftUI

struct ShopTabView: View {
    let userRole: String
    
    var body: some View {
        ShopProductsView(userRole: userRole)
    }
}

#Preview {
    ShopTabView(userRole: "attendee")
}

