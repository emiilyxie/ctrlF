//
//  ARViewContainer.swift
//  ctrlF-AR
//
//  Created by Emily Xie on 2/8/25.
//

import SwiftUI
import UIKit

struct ARViewContainer: UIViewControllerRepresentable {
    var selectedObject: String

    func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController()
        arViewController.selectedObject = selectedObject // Pass the selected object
        return arViewController
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {
        // You can update ARViewController here if needed
    }
}


#Preview {
    ARViewContainer(selectedObject: "Laptop")
}
