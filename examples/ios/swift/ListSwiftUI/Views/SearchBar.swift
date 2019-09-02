import SwiftUI

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
