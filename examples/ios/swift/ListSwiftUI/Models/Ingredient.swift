import Foundation
import RealmSwift

final class Ingredient: Object {
    @objc dynamic var name: String? = nil
    let recipes = LinkingObjects(fromType: Recipe.self,
                                 property: "ingredients")
    @objc dynamic private var _foodType: String = "food"

    var foodType: FoodType? {
        FoodType(rawValue: _foodType)
    }

    class func new(name: String, foodType: FoodType) -> Ingredient {
        let ingredient = Ingredient()
        ingredient.name = name
        ingredient._foodType = "\(foodType)"
        return ingredient
    }
}
