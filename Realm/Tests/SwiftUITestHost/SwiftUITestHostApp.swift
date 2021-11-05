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

struct ReminderRowView: View {
    @ObservedRealmObject var list: ReminderList
    @ObservedRealmObject var reminder: Reminder
    @State var hasFocus: Bool
    @State var showReminderForm = false

    var body: some View {
        NavigationLink(destination: ReminderFormView(list: list,
                                                     reminder: reminder,
                                                     showReminderForm: $showReminderForm), isActive: $showReminderForm) {
            Text(reminder.title)
        }.isDetailLink(true)
    }
}

struct ReminderFormView: View {
    @ObservedRealmObject var list: ReminderList
    @ObservedRealmObject var reminder: Reminder
    @Binding var showReminderForm: Bool

    var body: some View {
        Form {
            TextField("title", text: $reminder.title).accessibility(identifier: "formTitle")
            DatePicker("date", selection: $reminder.date)
            Picker("priority", selection: $reminder.priority, content: {
                ForEach(Reminder.Priority.allCases) { priority in
                    Text(priority.description).tag(priority)
                }
            }).accessibilityIdentifier("picker")
        }
        .navigationTitle(reminder.title)
        .navigationBarItems(trailing: Button("Save") {
            if reminder.realm == nil {
                $list.reminders.append(reminder)
            }
            showReminderForm.toggle()
        }.disabled(reminder.title.isEmpty))
    }
}

struct ReminderListView: View {
    @ObservedRealmObject var list: ReminderList
    @State var newReminderAdded = false
    @State var showReminderForm = false

    func shouldFocusReminder(_ reminder: Reminder) -> Bool {
        return newReminderAdded && list.reminders.last == reminder
    }

    var body: some View {
        VStack {
            List {
                ForEach(list.reminders) { reminder in
                    ReminderRowView(list: list,
                                    reminder: reminder,
                                    hasFocus: shouldFocusReminder(reminder))
                }
                .onMove(perform: $list.reminders.move)
                .onDelete(perform: $list.reminders.remove)
            }
        }.navigationTitle(list.name)
        .navigationBarItems(trailing: HStack {
            EditButton()
            Button("add") {
                newReminderAdded = true
                $list.reminders.append(Reminder())
            }.accessibility(identifier: "addReminder")
        })
    }
}

struct ReminderListRowView: View {
    @ObservedRealmObject var list: ReminderList

    var body: some View {
        HStack {
            Image(systemName: list.icon)
            TextField("List Name", text: $list.name).accessibility(identifier: "listRow")
            Spacer()
            Text("\(list.reminders.count)")
        }.frame(minWidth: 100).accessibility(identifier: "hstack")
    }
}

struct ReminderListResultsView: View {
    @ObservedResults(ReminderList.self) var reminders
    @Binding var searchFilter: String

    var body: some View {
        List {
            ForEach(reminders) { list in
                NavigationLink(destination: ReminderListView(list: list)) {
                    ReminderListRowView(list: list).tag(list)
                }.accessibilityIdentifier(list.name)
            }.onDelete(perform: $reminders.remove)
        }.onChange(of: searchFilter) { value in
            $reminders.filter = value.isEmpty ? nil : NSPredicate(format: "name CONTAINS[c] %@", value)
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
            }.background(RoundedRectangle(cornerRadius: 15)
                            .fill(Color.secondarySystemBackground))
            Spacer()
        }.frame(maxHeight: 40).padding()
    }
}

struct Footer: View {
    @ObservedResults(ReminderList.self) var lists

    var body: some View {
        HStack {
            Button(action: {
                $lists.append(ReminderList())
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

    var body: some View {
        NavigationView {
            VStack {
                SearchView(searchFilter: $searchFilter)
                ReminderListResultsView(searchFilter: $searchFilter)
                Spacer()
                Footer()
            }
            .navigationBarItems(trailing: EditButton())
            .navigationTitle("reminders")
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

enum ViewState {
     case initial
     case pending
     case error(Error)
     case complete
 }

 @available(macOS 12.0, tvOS 15.0, iOS 15.0, watchOS 8.0, *)
 struct FlexibleSyncView: View {
     @ObservedResults(ReminderList.self) var reminders
     @Environment(\.realm) var realm //Realm with flexible sync configuration
     @State var viewState: ViewState = .initial

     var body: some View {
         VStack {
             switch viewState {
             case .initial:
                 EmptyView()
             case .pending:
                 ProgressView()
             case .error(let error):
                 Text("Error on Flexible Sync \(error.localizedDescription)")
             case .complete:
                 List {
                     ForEach(reminders) { reminder in
                         Text("\(reminder.name) list: Has \(reminder.reminders.count) reminders")
                     }
                 }
             }
         }.task {
             do {
                 let subscriptions = realm.subscriptions
                 let task = try await subscriptions.write {
                     try subscriptions.add {
                         Subscription<ReminderList> { reminderList in
                             reminderList.reminders.count > 0
                         }
                     }
                 }

                 // You can get notifications for state changes and trigger UI changes
                 for await state in task.observe() {
                     switch state {
                     case .complete:
                         viewState = .complete
                     case .error(let error):
                         viewState = .error(error)
                     case .pending:
                         viewState = .pending
                     }
                 }
             } catch {
                 viewState = .error(error)
             }
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
            default:
                return AnyView(ContentView())
            }
        }()
        return WindowGroup {
            view
        }
    }
}
