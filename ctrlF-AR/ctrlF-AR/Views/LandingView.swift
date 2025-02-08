//
//  LandingView.swift
//  ctrlF-AR
//
//  Created by Emily Xie on 2/8/25.
//

import SwiftUI

struct LandingView: View {
    @State private var searchText = ""
    @State private var allItems: [String] = []
    @State private var filteredItems: [String] = []
    @State private var selectedItem: String?

    var body: some View {
        NavigationView {
            VStack() {
                Text("ctrl-F")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .bold()

                Text("find what you're looking for, in real life")
                    .font(.system(size: 16, weight: .light, design: .monospaced))
                    .foregroundColor(.gray)
                    .italic()
                    .multilineTextAlignment(.center)

                TextField("search here...", text: $searchText, onEditingChanged: { _ in
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
            .onAppear {
                fetchObjectList()
            }
        }
        .background(Color("bgColor"))
    }

    private func filterItems() {
        if searchText.isEmpty {
            filteredItems = []
        } else {
            filteredItems = allItems.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    private func fetchObjectList() {
           NetworkService.fetchObjectNames { objectNames in
               DispatchQueue.main.async {
                   self.allItems = objectNames
                   self.filteredItems = objectNames
                   print("📦 Objects fetched: \(objectNames)")
               }
           }
       }
}

#Preview {
    LandingView()
}
