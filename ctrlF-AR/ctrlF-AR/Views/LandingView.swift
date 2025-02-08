//
//  LandingView.swift
//  ctrlF-AR
//
//  Created by Emily Xie on 2/8/25.
//

import SwiftUI

struct LandingView: View {
    @State private var searchText = ""
    @State private var filteredItems: [String] = []
    @State private var allItems = ["Laptop", "Keys", "Bag", "Phone", "Notebook", "Cup", "Bottle"]
    @State private var selectedItem: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Ctrl-F")
                    .font(.largeTitle)
                    .bold()

                Text("What are you looking for (in real life)?")
                    .font(.headline)
                    .foregroundColor(.gray)

                TextField("Search for an object...", text: $searchText, onEditingChanged: { _ in
                    filterItems()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

                List(filteredItems, id: \.self) { item in
                    Button(action: {
                        selectedItem = item
                        searchText = item
                    }) {
                        Text(item)
                    }
                }
                .frame(height: min(200, CGFloat(filteredItems.count * 44)))

                if let selected = selectedItem {
                    NavigationLink(destination: ARView(selectedObject: selected)) {
                        Text("Find in AR")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
    }

    private func filterItems() {
        if searchText.isEmpty {
            filteredItems = []
        } else {
            filteredItems = allItems.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
}

#Preview {
    LandingView()
}
