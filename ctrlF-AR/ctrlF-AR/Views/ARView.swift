//
//  ARView.swift
//  ctrlF-AR
//
//  Created by Emily Xie on 2/8/25.
//

import SwiftUI
import ARKit
import RealityKit

struct ARView: View {
    var selectedObject: String
    @State private var isQRScanned = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ARViewContainer(selectedObject: selectedObject)
                .edgesIgnoringSafeArea(.all) // Full-screen AR view

            VStack {
                Spacer()

                Text("Looking for: \(selectedObject)")
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .foregroundColor(.white)

                Button("Exit AR") {
                    dismiss()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}


#Preview {
    ARView(selectedObject: "Laptop")
}
