import SwiftUI
import RealmSwift

final class Ingredient: Object {
    @objc dynamic var name: String? = nil
    let recipes = LinkingObjects(fromType: Recipe.self, property: "ingredients")

    class func new(name: String) -> Ingredient {
        let ingredient = Ingredient()
        ingredient.name = name
        return ingredient
    }
}

final class Recipe: Object {
    @objc dynamic var id = UUID.init().uuidString
    @objc dynamic var name: String? = nil
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

        guard let recipes = realm.object(ofType: Recipes.self, forPrimaryKey: UIDevice.current.identifierForVendor!.uuidString) else {
            let recipes = Recipes()
            recipes.id = UIDevice.current.identifierForVendor!.uuidString
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

struct RecipeRow: View {
    let recipe: Recipe
    @EnvironmentObject var state: ContentViewState

    init(_ recipe: Recipe) {
        print("Initializing RecipeRow")
        self.recipe = recipe
    }

    var body: some View {
        print("constructing recipe row")
        return VStack(alignment: .leading) {
            Text(recipe.name!).onTapGesture {
                self.state.sectionState[self.recipe] = !self.isExpanded(self.recipe)
            }.animation(.interactiveSpring())
            if self.isExpanded(recipe) {
                ForEach(recipe.ingredients) { ingredient in
                    Text("- \(ingredient.name ?? "")").padding(.leading, 5)
                }.animation(.interactiveSpring())
            }
        }
    }

    private func isExpanded(_ section: Recipe) -> Bool {
        self.state.sectionState[section] ?? false
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        ZStack {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("recipe or ingredient", text: $text)
            }.padding()
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(red: 0.9,
                              green: 0.9,
                              blue: 0.9),
                        lineWidth: 3)
        }
    }
}

final class ContentViewState: ObservableObject {
    @Published var sectionState: [Recipe: Bool] = [:]
}

struct ContentView: View {
    @ObservedObject var recipes: RealmSwift.List<Recipe>
    @State private var searchTerm: String = ""
    @State var state: ContentViewState = ContentViewState()

    var body: some View {
        print("count: \(recipes.count)")
        return NavigationView {
            List {
                Section(header:
                    HStack {
                        SearchBar(text: self.$searchTerm)
                        Button("add") {
                            let realm = try! Realm()
                            try! realm.write {
                                self.recipes.append(
                                    Recipe.new(name: "cake",
                                               ingredients: Ingredient.new(name: "sugar")))
                            }
                        }
                }) {
                    ForEach(self.recipes.map { $0 }, id: \.id) { recipe in
                        RecipeRow(recipe).environmentObject(self.state)
                    }.onDelete(perform: self.delete)
            }
        }.listStyle(GroupedListStyle())
                .navigationBarTitle("recipes", displayMode: .large)
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(false)
        }
    }

    func delete(at offsets: IndexSet) {
        print("deleting row \(offsets.first!)")
        try! Realm().write {
            print("write block!")
            recipes.remove(atOffsets: offsets)
            print("done writing")
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //        try! realm.write {
        ////            realm.deleteAll()
        //
        //            let recipe = Recipe()
        //            recipe.name = "cake"
        //            let ig1 = Ingredient()
        //            ig1.name = "sugar"
        //            recipe.ingredients.append(ig1)
        //
        //            realm.add(recipes)
        //
        //            recipes.recipes.append(recipe)
        //        }

        return ContentView(recipes: Recipes.shared.recipes)
    }
}
#endif
