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
    @State private var navigateToAR = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("ctrl-F")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .bold()

                Text("find what you're looking for, in real life")
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(.gray)
                    .italic()
                    .multilineTextAlignment(.center)

                TextField("search here...", text: $searchText, onEditingChanged: { _ in
                    filterItems()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .padding()

                List(filteredItems, id: \.self) { item in
                    Button(action: {
                        selectedItem = item
                        searchText = item
                    }) {
                        Text(item)
                    }
                }
                .frame(height: min(300, CGFloat(filteredItems.count * 44)))
                .background(Color("bgColor"))

                NavigationLink(destination: ARView(selectedObject: selectedItem ?? "")) {
                    Text("Find in AR")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .opacity(selectedItem == nil ? 0.5 : 1.0)  // ✅ Reduce opacity when disabled
                .allowsHitTesting(selectedItem != nil)  // ✅ Prevents tap when no item is selected
            }
            .padding()
            .onAppear {
                fetchObjectList()
            }
            .fullScreenCover(isPresented: $navigateToAR) {
                if let selected = selectedItem {
                    ARView(selectedObject: selected)  // ✅ Ensure it's using ARView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color("bgColor").edgesIgnoringSafeArea(.all))
        }
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
