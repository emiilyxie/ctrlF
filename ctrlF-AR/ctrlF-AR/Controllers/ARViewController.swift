//
//  ARViewController.swift
//  ctrlF-AR
//
//  Created by Emily Xie on 2/8/25.
//

import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate {
    var selectedObject: String? // Store selected object from search

    var sceneView: ARSCNView!
    var storedFixedCameraPosition: SCNVector3?
    var fetchedObjects: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize AR scene
        sceneView = ARSCNView(frame: self.view.bounds)
        sceneView.delegate = self
        self.view.addSubview(sceneView)

        setupARSession()
        fetchObjectPositions()
    }

    private func setupARSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.session.run(configuration)
    }

    private func fetchObjectPositions() {
        NetworkService.fetchObjects { objects in
            DispatchQueue.main.async {
                self.fetchedObjects = objects
                print("elx", objects)
                print("📦 Objects fetched and stored.")
            }
        }
    }

    func storeFixedCameraPosition(_ position: SCNVector3?) {
        if let pos = position {
            storedFixedCameraPosition = pos
            print("📍 Fixed Camera Position Stored: \(pos)")

            if !fetchedObjects.isEmpty {
                placeObjects()
            }
        }
    }

    func placeObjects() {
        guard let cameraPosition = storedFixedCameraPosition else { return }
//        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in node.removeFromParentNode() }
        
        for object in fetchedObjects {
            if let name = object["name"] as? String,
               let x = object["x"] as? Double,
               let y = object["y"] as? Double,
               let z = object["z"] as? Double,
               name.lowercased() == selectedObject?.lowercased() { // Only place the selected object

                let worldPosition = SCNVector3(
                    cameraPosition.x + Float(x),
                    cameraPosition.y + Float(y),
                    cameraPosition.z + Float(z)
                )

                addMarker(at: worldPosition, with: name)
            }
        }
    }

    func addMarker(at position: SCNVector3, with label: String) {
        if let existingNode = sceneView.scene.rootNode.childNode(withName: label, recursively: true) {
            existingNode.position = position  // Update position instead of re-adding
            print("✅ Updated existing node: \(label) to \(position)")
            
            if let textNode = sceneView.scene.rootNode.childNode(withName: "\(label)_text", recursively: true) {
                        textNode.position = SCNVector3(position.x, position.y + 0.2, position.z)  // Update text position
                    print("✅ Updated text node for: \(label)")
                }
            return
        }
        
        let sphere = SCNSphere(radius: 0.05)
        sphere.firstMaterial?.diffuse.contents = UIColor.red
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        sphereNode.name = label

        let textGeometry = SCNText(string: label, extrusionDepth: 0.1)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        textNode.position = SCNVector3(position.x, position.y + 0.2, position.z)
        textNode.constraints = [SCNBillboardConstraint()]
        textNode.name = "\(label)_text"

        sceneView.scene.rootNode.addChildNode(sphereNode)
        sceneView.scene.rootNode.addChildNode(textNode)
    }

    // 📌 ✅ **NEW: Process Camera Frames for QR Code Detection**
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else { return }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, options: [:])

        do {
            try imageRequestHandler.perform([VNDetectBarcodesRequest { request, error in
                guard let results = request.results as? [VNBarcodeObservation] else { return }

                for result in results {
                    if let payload = result.payloadStringValue, payload == "ctrlF_app" {
                        DispatchQueue.main.async {
                            print("✅ QR Code Detected!")
                            let qrPosition = self.getQRCodeWorldPosition(result.boundingBox.origin)
                            self.storeFixedCameraPosition(qrPosition)
                        }
                    }
                }
            }])
        } catch {
            print("❌ Error detecting QR Code: \(error.localizedDescription)")
        }
    }

    // Convert QR Code position into ARKit world coordinates
    func getQRCodeWorldPosition(_ screenPoint: CGPoint) -> SCNVector3? {
        guard let query = sceneView.raycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .any) else {
            print("❌ Raycast query failed.")
            return nil
        }

        let results = sceneView.session.raycast(query)
        if let firstResult = results.first {
            let transform = firstResult.worldTransform
            return SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        }

        print("❌ No raycast results, trying feature points...")
        return nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("🔄 Restarting AR session")

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])  // Reset on re-entry
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        print("🗑 Clearing AR scene before exit")
//        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
//            node.removeFromParentNode()
//        }

        print("⏹ Stopping AR session")
        sceneView.session.pause()  // Pause when leaving AR view
    }
}
