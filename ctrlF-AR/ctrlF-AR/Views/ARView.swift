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

    var body: some View {
        VStack {
            ARViewContainer(selectedObject: selectedObject)
                .edgesIgnoringSafeArea(.all)

            if isQRScanned {
                Text("Object \(selectedObject) found in AR!")
                    .padding()
                    .background(Color.green.opacity(0.7))
                    .cornerRadius(10)
                    .foregroundColor(.white)
            } else {
                Text("Scan the QR Code to find your object.")
                    .padding()
            }

            Button("Exit AR") {
                // Action to exit AR and return to the landing screen
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}


#Preview {
    ARView(selectedObject: "Laptop")
}
