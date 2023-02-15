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

import RealmSwift
import SwiftUI

struct ReminderFormView: View {
    @ObservedRealmObject var reminder: Reminder

    var body: some View {
        Form {
            TextField("title", text: $reminder.title).accessibility(identifier: "formTitle")
            DatePicker("date", selection: $reminder.date)
            Picker("priority", selection: $reminder.priority, content: {
                ForEach(Reminder.Priority.allCases) { priority in
                    Text(priority.description)
                        .tag(priority)
                        .accessibilityIdentifier(priority.description)
                }
            }).accessibilityIdentifier("priority_picker")
        }
        .navigationTitle(reminder.title)
    }
}


struct ReminderListView: View {
    @ObservedRealmObject var list: ReminderList
    @State var activeReminder: Reminder.ID?

    var body: some View {
        VStack {
            List {
                ForEach(list.reminders) { reminder in
                    NavigationLink(destination: ReminderFormView(reminder: reminder),
                                   tag: reminder.id, selection: $activeReminder) {
                        Text(reminder.title)
                    }
                }
                .onMove(perform: $list.reminders.move)
                .onDelete(perform: $list.reminders.remove)
            }
        }.navigationTitle(list.name)
        .navigationBarItems(trailing: HStack {
            EditButton()
            Button("add") {
                let reminder = Reminder()
                $list.reminders.append(reminder)
                activeReminder = reminder.id
            }.accessibility(identifier: "addReminder")
        })
    }
}

struct ReminderListResultsView: View {
    // Only receive notifications on "name" to work around what appears to be
    // a SwiftUI bug introduced in iOS 14.5: when we're two levels deep in
    // NagivationLinks, refreshing this view makes the second NavigationLink pop
    @ObservedResults(ReminderList.self, keyPaths: ["name", "icon"]) var reminders
    @Binding var searchFilter: String
    @State var activeList: ReminderList.ID?

    struct Row: View {
        @ObservedRealmObject var list: ReminderList

        var body: some View {
            HStack {
                Image(systemName: list.icon)
                TextField("List Name", text: $list.name)
                Spacer()
                Text("\(list.reminders.count)")
            }.accessibility(identifier: "hstack")
        }
    }

    var body: some View {
        List {
            ForEach(reminders) { list in
                NavigationLink(destination: ReminderListView(list: list), tag: list.id, selection: $activeList) {
                    Row(list: list)
                }.accessibilityIdentifier(list.name).accessibilityActivationPoint(CGPoint(x: 0, y: 0))
            }.onDelete(perform: $reminders.remove)
        }.onChange(of: searchFilter) { value in
            if ProcessInfo.processInfo.environment["query_type"] == "type_safe_query" {
                $reminders.where = value.isEmpty ? nil : { $0.name.contains(value, options: .caseInsensitive) }
            } else {
                $reminders.filter = value.isEmpty ? nil : NSPredicate(format: "name CONTAINS[c] %@", value)
            }
        }
    }
}

public extension Color {
    static let lightText = Color(UIColor.lightText)
    static let darkText = Color(UIColor.darkText)

    static let label = Color(UIColor.label)
    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let tertiaryLabel = Color(UIColor.tertiaryLabel)
    static let quaternaryLabel = Color(UIColor.quaternaryLabel)

    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
}

struct SearchView: View {
    @Binding var searchFilter: String

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                    .padding(.leading, 7)
                    .padding(.top, 7)
                    .padding(.bottom, 7)
                TextField("search", text: $searchFilter)
                    .padding(.top, 7)
                    .padding(.bottom, 7)
                    .accessibility(identifier: "searchField")
            }.background(RoundedRectangle(cornerRadius: 15)
                            .fill(Color.secondarySystemBackground))
            Spacer()
        }.frame(maxHeight: 40).padding()
    }
}

struct Footer: View {
    let realm = try! Realm()

    var body: some View {
        HStack {
            Button(action: {
                try! realm.write {
                    realm.add(ReminderList())
                }
            }, label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add list")
                }
            }).buttonStyle(BorderlessButtonStyle())
            .padding()
            .accessibility(identifier: "addList")
            Spacer()
        }
    }
}

struct ContentView: View {
    @State var searchFilter: String = ""

    var content: some View {
        VStack {
            SearchView(searchFilter: $searchFilter)
            ReminderListResultsView(searchFilter: $searchFilter)
            Spacer()
            Footer()
        }
        .navigationBarItems(trailing: EditButton())
        .navigationTitle("reminders")
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }
}

struct MultiRealmContentView: View {
    struct RealmView: View {
        @Environment(\.realm) var realm
        var body: some View {
            Text(realm.configuration.inMemoryIdentifier ?? "no memory identifier")
                .accessibilityIdentifier("test_text_view")
        }
    }

    @State var showSheet = false

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink("Realm A", destination: RealmView().environment(\.realmConfiguration, Realm.Configuration(inMemoryIdentifier: "realm_a")))
                NavigationLink("Realm B", destination: RealmView().environment(\.realmConfiguration, Realm.Configuration(inMemoryIdentifier: "realm_b")))
                Button("Realm C") {
                    showSheet = true
                }
            }.sheet(isPresented: $showSheet, content: {
                RealmView().environment(\.realmConfiguration, Realm.Configuration(inMemoryIdentifier: "realm_c"))
            })
        }
    }
}

struct UnmanagedObjectTestView: View {
    struct NestedViewOne: View {
        struct NestedViewTwo: View {
            @Environment(\.realm) var realm
            @Environment(\.presentationMode) var presentationMode
            @ObservedRealmObject var reminderList: ReminderList

            var body: some View {
                Button("Delete") {
                    $reminderList.delete()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        @ObservedRealmObject var reminderList: ReminderList
        @Environment(\.presentationMode) var presentationMode
        @State var shown = false
        var body: some View {
            NavigationLink("Next", destination: NestedViewTwo(reminderList: reminderList)).onAppear {
                if shown {
                    presentationMode.wrappedValue.dismiss()
                }
                shown = true
            }
        }
    }
    @ObservedRealmObject var reminderList = ReminderList()
    @Environment(\.realm) var realm
    @State var passToNestedView = false

    var body: some View {
        NavigationView {
            Form {
                TextField("name", text: $reminderList.name).accessibilityIdentifier("name")
                NavigationLink("test", destination: NestedViewOne(reminderList: reminderList), isActive: $passToNestedView)
            }.navigationBarItems(trailing: Button("Add", action: {
                try! realm.write { realm.add(reminderList) }
                passToNestedView = true
            }).accessibility(identifier: "addReminder"))
        }.onAppear {
            print("ReminderList: \(reminderList)")
        }
    }
}

struct ObservedResultsKeyPathTestView: View {
    @ObservedResults(ReminderList.self, keyPaths: ["reminders.isFlagged"]) var reminders

    var body: some View {
        VStack {
            List {
                ForEach(reminders) { list in
                    ObservedResultsKeyPathTestRow(list: list)
                }.onDelete(perform: $reminders.remove)
            }
            .navigationBarItems(trailing: EditButton())
            .navigationTitle("reminders")
            Footer()
        }
    }
}

struct ObservedResultsKeyPathTestRow: View {
    var list: ReminderList

    var body: some View {
        HStack {
            Image(systemName: list.icon)
            Text(list.name)
        }.frame(minWidth: 100).accessibility(identifier: "hstack")
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ObservedResultsSearchableTestView: View {
    @ObservedResults(ReminderList.self, where: { $0.name.starts(with: "reminder") }) var reminders
    @State var searchFilter: String = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(reminders) { reminder in
                    Text(reminder.name)
                }
            }
            .searchable(text: $searchFilter,
                        collection: $reminders,
                        keyPath: \.name) {
                ForEach(reminders) { remindersFiltered in
                    Text(remindersFiltered.name).searchCompletion(remindersFiltered.name)
                }
            }
            .navigationTitle("Reminders")
            .navigationBarItems(trailing:
                Button("add") {
                    let reminder = ReminderList()
                    $reminders.append(reminder)
                }.accessibility(identifier: "addList"))
        }
    }
}

struct ObservedResultsConfiguration: View {
    @ObservedResults(ReminderList.self) var remindersA // config from `.environment`
    @ObservedResults(ReminderList.self,
                     configuration: Realm.Configuration(inMemoryIdentifier: "realm_b")) var remindersB

    var body: some View {
        NavigationView {
            VStack {
                Text(remindersA.realm?.configuration.inMemoryIdentifier ?? "no memory identifier")
                    .accessibility(identifier: "realm_a_label")
                Text(remindersB.realm?.configuration.inMemoryIdentifier ?? "no memory identifier")
                    .accessibility(identifier: "realm_b_label")
                List {
                    ForEach(remindersA) { reminder in
                        Text(reminder.name)
                    }
                }.accessibility(identifier: "ListA")
                List {
                    ForEach(remindersB) { reminder in
                        Text(reminder.name)
                    }
                }.accessibility(identifier: "ListB")
            }
            .navigationTitle("Reminders")
            .navigationBarItems(leading:
                Button("add A") {
                    let reminder = ReminderList()
                    $remindersA.append(reminder)
                }.accessibility(identifier: "addListA")
            )
            .navigationBarItems(trailing:
                Button("add B") {
                    let reminder = ReminderList()
                    $remindersB.append(reminder)
                }.accessibility(identifier: "addListB")
            )
        }
    }
}

struct ObservedSectionedResultsKeyPathTestView: View {
    @ObservedSectionedResults(ReminderList.self,
                              sectionKeyPath: \.firstLetter,
                              keyPaths: ["reminders.isFlagged"]) var reminders

    var body: some View {
        VStack {
            List {
                ForEach(reminders) { section in
                    Section(header: Text(section.key)) {
                        ForEach(section) { object in
                            ObservedResultsKeyPathTestRow(list: object)
                        }
                    }
                }
            }
            .navigationBarItems(trailing: EditButton())
            .navigationTitle("reminders")
            Footer()
        }
    }
}

// swiftlint:disable:next type_name
struct ObservedSectionedResultsWithSortDescriptorsView: View {
    @ObservedSectionedResults(ReminderList.self,
                              sectionBlock: { $0.name.first.map(String.init(_:)) ?? "" },
                              sortDescriptors: [SortDescriptor(keyPath: \ReminderList.name)],
                              keyPaths: ["reminders.isFlagged"]) var reminders

    var body: some View {
        VStack {
            List {
                ForEach(reminders) { section in
                    Section(header: Text(section.key)) {
                        ForEach(section) { object in
                            ObservedResultsKeyPathTestRow(list: object)
                        }
                    }
                }
            }
            .navigationBarItems(trailing: EditButton())
            .navigationTitle("reminders")
            Footer()
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// swiftlint:disable:next type_name
struct ObservedSectionedResultsSearchableTestView: View {
    @ObservedSectionedResults(ReminderList.self,
                              sectionKeyPath: \.firstLetter,
                              where: { $0.name.starts(with: "reminder") }) var reminders
    @State var searchFilter: String = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(reminders) { section in
                    Section(section.key) {
                        ForEach(section) { object in
                            Text(object.name)
                        }
                    }
                }
            }
            .searchable(text: $searchFilter,
                        collection: $reminders,
                        keyPath: \.name) {
                ForEach(reminders) { section in
                    Section(section.key) {
                        ForEach(section) { objectsFiltered in
                            Text(objectsFiltered.name).searchCompletion(objectsFiltered.name)
                        }
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarItems(trailing:
                Button("add") {
                let realm = $reminders.wrappedValue.realm
                try! realm?.write {
                    realm?.add(ReminderList())
                }
                }.accessibility(identifier: "addList"))
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ObservedSectionedResultsConfiguration: View {
    @ObservedSectionedResults(ReminderList.self, sectionKeyPath: \.firstLetter) var remindersA // config from `.environment`
    @ObservedSectionedResults(ReminderList.self,
                              sectionKeyPath: \.firstLetter,
                              configuration: Realm.Configuration(inMemoryIdentifier: "realm_b")) var remindersB

    var body: some View {
        NavigationView {
            VStack {
                Text(remindersA.realm?.configuration.inMemoryIdentifier ?? "no memory identifier")
                    .accessibility(identifier: "realm_a_label")
                Text(remindersB.realm?.configuration.inMemoryIdentifier ?? "no memory identifier")
                    .accessibility(identifier: "realm_b_label")
                List {
                    ForEach(remindersA) { reminderSection in
                        Section(reminderSection.key) {
                            ForEach(reminderSection) { object in
                                Text(object.name)
                            }
                        }
                    }
                }.accessibility(identifier: "ListA")
                List {
                    ForEach(remindersB) { reminderSection in
                        Section(reminderSection.key) {
                            ForEach(reminderSection) { object in
                                Text(object.name)
                            }
                        }
                    }
                }.accessibility(identifier: "ListB")
            }
            .navigationTitle("Reminders")
            .navigationBarItems(leading:
                Button("add A") {
                    let realm = $remindersA.wrappedValue.realm
                    try! realm?.write {
                        realm?.add(ReminderList())
                    }
                }.accessibility(identifier: "addListA")
            )
            .navigationBarItems(trailing:
                Button("add B") {
                    let realm = $remindersB.wrappedValue.realm
                    try! realm?.write {
                        realm?.add(ReminderList())
                    }
                }.accessibility(identifier: "addListB")
            )
        }
    }
}


@main
struct App: SwiftUI.App {
    var body: some Scene {
        if let realmPath = ProcessInfo.processInfo.environment["REALM_PATH"] {
            Realm.Configuration.defaultConfiguration =
                Realm.Configuration(fileURL: URL(string: realmPath)!, deleteRealmIfMigrationNeeded: true)
        } else {
            Realm.Configuration.defaultConfiguration =
                Realm.Configuration(deleteRealmIfMigrationNeeded: true)
        }
        let view: AnyView = {
            switch ProcessInfo.processInfo.environment["test_type"] {
            case "multi_realm_test":
                return AnyView(MultiRealmContentView())
            case "unmanaged_object_test":
                return AnyView(UnmanagedObjectTestView())
            case "observed_results_key_path":
                return AnyView(ObservedResultsKeyPathTestView())
            case "observed_results_searchable":
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    return AnyView(ObservedResultsSearchableTestView())
                } else {
                    return AnyView(EmptyView())
                }
            case "observed_results_configuration":
                return AnyView(ObservedResultsConfiguration()
                                .environment(\.realmConfiguration, Realm.Configuration(inMemoryIdentifier: "realm_a")))
            case "observed_sectioned_results_key_path":
                return AnyView(ObservedSectionedResultsKeyPathTestView())
            case "observed_sectioned_results_sort_descriptors":
                return AnyView(ObservedSectionedResultsWithSortDescriptorsView())
            case "observed_sectioned_results_searchable":
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    return AnyView(ObservedSectionedResultsSearchableTestView())
                } else {
                    return AnyView(EmptyView())
                }
            case "observed_sectioned_results_configuration":
                if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
                    return AnyView(ObservedSectionedResultsConfiguration()
                                    .environment(\.realmConfiguration, Realm.Configuration(inMemoryIdentifier: "realm_a")))
                } else {
                    return AnyView(EmptyView())
                }
            default:
                return AnyView(ContentView())
            }
        }()
        return WindowGroup {
            view
        }
    }
}
