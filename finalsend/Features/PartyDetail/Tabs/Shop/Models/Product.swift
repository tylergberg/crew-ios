import Foundation

struct Product: Identifiable, Codable {
    let id: String
    let name: String
    let price: Double
    let imageName: String
    let description: String
    
    var displayPrice: String {
        return String(format: "$%.2f", price)
    }
    
    static let sampleProducts: [Product] = [
        Product(
            id: "tshirt",
            name: "Custom T-Shirt",
            price: 29.99,
            imageName: "tshirt-white",
            description: "Custom party t-shirt with your crew's design"
        ),
        Product(
            id: "longsleeve",
            name: "Custom Long Sleeve",
            price: 34.99,
            imageName: "longsleeve-white",
            description: "Custom long sleeve shirt for cooler weather"
        ),
        Product(
            id: "hoodie",
            name: "Custom Hoodies",
            price: 49.99,
            imageName: "hoodie-white",
            description: "Comfortable custom hoodies for the whole crew"
        ),
        Product(
            id: "hat",
            name: "Custom Hats",
            price: 29.99,
            imageName: "hat-white",
            description: "Custom baseball caps with your party theme"
        ),
        Product(
            id: "crewneck",
            name: "Custom Crewnecks",
            price: 49.99,
            imageName: "crewneck-white",
            description: "Classic crewneck sweatshirts with custom design"
        ),
        Product(
            id: "bag",
            name: "Custom Bags",
            price: 19.99,
            imageName: "bag-white",
            description: "Custom tote bags for carrying party essentials"
        )
    ]
}
