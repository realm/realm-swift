import SwiftUI
import RealmSwift

struct RecipeFormView: View {
    @State var showIngredientForm: Bool = false
    @State var draftRecipe: Recipe = Recipe()
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
                try! Realm().write {
                    Recipes.shared.recipes.append(self.draftRecipe)
                    self.draftRecipe = Recipe()
                }
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
        RecipeFormView(showRecipeFormView: .constant(true))
    }
}
