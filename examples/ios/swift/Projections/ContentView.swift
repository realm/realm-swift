////////////////////////////////////////////////////////////////////////////
 //
 // Copyright 2021 Realm Inc.
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

class Series: Object {
    @Persisted var title: String
    @Persisted var episodes: RealmSwift.List<Movie>
}

class Movie: Object {
    @Persisted var title: String
    @Persisted var episodeNumber: Int
    @Persisted var length: Int
    @Persisted(originProperty: "episodes")
    var series: LinkingObjects<Series>
}

class SeriesModel: Projection<Series> {
    @Projected(\Series.title) var title
    @Projected(\Series.episodes.count) var epCount
    @Projected(\Series.episodes.first?.title.quoted) var firstEpisode
    @Projected(\Series.episodes) var episodes
}

extension String {
    var quoted: String {
        "\"\(self)\""
    }
}

struct SeriesCellView: View {
    @ObservedRealmObject var series: SeriesModel

    var body: some View {
        VStack {
            HStack {
                Text(series.title)
                Text("\(series.epCount) \(series.epCount == 1 ? "episode" : "episodes")")
                    .font(.footnote)
            }
            if let firstTitle = series.firstEpisode, !firstTitle.isEmpty {
                Text("start watch from " + firstTitle)
                    .font(.footnote)
            }
        }
    }
}

struct EpisodeCellView: View {
    @ObservedRealmObject var episode: Movie

    var body: some View {
        Text(episode.title)
            .padding()
    }
}

struct SeriesView: View {
    @ObservedRealmObject var series: SeriesModel
    var body: some View {
        VStack {
            Text("Episodes")
            List($series.episodes) { episode in
                EpisodeCellView(episode: episode.wrappedValue)
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.realm) var realm
    @ObservedResults(SeriesModel.self) var series

    var body: some View {
        NavigationView {
            List {
                ForEach(series) { series in
                    NavigationLink(destination: SeriesView(series: series)) {
                      SeriesCellView(series: series)
                    }
                }
            }
        }
        .navigationTitle("Movies")
        .onAppear(perform: fillData)
    }

    // Add records to display in the view
    func fillData() {
        if realm.objects(Movie.self).count == 0 {
            let sw = Series(value: ["Space Shooter",
                                    [["Revived Beliefs", 4],
                                     ["The Tyrany Evens the Score", 5],
                                     ["Comeback of Magician", 6],
                                     ["The Mirage Hazard", 1],
                                     ["Offence of Siblings", 2],
                                     ["Vendetta of Bad Guys", 3]]])
            try! realm.write {
                realm.add(sw)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
