import SwiftUI
import RealmSwift

struct RecipeRow: View {
    var recipe: Recipe
    @EnvironmentObject var state: ContentViewState

    init(_ recipe: Recipe) {
        self.recipe = recipe
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(recipe.name).onTapGesture {
                    self.state.sectionState[self.recipe] = !self.isExpanded(self.recipe)
                }.animation(.interactiveSpring())
                if self.isExpanded(recipe) {
                    ForEach(recipe.ingredients) { ingredient in
                        HStack {
                            URLImage(ingredient.foodType!.imgUrl)
                            Text(ingredient.name!)
                        }.padding(.leading, 5)
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
                    ForEach(Array(self.draftRecipe.ingredients),  id: \.self) { ingredient in
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


final class ContentViewState: ObservableObject {
    @Published var sectionState: [Recipe: Bool] = [:]
}

struct ContentView: View {
    @State private var searchTerm: String = ""
    @State private var showRecipeFormView = false
    @ObservedObject var recipes = Recipes.shared.recipes
    @ObservedObject var state: ContentViewState = ContentViewState()

    var body: some View {
        NavigationView {
            List {
                Section(header:
                    HStack {
                        SearchBar(text: self.$searchTerm)
                            .frame(width: 300, alignment: .leading)
                            .padding(5)
                        NavigationLink(destination: RecipeFormView(showRecipeFormView: self.$showRecipeFormView),
                                       isActive: self.$showRecipeFormView,
                                       label: { Button("add recipe")  {
                                        self.showRecipeFormView = true
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
            return Array(self.recipes)
        } else {
            return Array(self.recipes.filter("name CONTAINS '\(searchTerm)'"))
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
        return ContentView()
    }
}
#endif
