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
import AuthenticationServices
import RealmSwift

/// Your MongoDB Realm App ID
let appId = "your-app-id"

struct ContentView: View {
    @State var accessToken: String = ""
    @State var error: String = ""

    var body: some View {
        VStack {
            SignInWithAppleView(accessToken: $accessToken, error: $error)
                .frame(width: 200, height: 50, alignment: .center)
            Text(self.accessToken)
            Text(self.error)
        }
    }
}

class SignInCoordinator: ASLoginDelegate {
    var parent: SignInWithAppleView
    var app: App

    init(parent: SignInWithAppleView) {
        self.parent = parent
        app = App(id: appId)
        app.authorizationDelegate = self
    }

    @objc func didTapLogin() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        app.setASAuthorizationControllerDelegate(for: authorizationController)
        authorizationController.performRequests()
    }

    func authenticationDidComplete(error: Error) {
        parent.error = error.localizedDescription
    }

    func authenticationDidComplete(user: User) {
        parent.accessToken = user.accessToken ?? "Could not get access token"
    }
}

struct SignInWithAppleView: UIViewRepresentable {
    @Binding var accessToken: String
    @Binding var error: String

    func makeCoordinator() -> SignInCoordinator {
        return SignInCoordinator(parent: self)
    }

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
        button.addTarget(context.coordinator, action: #selector(context.coordinator.didTapLogin), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
