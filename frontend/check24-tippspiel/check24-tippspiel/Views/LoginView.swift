//
//  ContentView.swift
//  check24-tippspiel
//
//  Created by Simon Bestler on 13.04.24.
//

import SwiftUI

struct LoginView: View {

    @Environment(\.dismiss) var dismiss

    @State private var username_register = ""
    @State private var username_login = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("Create a new account"),
                    footer: Text("The username should be unique and you can login with only rembering your username")) {
                    TextField("Username", text: $username_register)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    Button("Register", action: registerNewAccount)
                }
                Section(
                    header: Text("Login"),
                    footer: Text("Simply put your username and press login to get started")){
                        TextField("Username", text: $username_login)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button("Login", action: loginToAccount)
                    }

            }
            .navigationTitle("Tippspiel Euro 2024")
        }

    }

    func registerNewAccount() {
        let body = "{\"name\": \"\(username_register)\"}"

        var components = Settings.getBaseURLComponents()
        components.path = "/users"

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        let data = body.data(using: .utf8)!
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        print(body)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
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
        dismiss()
    }

    func loginToAccount() {

        var components = Settings.getBaseURLComponents()
        components.path = "/users/validate/\(username_login)"

        let request = URLRequest(url: components.url!)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            var statusCode = 500
            if let response {
                statusCode = (response as! HTTPURLResponse).statusCode
            } else {
                return
            }

            guard statusCode == 200 && data != nil else {
                print("Error with statusCode \(statusCode)")
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let user = try decoder.decode(User.self, from: data!)
                if let id = user.id {
                    writeToAppStorage(id: id)
                }


            } catch {
                print(error)
            }
        }
        task.resume()
    }
}

#Preview {
    LoginView()
}
