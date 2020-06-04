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

struct RadioGrid<Data, ID, Content>: View, DynamicViewContent where Data: RandomAccessCollection,
    Data.Index == Int, Content: View, ID: Hashable, Data.Element: Equatable {

    private var content: (Data.Element) -> Content
    private var columns: Int

    @Binding var selection: Data.Element?
    var data: Data

    public init(_ data: Data, id: KeyPath<Data.Element, ID>, columns: Int, selection: Binding<Data.Element?>, @ViewBuilder builder: @escaping (Data.Element) -> Content) {
        self.data = data
        self.columns = columns
        self.content = builder
        self._selection = selection
    }

    private func setSelection(_ row: Int, _ column: Int) {
        self.selection = self.data[row * self.columns + column]
    }

    private func radioButton(_ row: Int, _ column: Int) -> RadioButton {
        RadioButton(
            isSelected: selection == self.data[row * self.columns + column])
    }

    var body: some View {
        ForEach(0..<data.count/columns) { (row: Int) in
            HStack {
                Spacer()
                ForEach(0..<self.columns) { column in
                    Spacer()
                    VStack {
                        self.content(self.data[row * self.columns + column])
                        self.radioButton(row, column)
                    }.onTapGesture {
                        self.setSelection(row, column)
                    }
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct RadioButton: View {
    var isSelected: Bool

    var body: some View {
        if !isSelected {
            return AnyView(Circle().strokeBorder().foregroundColor(Color.black)
                .background(Color.clear).frame(width: 20, height: 20))
        } else {
            return AnyView(
                ZStack {
                    Circle().strokeBorder().foregroundColor(Color.black).frame(width: 20, height: 20)
                    Circle().fill(Color.green).foregroundColor(Color.black).frame(width: 8, height: 8)
                }
            )
        }
    }
}

struct IngredientFormView: View {
    @Binding var recipe: Recipe
    @Binding var showIngredientForm: Bool
    @State var ingredientName: String = ""
    @State var selection: FoodType?

    var body: some View {
        Form {
            Section(header: HStack {
                Text("ingredient")
                Spacer()
                Button("save") {
                    self.recipe.ingredients.append(
                        Ingredient(name: self.ingredientName, foodType: self.selection!)
                    )
                    self.ingredientName = ""
                    self.selection = nil
                    self.showIngredientForm = false
                }
            }) {
                TextField("ingredient name", text: self.$ingredientName)
            }
            Section(header: Text("icon")) {
                RadioGrid(FoodType.allCases,
                          id: \.self,
                          columns: 4,
                          selection: $selection) { (foodType: FoodType) in
                            URLImage(foodType.imgUrl)
                }
            }
        }.navigationBarTitle("ingredient").navigationBarItems(trailing: Button("save") {
            self.recipe.ingredients.append(Ingredient(name: self.ingredientName, foodType: self.selection!))
            self.showIngredientForm = false
        }).edgesIgnoringSafeArea(.top)
    }
}

struct IngredientFormViewPreviews: PreviewProvider {
    static var previews: some View {
        IngredientFormView(recipe: .constant(Recipe()), showIngredientForm: .constant(true))
    }
}
