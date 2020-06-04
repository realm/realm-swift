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

import SwiftUI
import RealmSwift

struct RecipeFormView: View {
    let recipes: RealmSwift.List<Recipe>
    @State var showIngredientForm = false
    @State var draftRecipe = Recipe()
    @Binding var showRecipeFormView: Bool

    var body: some View {
        Form {
            Section(header: Text("recipe name")) {
                TextField("recipe name", text: self.$draftRecipe.name)
            }
            Section(header: Text("ingredients")) {
                VStack {
                    ForEach(Array(self.draftRecipe.ingredients), id: \.self) { ingredient in
                        HStack {
                            URLImage(ingredient.foodType!.imgUrl)
                            Text(ingredient.name!)
                        }
                    }
                    Button("add ingredient") {
                        self.showIngredientForm = true
                    }
                }
            }
            Button("save") {
                self.recipes.realm?.beginWrite()
                self.recipes.append(self.draftRecipe)
                try! self.recipes.realm?.commitWrite()
                self.showRecipeFormView = false
            }
        }.navigationBarTitle("make recipe")
            .sheet(isPresented: $showIngredientForm, content: {
                IngredientFormView(recipe: self.$draftRecipe,
                                   showIngredientForm: self.$showIngredientForm)
            })
    }
}

struct RecipeFormViewPreviews: PreviewProvider {
    static var previews: some View {
        RecipeFormView(recipes: RealmSwift.List<Recipe>(), showRecipeFormView: .constant(true))
    }
}
