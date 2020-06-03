////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import RealmSwift

/// An individual ingredient. Part of a `Recipe`.
final class Ingredient: Object, ObjectKeyIdentifable {
    /// The name of the ingredient.
    @objc dynamic var name: String?

    /// The backlink to the `Recipe` this ingredient is a part of.
    let recipes = LinkingObjects(fromType: Recipe.self,
                                 property: "ingredients")

    /// The raw `FoodType` value. Realm cannot store an
    /// `enum` with non-int raw values, so we use a backing property
    /// to work around this.
    @objc dynamic private var _foodType: String = "food"
    var foodType: FoodType? {
        FoodType(rawValue: _foodType)
    }

    /// Convenience initializer for Ingredient.
    /// - parameter name: the name of the ingredient
    /// - parameter foodType: the type of food associated with this ingredient.
    convenience init(name: String, foodType: FoodType) {
        self.init()
        self.name = name
        self._foodType = "\(foodType)"
    }
}
