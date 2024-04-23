//
//  ContentView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 13.04.24.
//

import SwiftUI

struct LoginView: View {

    @Environment(\.dismiss) var dismiss

    @State private var username = ""


    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Create a new account"),
                    footer: Text("The username should be unique and you can login with only rembering your username")) {
                    TextField("Username", text: $username)
                    Button("Register", action: registerNewAccount)
                }
                Section(
                    header: Text("Login"),
                    footer: Text("Simply put your username and press login to get started")){
                        TextField("Username", text: $username)
                        Button("Login", action: loginToAccount)
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
            
            //TODO Error handling
            if let error {
                print(error)
                return
            }
            let statusCode = (response as! HTTPURLResponse).statusCode
            if statusCode == 200 {
                print("SUCCESS")
                if let data {
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let decodedData = try decoder.decode(User.self, from: data)
                        let user = decodedData
                        if let id = user.id {
                            print(id)
                            writeToAppStorage(id: id)
                        }
                    } catch {
                        print(error)
                    }
                } else {
                    print("No fetched Data")
                }
            } else {
                print("FAILURE")
            }
        }
        task.resume()
    }


    private func writeToAppStorage(id: UUID) {
        UserDefaults.standard.setValue(id.uuidString, forKey: "userID")
        print(Array(UserDefaults.standard.dictionaryRepresentation()))
        dismiss()
    }

    func loginToAccount() {
        //TODO: Implementation
    }
}

#Preview {
    LoginView()
}
