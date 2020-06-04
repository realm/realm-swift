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

final class ContentViewState: ObservableObject {
    /// This dict will allow us to store state on the expansion and contraction of rows.
    @Published var sectionState: [Recipe: Bool] = [:]
}

struct ContentView: View {
    @State private var searchTerm: String = ""
    @State private var showRecipeFormView = false
    @ObservedObject var state = ContentViewState()
    @ObservedObject var recipes: RealmSwift.List<Recipe>

    var body: some View {
        NavigationView {
            List {
                Section(header:
                    HStack {
                        SearchBar(text: self.$searchTerm)
                            .frame(width: 300, alignment: .leading)
                            .padding(5)
                        NavigationLink(destination: RecipeFormView(recipes: self.recipes, showRecipeFormView: self.$showRecipeFormView),
                                       isActive: self.$showRecipeFormView,
                                       label: {
                                        Button("add recipe") {
                                            self.showRecipeFormView = true
                                        }
                        })
                }) {
                    ForEach(filteredCollection().freeze()) { recipe in
                        RecipeRow(recipe).environmentObject(self.state)
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                }
            }.listStyle(GroupedListStyle())
                .navigationBarTitle("recipes", displayMode: .large)
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(false)
                .navigationBarItems(trailing: EditButton())
        }
    }

    func filteredCollection() -> AnyRealmCollection<Recipe> {
        if self.searchTerm.isEmpty {
            return AnyRealmCollection(self.recipes)
        } else {
            return AnyRealmCollection(self.recipes.filter("name CONTAINS[c] %@", searchTerm))
        }
    }

    func delete(at offsets: IndexSet) {
        if let realm = recipes.realm {
            try! realm.write {
                realm.delete(recipes[offsets.first!])
            }
        } else {
            recipes.remove(at: offsets.first!)
        }
    }

    func move(fromOffsets offsets: IndexSet, toOffset to: Int) {
        recipes.realm?.beginWrite()
        recipes.move(fromOffsets: offsets, toOffset: to)
        try! recipes.realm?.commitWrite()
    }
}

#if DEBUG
struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        return ContentView(recipes: .init())
    }
}
#endif
