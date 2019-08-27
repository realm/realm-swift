import SwiftUI
import RealmSwift

final class Ingredient: Object {
    @objc dynamic var name: String? = nil
    let recipes = LinkingObjects(fromType: Recipe.self, property: "ingredients")
    @objc dynamic private var _foodType: String = "food"
    var foodType: FoodType? {
        FoodType(rawValue: _foodType)
    }

    class func new(name: String, foodType: FoodType) -> Ingredient {
        let ingredient = Ingredient()
        ingredient.name = name
        return ingredient
    }
}

final class Recipe: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String? = nil
    let ingredients = RealmSwift.List<Ingredient>()

    override class func primaryKey() -> String? {
        "id"
    }

    class func new(name: String, ingredients: Ingredient...) -> Recipe {
        let recipe = Recipe()
        recipe.name = name
        recipe.ingredients.append(objectsIn: ingredients)
        recipe.id = UUID.init().uuidString
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

struct RecipeRow: View {
    var recipe: Recipe
    @EnvironmentObject var state: ContentViewState

    init(_ recipe: Recipe) {
        self.recipe = recipe
    }

    var body: some View {
        HStack {
        VStack(alignment: .leading) {
            Text(recipe.name!).onTapGesture {
                self.state.sectionState[self.recipe] = !self.isExpanded(self.recipe)
            }.animation(.interactiveSpring())
            if self.isExpanded(recipe) {
                ForEach(recipe.ingredients) { ingredient in
                    Text("- \(ingredient.name ?? "")").padding(.leading, 5)
                }.animation(.interactiveSpring())
            }
        }
            Spacer()
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
                TextField("recipe or ingredient", text: $text).scaledToFill()
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

struct RecipeFormView: View {
    @State var recipeName: String = ""
    @State private var selectedImage = 0
    var ingredients: [Ingredient] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("recipe name")) {
                    TextField("", text: self.$recipeName)
                }
                Section(header: Text("ingredients")) {
                    VStack {
                        ForEach(self.ingredients,  id: \.self) { ingredient in
                            HStack {
                                Image("")
                                Text(ingredient.name!)
                            }
                        }

                        Section {
                            Picker(selection: $selectedImage, label: Text("add ingredient")) {
                                ForEach(0 ..< FoodType.allCases.count) { (idx: Int) in
                                    VStack {
                                        URLImage(FoodType.allCases[idx].imgUrl)
                                        Text(FoodType.allCases[idx].rawValue)
                                    }
                                }
                            }
                        }
                    }
                }
            }.navigationBarTitle("make recipe")
        }
    }
}

struct ContentView: View {
    @ObservedObject var recipes: RealmSwift.List<Recipe>
    @State private var searchTerm: String = ""
    @State var state: ContentViewState = ContentViewState()
    @State var inRecipeFormView: Bool = false

    var body: some View {
        NavigationView {
            List {
                Section(header:
                    HStack {
                        SearchBar(text: self.$searchTerm)
                            .frame(width: 300, alignment: .leading)
                            .padding(5)
                        NavigationLink(destination: RecipeFormView(),
                                       isActive: self.$inRecipeFormView,
                                       label: { Button("add recipe")  {
                            self.inRecipeFormView = true
                                        }})
                }) {
                    ForEach(filteredCollection(), id: \.id) { recipe in
                        RecipeRow(recipe).environmentObject(self.state)
                    }.onDelete(perform: self.delete)
                        .onMove(perform: self.move)

            }
        }.listStyle(GroupedListStyle())
                .navigationBarTitle("recipes", displayMode: .large)
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(false)
                .navigationBarItems(trailing: EditButton())
        }
    }

    func filteredCollection() -> Array<Recipe> {
        if (self.searchTerm.isEmpty) {
            return Array(recipes)
        } else {
            return Array(recipes.filter("name CONTAINS '\(searchTerm)'"))
        }
    }

    func delete(at offsets: IndexSet) {
        try! Realm().write {
            self.recipes.remove(atOffsets: offsets)
        }
    }

    func move(fromOffsets offsets: IndexSet, toOffset offset: Int) {
        try! Realm().write {
            self.recipes.move(from: offsets.first!,
                              to: offset == 0 ? 0 : offset - 1)
        }
    }
    
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        return ContentView(recipes: Recipes.shared.recipes)
    }
}
#endif
