//
//  ContentView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 13.04.24.
//

import SwiftUI

struct LoginView: View {

    @State private var username = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Create a new account"), footer: Text("The username should be unique and you can login with only rembering your username")) {
                    TextField("Username", text: $username)
                    Button("Register", action: registerNewAccount)
                }
                Section {

                }

            }
            .navigationTitle("Tippspiel Euro 2024")
        }

    }

    func registerNewAccount() {
        let body = "{\"name\": \"\(username)\"}"
        let url = URL(string: "http://localhost:8080/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let data = body.data(using: .utf8)!
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print(body)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let statusCode = (response as! HTTPURLResponse).statusCode

            if statusCode == 200 {
                print("SUCCESS")
            } else {
                print("FAILURE")
            }
        }
        task.resume()
    }
}

#Preview {
    LoginView()
}
