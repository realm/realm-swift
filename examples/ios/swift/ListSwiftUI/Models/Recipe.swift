import Foundation
import RealmSwift
import SwiftUI

final class Recipe: Object {
    @objc dynamic var id: String = UUID.init().uuidString
    @objc dynamic var name: String = ""
    let ingredients = RealmSwift.List<Ingredient>()

    override class func primaryKey() -> String? {
        "id"
    }

    class func new(name: String, ingredients: Ingredient...) -> Recipe {
        let recipe = Recipe()
        recipe.name = name
        recipe.ingredients.append(objectsIn: ingredients)
        return recipe
    }
}

final class Recipes: Object {
    @objc dynamic var id: String = ""
    let recipes = RealmSwift.List<Recipe>()

    static let shared: Recipes = ({
        let realm = try! Realm.init(configuration: .init(deleteRealmIfMigrationNeeded: true))

        guard let uuid = UIDevice.current.identifierForVendor,
            let recipes = realm.object(ofType: Recipes.self, forPrimaryKey: uuid.uuidString) else {
            let recipes = Recipes()
            let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            recipes.id = UIDevice.current.identifierForVendor?.uuidString ?? String((0..<36).map{ _ in letters.randomElement()! })
            try! realm.write {
                realm.add(recipes)
            }
            return recipes
        }

        return recipes
    })()

    override class func primaryKey() -> String? {
        "id"
    }
}
