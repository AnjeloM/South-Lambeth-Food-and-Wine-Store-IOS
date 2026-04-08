import Foundation

// MARK: - Protocol

public protocol PrintOrderRepositoring {
    func load() -> PrintOrderStorage
    func save(_ storage: PrintOrderStorage)
}

// MARK: - LocalPrintOrderRepository

/// Persists `PrintOrderStorage` to `UserDefaults` as JSON.
/// On first launch (no saved data) returns `DefaultPrintOrderData.storage`.
public final class LocalPrintOrderRepository: PrintOrderRepositoring {

    private let storageKey = "app.printOrderStorage.v1"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> PrintOrderStorage {
        guard
            let data = defaults.data(forKey: storageKey),
            let storage = try? JSONDecoder().decode(PrintOrderStorage.self, from: data)
        else {
            return DefaultPrintOrderData.storage
        }
        return storage
    }

    public func save(_ storage: PrintOrderStorage) {
        guard let data = try? JSONEncoder().encode(storage) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

// MARK: - DefaultPrintOrderData
// Source of truth for the factory-default print order.
// Mirrors the structure of sample_print_list.pdf with numeric prefixes removed.

public enum DefaultPrintOrderData {

    public static let storage: PrintOrderStorage = {
        let list = defaultList
        return PrintOrderStorage(lists: [list], defaultListId: list.id)
    }()

    // MARK: - Default List

    static let defaultList = PrintOrderList(
        name: "Default Print Order",
        nodes: [
            smallCans,
            standardBottles,
            glassBottles,
            energyDrinks,
            largeFormat,
            twoLitreBottles,
            stillWater,
            sparklingWater,
            cartons
        ]
    )

    // MARK: - Section 1 – Small Cans

    private static let smallCans = mainCat("Small Cans", children: [
        subcat("300ml Can", children: [
            group("7up",       items: [("7up Zero Sugar 330ml", 2)]),
            group("Coca Cola", items: [("Coca Cola Zero Sugar 330ml", 2)]),
            group("Dr Pepper", items: [("Dr Pepper 330ml", 2)]),
            group("Fanta",     items: [("Fanta Fruit Twist 330ml", 1), ("Fanta Orange 330ml", 2)]),
            group("Merinda",   items: [("Merinda Strawberry 330ml", 1)]),
            group("Soft Drink",items: [("Mountain Dew 330ml", 1)]),
            group("Tango",     items: [("Tango Apple 330ml", 1)])
        ]),
        subcat("Glass Bottle", children: [
            group("Purdey's", items: [("Purdey's 330ml", 1)])
        ]),
        subcat("Nurishment Cans", children: [
            group("Nurishment", items: [
                ("Nurishment Chocolate 330ml", 2),
                ("Nurishment Vanilla 330ml", 1)
            ])
        ]),
        subcat("Sanpellegrino Cans", children: [
            group("Sanpellegrino", items: [
                ("Sanpellegrino Aranciata Rossa 330ml", 1),
                ("Sanpellegrino Limone & Menta 330ml", 1),
                ("Sanpellegrino Melogreno & Arancia 330ml", 1),
                ("Sanpellegrino Pompelmo 330ml", 1)
            ])
        ])
    ])

    // MARK: - Section 2 – Standard Bottles (500ml)

    private static let standardBottles = mainCat("Standard Bottles", children: [
        subcat("500ml Bottle", children: [
            group("Arizona",  items: [("Arizona Green Tea 500ml", 1)]),
            group("Bigga",    items: [
                ("Bigga Fruit Punch 500ml", 1),
                ("Bigga Grape 500ml", 1),
                ("Bigga Orange 500ml", 1),
                ("Bigga Scream Soda 500ml", 1)
            ]),
            group("Boost",    items: [("Boost 500ml", 2)]),
            group("Coca Cola",items: [
                ("Coca Cola Cherry 500ml", 1),
                ("Coca Cola Diet 500ml", 1),
                ("Coca Cola Original 500ml", 1),
                ("Coca Cola Zero Sugar 500ml", 1)
            ]),
            group("Fanta",    items: [
                ("Fanta Mango 500ml", 1),
                ("Fanta Orange 500ml", 1)
            ]),
            group("KA",       items: [
                ("KA Fruit Punch 500ml", 1),
                ("KA Pineapple 500ml", 1)
            ]),
            group("Lucozade", items: [
                ("Lucozade Orange 500ml", 1),
                ("Lucozade Original 500ml", 1),
                ("Lucozade Pink Lemonade 500ml", 1)
            ]),
            group("Soft Drink", items: [
                ("Aloe Original 500ml", 1),
                ("Dr Pepper 500ml", 1),
                ("Iron-Bru 500ml", 1),
                ("Lipton Peach Tea 500ml", 1),
                ("Lipton Tropical Ice Tea 500ml", 1),
                ("Mogo Mogu Coconut", 1),
                ("Mountain Dew 500ml", 1),
                ("Oasis Citrus Punch 500ml", 1),
                ("Oasis Summer Fruits 500ml", 1),
                ("Ribena Blackcurrant 500ml", 1),
                ("Ribena Strawberry 500ml", 1)
            ])
        ]),
        subcat("Dairy Drinks", children: [
            group("Dairy", items: [
                ("Galaxy 350ml", 1),
                ("Mars 350ml", 1),
                ("Snickers 350ml", 1),
                ("Yazoo Strawberry 400ml", 1),
                ("Yazoo Vanilla 400ml", 1)
            ])
        ]),
        subcat("Sports Cap", children: [
            group("Lucozade", items: [
                ("Lucozade Caribbean Burst 500ml Sports Cap", 1),
                ("Lucozade Ice Kick 500ml Sports Cap", 1)
            ]),
            group("Power EDE", items: [
                ("Power EDE Berry & Tropical Fruit Sports Cap 500ml", 1)
            ])
        ])
    ])

    // MARK: - Section 3 – Glass Bottles

    private static let glassBottles = mainCat("Glass Bottles", children: [
        subcat("Glass Bottle", children: [
            group("Appletiser", items: [("Appletiser 275ml", 2)]),
            group("Snapple", items: [
                ("Snapple Apple 473ml", 1),
                ("Snapple Fruit Punch 473ml", 1),
                ("Snapple Juicy Peachy Iced Tea 473ml", 1),
                ("Snapple Kiwi Meets Strawberry 473ml", 1),
                ("Snapple Mango Madness 473ml", 1),
                ("Snapple Pink Lemonade 473ml", 1)
            ])
        ]),
        subcat("Soft Drinks", children: [
            group("Supermalt",        items: [("Supermalt 330ml", 1)]),
            group("Tropical Rhythms", items: [("Tropical Rhythms Pineapple Ginger 475ml", 1)]),
            group("Tropical Vibes",   items: [("Tropical Vibes Mango Carrot 300ml", 1)])
        ])
    ])

    // MARK: - Section 4 – Energy Drinks

    private static let energyDrinks = mainCat("Energy Drinks", children: [
        subcat("Energy Can", children: [
            group("Boost", items: [
                ("Boost Blue Raspberry 250ml", 1),
                ("Boost Original 500ml", 1),
                ("Boost Sour Cherry 250ml", 1)
            ]),
            group("Monster", items: [
                ("Monster Energy 500ml", 1),
                ("Monster Pacific Punch 500ml", 1),
                ("Monster Pipeline Punch 500ml", 1),
                ("Monster Ultra Paradise 500ml", 1),
                ("Monster VR46 500ml", 1),
                ("Monster Zero Sugar 500ml", 1)
            ]),
            group("Red Bull", items: [
                ("Red Bull Apricot-Strawberry 250ml", 1),
                ("Red Bull Blue Edition 250ml", 1),
                ("Red Bull Original 355ml", 2),
                ("Red Bull Original 473ml", 2),
                ("Red Bull Red Edition 250ml", 1),
                ("Red Bull Sugar Free 250ml", 1),
                ("Red Bull Tropical Edition 250ml", 1)
            ]),
            group("Relentless", items: [("Relentless Original 500ml", 1)]),
            group("Soft Drink", items: [("Tropical Sun Coconut Water 500ml", 1)])
        ])
    ])

    // MARK: - Section 5 – Large Format

    private static let largeFormat = mainCat("Large Format", children: [
        subcat("1L Bottle", children: [
            group("Lucozade",    items: [("Lucozade Orange 1L", 1), ("Lucozade Original 1L", 1)]),
            group("Soft Drinks", items: [("Boost 1L", 2)])
        ]),
        subcat("1.5L Bottle", children: [
            group("Soft Drinks", items: [("Tropical Sun Aloe Vera 1.5L", 1)])
        ]),
        subcat("1.75L Bottle", children: [
            group("Coca Cola", items: [
                ("Coca Cola Cherry 1.75L", 1),
                ("Coca Cola Original 1.75L", 15)
            ])
        ]),
        subcat("600ml", children: [
            group("Soft Drinks", items: [("Ribena 600ml", 1)])
        ]),
        subcat("750ml Bottle", children: [
            group("Soft Drinks", items: [
                ("Robinsons Apple & Blackcurrant 750ml", 1),
                ("Robinsons Summer Fruits 750ml", 1)
            ])
        ])
    ])

    // MARK: - Section 6 – Two Litre Bottles

    private static let twoLitreBottles = mainCat("Two Litre Bottles", children: [
        subcat("2L Bottle", children: [
            group("Coca Cola", items: [
                ("Coca Cola Diet 2L", 1),
                ("Coca Cola Zero Sugar 2L", 2)
            ]),
            group("Fanta", items: [
                ("Fanta Fruit Twist 2L", 1),
                ("Fanta Grape 2L", 1),
                ("Fanta Mango 2L", 1)
            ]),
            group("KA", items: [
                ("KA Black Grape 2L", 1),
                ("KA Fruit Punch 2L", 1),
                ("KA Pineapple 2L", 1)
            ]),
            group("Soft Drinks", items: [
                ("7up 2L", 1),
                ("Dr Pepper 2L", 1),
                ("Fanta Orange 2L", 1),
                ("Rubicon Mango 2L", 1),
                ("Schweppes Slimline Classic Lemonade 2L", 1),
                ("Sprite 2L", 2)
            ])
        ])
    ])

    // MARK: - Section 7 – Still Water

    private static let stillWater = mainCat("Still Water", children: [
        subcat("Water Still", children: [
            group("Water", items: [
                ("Evian 1.5L", 5),
                ("Saka 500ml", 5)
            ])
        ])
    ])

    // MARK: - Section 8 – Sparkling Water

    private static let sparklingWater = mainCat("Sparkling Water", children: [
        subcat("Water", children: [
            group("Water", items: [
                ("Highland Spring Sparkling 1.5L", 2),
                ("Highland Spring Sparkling 500ml", 1),
                ("Perrier 330ml", 1),
                ("Perrier 750ml", 2),
                ("S.Pellegrino Sparkling Water 750ml", 2)
            ])
        ])
    ])

    // MARK: - Section 9 – Cartons

    private static let cartons = mainCat("Cartons", children: [
        subcat("Carton", children: [
            group("Just Juice", items: [("It's Just Juice Apples 1L", 2)]),
            group("KA", items: [
                ("KA Black Grape 1L", 1),
                ("KA Fruit Punch 1L", 1)
            ]),
            group("Ribena",  items: [("Ribena Blackcurrant 1L", 1)]),
            group("Rubicon", items: [
                ("Rubicon Mango 1L", 1),
                ("Rubicon Passion Fruit 1L", 1)
            ]),
            group("Soft Drink", items: [("Vita Coco Coconut Water 1L", 2)]),
            group("Sun Exotic", items: [
                ("Rubicon Tropical 1L", 1),
                ("Sun Exotic Citrus Twist 1L", 1),
                ("Sun Exotic Pineapple & Coconut 1L", 1)
            ]),
            group("Sunpride", items: [
                ("Sunpride Apple 1L", 1),
                ("Sunpride Tropical 1L", 1)
            ]),
            group("Tropical Vibes", items: [("Tropical Vibes Fruit Punch 1L", 1)])
        ])
    ])

    // MARK: - Builder Helpers

    private static func mainCat(_ name: String, children: [PrintOrderNode]) -> PrintOrderNode {
        PrintOrderNode(name: name, level: .mainCategory, children: children)
    }

    private static func subcat(_ name: String, children: [PrintOrderNode]) -> PrintOrderNode {
        PrintOrderNode(name: name, level: .subcategory, children: children)
    }

    private static func group(_ name: String, items: [(String, Int)]) -> PrintOrderNode {
        let leafNodes = items.map { name, qty in
            PrintOrderNode(name: name, level: .item, children: nil, quantity: qty)
        }
        return PrintOrderNode(name: name, level: .group, children: leafNodes)
    }
}
