import SwiftUI
import RealmSwift

let appId = "<INSERT-APP-ID>"

class ChatEntry: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id = ObjectId.generate()
    @Persisted var text: String
    @Persisted var user: ChatUser?
    @Persisted(indexed: true) var createdAt: Date

    convenience init(text: String, user: ChatUser) {
        self.init()
        self.text = text
        self.user = user
    }
}

class ChatUser: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: String
    @Persisted var name: String

    convenience init(id: String, name: String) {
        self.init()
        self._id = id
        self.name = name
    }
}

struct ChatEntryView: View {
    var entry: ChatEntry
    var user: ChatUser
    var isContinuation: Bool

    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            VStack(alignment: isCurrentUser ? .trailing : .leading) {
                if !isContinuation { Text(entry.user?.name ?? "<deleted>").font(.footnote).padding(.bottom, 3) }
                Text(entry.text)
                    .foregroundColor(.white)
                    .background(RoundedRectangle(cornerRadius: 5)
                                    .inset(by: -5)
                                    .fill(isCurrentUser ? Color.blue : Color.gray))
            }.padding(3)
            if !isCurrentUser { Spacer() }
        }.frame(maxWidth: .infinity).padding(.bottom, 2).padding(.leading, 2).padding(.trailing, 2)
    }

    var isCurrentUser: Bool {
        user._id == entry.user?._id
    }
}

struct ChatView: View {
    @ObservedResults(ChatEntry.self) var entries
    @State var draftMessage: String = ""
    var chatUser: ChatUser

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { scrollViewReader in
                ScrollView {
                    ForEach(entries) { entry in
                        ChatEntryView(entry: entry,
                                      user: chatUser,
                                      isContinuation: entries.index(of: entry)! > 0 ? entries[entries.index(of: entry)! - 1].user?._id == entry.user?._id : false)
                            .id(entry.id)
                    }.frame(maxWidth: .infinity).padding()
                        .onAppear { scrollViewReader.scrollTo(entries.last?.id) }
                        .onChange(of: entries) { _ in scrollViewReader.scrollTo(entries.last?.id) }
                }
            }
            HStack {
                TextField("small talk", text: $draftMessage).textFieldStyle(.roundedBorder)
                Button(action: {
                    $entries.append(ChatEntry(text: draftMessage, user: chatUser))
                    draftMessage = ""
                }, label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(draftMessage.isEmpty ? .gray : .blue)
                        .imageScale(.large)
                }).disabled(draftMessage.isEmpty).padding()
                Button(action: {
                    Task { try await RealmSwift.App(id: appId).currentUser!.logOut() }
                }, label: {
                    Image(systemName: "arrow.uturn.down.circle")
                        .foregroundColor(.red)
                        .imageScale(.large)
                })
            }
        }
    }
}

struct LoginView: View {
    @State var name: String = ""
    @State var user: ChatUser?
    @ObservedObject var app = RealmSwift.App(id: appId)

    var body: some View {
        if let user = app.currentUser,
           let chatUser = try? Realm(configuration: user.configuration(partitionValue: "chat"))
            .objects(ChatUser.self)
            .first(where: { $0._id == user.id }) {
            ChatView(chatUser: chatUser)
                .environment(\.realmConfiguration, user.configuration(partitionValue: "chat"))
                .environment(\.font, .system(.body, design: .monospaced))
        } else {
            Text("s m a l l   t a l k")
                .font(.system(.headline, design: .monospaced))
                .foregroundStyle(LinearGradient(colors: [.purple, .orange],
                                                startPoint: .bottom, endPoint: .top))
            HStack {
                TextField("name", text: $name).textFieldStyle(.roundedBorder)
                Button(action: {
                    Task {
                        let user = try await app.login(credentials: .anonymous)
                        let realm = try await Realm(configuration: user.configuration(partitionValue: "chat"),
                                                    downloadBeforeOpen: .always)
                        self.user = try realm.write {
                            realm.create(ChatUser.self, value: ChatUser(id: user.id, name: name))
                        }
                        self.name = ""
                    }
                }, label: {
                    Image(systemName: "arrow.uturn.up.circle")
                        .foregroundColor(.green)
                        .imageScale(.large)
                }).padding()
            }.padding()
        }
    }
}

@main
struct SmallTalkApp: SwiftUI.App {
    var body: some Scene { WindowGroup { LoginView() } }
}
