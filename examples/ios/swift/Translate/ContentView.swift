import SwiftUI
import RealmSwift
import AVFoundation

struct LanguageChooseView: View {
    @EnvironmentObject var environment: AppEnvironment

    var state: LanguageState

    var body: some View {
        List {
            ForEach(self.environment.languages.sorted(byKeyPath: "name"), id: \.name) { language in
                Button(language.name, action: {
                    self.environment.language(self.state, language)

                    self.environment.tableOfContents = .translateView
                    self.environment.isShowingLanguageSelectionToPage = false
                    self.environment.isShowingLanguageSelectionFromPage = false
                })
            }
        }.navigationBarTitle("Translate from")
    }
}


enum TableOfContents {
    case translateView
    case selectionView1
    case selectionView2
}

struct NavigationConfigurator: UIViewControllerRepresentable {
    var configure: (UINavigationController) -> Void = { _ in }

    func makeUIViewController(context: UIViewControllerRepresentableContext<NavigationConfigurator>) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<NavigationConfigurator>) {
        if let nc = uiViewController.navigationController {
            self.configure(nc)
        }
    }
}

struct LanguageSelectionStack: View {
    @EnvironmentObject var environment: AppEnvironment
    @State var angle = 0.0

    var body: some View {
        HStack {
            Spacer()

            NavigationLink(
                self.environment.language(.from).name,
                destination: LanguageChooseView(state: .from),
                isActive: self.$environment.isShowingLanguageSelectionFromPage
            ).fixedSize()


            Spacer()

            Button(action: {
                self.angle += 180
                self.environment.swapLanguages()
            }, label: {
                Image(systemName:"arrow.right.arrow.left")
                    .opacity(0.5)
                    .rotationEffect(.degrees(self.angle))
                    .animation(.linear)
            }).fixedSize()

            Spacer()

            NavigationLink(
                self.environment.language(.to).name,
                destination: LanguageChooseView(state: .to),
                isActive: self.$environment.isShowingLanguageSelectionToPage
            ).fixedSize()

            Spacer()
        }
    }
}

struct SpeechLabel: View {
    @EnvironmentObject var appEnvironmentData: AppEnvironment
    @Environment(\.colorScheme) private var colorScheme: ColorScheme

    var language: Language
    @Binding var activeText: String

    var body: some View {
        HStack {
            Button(action: {
                let utterance = AVSpeechUtterance(string: self.activeText)
                utterance.voice = AVSpeechSynthesisVoice(language: self.language.languageCode)
                utterance.rate = 0.5

                let synthesizer = AVSpeechSynthesizer()
                synthesizer.speak(utterance)
            }, label: {
                Image(systemName: "speaker.2.fill")
                    .foregroundColor(colorScheme  == .light ? .black : .white)
                    .opacity(self.activeText == "" ? 0.5 : 1)
            }).disabled(self.activeText == "")

            Text(language.name)
                .font(Font.body.smallCaps())
                .fontWeight(.light)
        }
    }
}

struct TranslationRow: View {
    @EnvironmentObject var environment: AppEnvironment

    @ObservedObject var translation: Translation

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(self.translation.originalText).fontWeight(.bold)
                    .padding(.bottom).padding(.top)
                Text(self.translation.translatedText).fontWeight(.regular)
                    .padding(.bottom)
            }
            Spacer()
            Image(systemName: self.translation.isSaved ? "star.fill" : "star").onTapGesture {
                self.environment.toggleSave(for: self.translation)
            }.foregroundColor(self.translation.isSaved ? .yellow : .black)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var environment: AppEnvironment

    var body: some View {
        return
            TabView {
                NavigationView {
                    VStack(alignment: .leading) {
                        LanguageSelectionStack().padding(.top)

                        Divider()

                        VStack(alignment: .leading) {
                            SpeechLabel(language: self.environment.language(.from),
                                        activeText: self.$environment.textToTranslate)
                                .foregroundColor(.black)
                                .padding(.leading, 27)

                            MultilineTextField("Enter text", text: self.$environment.textToTranslate, onCommit: {
                                self.environment.translate()
                            }).lineLimit(nil)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 25)
                        }

                        Divider()

                        ZStack {
                            VStack(alignment: .leading) {
                                SpeechLabel(language: self.environment.language(.to),
                                            activeText: self.$environment.translatedText)
                                    .environment(\.colorScheme, .dark)
                                HStack {
                                    if self.environment.language(.to).direction == .rightToLeft {
                                        Spacer()
                                    }

                                    Text(self.environment.translatedText)
                                        .lineLimit(nil)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .padding(.top)
                                        .flipsForRightToLeftLayoutDirection(true)
                                        .foregroundColor(Color.white)

                                    if self.environment.language(.to).direction == .leftToRight {
                                        Spacer()
                                    }
                                }
                            }.padding()
                                .padding(.bottom, 10)
                                .background(Color.purple)
                        }.padding(10)

                        List {
                            ForEach(self.environment.translations, id: \.self) { translation in
                                TranslationRow(translation: translation)
                            }
                        }
                        Spacer()
                    }.navigationBarTitle(Text("Realm Translate"), displayMode: .inline)
                    .background(NavigationConfigurator { nc in
                        nc.navigationBar.backgroundColor = .systemPurple
                        nc.navigationBar.barTintColor = .systemPurple
                        nc.navigationBar.titleTextAttributes = [.foregroundColor : UIColor.white]
                    })
                }.navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                NavigationView {
                    List {
                        ForEach(self.environment.savedTranslations, id: \.self) { translation in
                            TranslationRow(translation: translation)
                        }
                    }.navigationBarTitle(Text("Saved"), displayMode: .inline)
                }.tabItem {
                    Image(systemName: "star.fill")
                    Text("Saved")
                }
            }.edgesIgnoringSafeArea(.top)
                .background(Color.purple)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(
            AppEnvironment(
                app: RealmApp("translate-utwuv")))
    }
}
