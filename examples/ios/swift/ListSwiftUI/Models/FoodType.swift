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

/// A type of rood associated with an `Ingredient`.
enum FoodType: String, CaseIterable {
    case food, foodTruck, organicFood, noFood, deliverFood, veganFood, foodService, healthyFood, fishFood, naturalFood, vegetarianFood
    case foodAndWine, nonVegetarianFoodSymbol, realFoodForMeals, healthyFoodCaloriesCalculator, mcdonalds, noShellfish, noCelery
    case noNuts, frenchFries, noSoy, spaghetti, ingredients, chiliPepper, cooker, cinnamonRoll, zucchini, steak, tinCan, wrap, potato
    case groceryBag, noApple, milkBottle, leaf, weddingCake, tapas, wheat, rackOfLamb, kawaiiBread, kawaiiEgg, sesame, kawaiiTaco
    case orange, barley, bulog, restaurantBuilding, salami, hotDog, kawaiiSushi, kawaiiCupcake, fridge, cottonCandy, cherry, tomato, picnicTable
    case pizza, hops, watermelon, peanuts, hazelnut, paella, kawaiiFrenchFries, waiter, asparagus, garlic, noLupines
    case melon, paprika, restaurant, protein, toasterOven, fiber, avocado, hamburger, soy, sushi, bento, banana, iceCreamScoop, quesadilla
    case cauliflower, pear, toaster, sprout, spamCan, vendingMachine
    case apple, raspberry, sodium, noodles, kiwi, dairy, celery, halloweenCandy, grass, snail, sashimi, palmTree, weber, corn, carbohydrates
    case plum, eggplant, naan, yearOfGoat, radish, broccoli, cucumber
    case sugarCubes, sugarCube, grill, beet, brezel

    /// A url associated with an icon for a given food type.
    var imgUrl: String {
        String(format: "https://img.icons8.com/color/48/000000/%@.png", self.rawValue.unicodeScalars.reduce("") {
            if CharacterSet.uppercaseLetters.contains($1) {
                return ($0 + "-" + String($1))
            } else {
                return $0 + String($1)
            }
        })
    }
}
