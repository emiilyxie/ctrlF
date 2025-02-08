//
//  ViewController.swift
//  ctrlF-AR
//
//  Created by Emily Xie on 2/7/25.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var qrRequest: VNDetectBarcodesRequest?
    var storedFixedCameraPosition: SCNVector3?
    var fetchedObjects: [[String: Any]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        
        // Start AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin, .showPhysicsShapes]
        sceneView.session.run(configuration)
        
        print("set up QR detection")
        qrRequest = VNDetectBarcodesRequest(completionHandler: handleQRCodeDetection)
        if qrRequest == nil {
            print("❌ QR Request failed to initialize.")
        } else {
            print("✅ QR Request successfully created.")
        }

        // Fetch objects from the backend
        fetchObjectPositions()
    }

    func fetchObjectPositions() {
        let url = URL(string: "http://192.168.0.101:5000/get-objects")!  // Replace with actual server IP

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error fetching object data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let objects = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.fetchedObjects = objects  // Store fetched objects
                    print("📦 Objects fetched and stored.")
                }
            }
        }.resume()
    }
    
    func convertObjectPositionToAR(objectX: Double, objectY: Double, objectZ: Double, cameraPosition: SCNVector3) -> SCNVector3 {
        // Convert stored object position (relative to the fixed camera) into ARKit world coordinates
        // we are facing the camera so we should reverse the Z
        let worldX = cameraPosition.x + Float(objectX)
        let worldY = cameraPosition.y + Float(objectY)
        let worldZ = cameraPosition.z + Float(objectZ)

        return SCNVector3(worldX, worldY, worldZ)
    }
    
    func clearARScene() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        print("🗑 Scene cleared before placing new objects.")
    }

    func placeObjects(in objects: [[String: Any]]) {
        guard let cameraPosition = storedFixedCameraPosition else {
                print("❌ No QR code position stored. Cannot place objects.")
                return
            }
        
        clearARScene()
        
        for object in objects {
            if let name = object["name"] as? String,
               let x = object["x"] as? Double,
               let y = object["y"] as? Double,
               let z = object["z"] as? Double {

                let worldPosition = convertObjectPositionToAR(objectX: x, objectY: y, objectZ: z, cameraPosition: cameraPosition)
                self.addMarker(at: worldPosition, with: name)
            }
        }
    }

    func addMarker(at position: SCNVector3, with label: String) {
        print("position", position, ", label", label)
        
        let sphere = SCNSphere(radius: 0.05)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        sphere.materials = [material]

        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
//        sphereNode.position = SCNVector3(x: 0, y: 0, z: 0)

        let textNode = SCNNode()
        let textGeometry = SCNText(string: label, extrusionDepth: 0.1)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textNode.geometry = textGeometry
        textNode.scale = SCNVector3(0.02, 0.02, 0.02)
        textNode.position = SCNVector3(position.x, position.y + 0.2, position.z)

        sceneView.scene.rootNode.addChildNode(sphereNode)
        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    func handleQRCodeDetection(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNBarcodeObservation] else { return }

        for result in results {
            if let payload = result.payloadStringValue, payload == "ctrlF_app" {
                print("QR Code Detected!")

                // Convert QR code screen position to ARKit world space
                let qrPosition = getQRCodeWorldPosition(result.boundingBox.origin)
                print("Fixed Camera Position in AR: \(String(describing: qrPosition))")

                // Store for adjusting object positions
                storeFixedCameraPosition(qrPosition)
            }
        }
    }

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
//        return getFeaturePointWorldPosition(screenPoint)
    }
    
    // Fallback: Use feature points if no plane is found
//    func getFeaturePointWorldPosition(_ screenPoint: CGPoint) -> SCNVector3? {
//        guard let query = sceneView.raycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .any) else {
//            print("❌ Feature point raycast query failed.")
//            return nil
//        }
//
//        let results = sceneView.session.raycast(query)
//        if let firstResult = results.first {
//            let transform = firstResult.worldTransform
//            return SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
//        }
//
//        print("❌ No feature point raycast results.")
//        return nil
//    }

    func storeFixedCameraPosition(_ position: SCNVector3?) {
        if let pos = position {
            storedFixedCameraPosition = pos
            print("Fixed Camera Stored at: \(pos)")
            // Save this position to adjust object locations
            
            // Check if objects have been fetched
            if !fetchedObjects.isEmpty {
                placeObjects(in: fetchedObjects)
            } else {
                print("⚠️ Objects not yet fetched. Will place in AR once available.")
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let frame = sceneView.session.currentFrame else {
//            print("❌ No ARKit frame detected.")
            return
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage, options: [:])
//        testRaycastAtCenter();

        do {
//            print("🔄 Running Vision request...")
            try imageRequestHandler.perform([qrRequest!])
        } catch {
//            print("❌ Error performing Vision request: \(error.localizedDescription)")
        }
    }
    
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        if let planeAnchor = anchor as? ARPlaneAnchor {
//            print("✅ Plane detected: \(planeAnchor)")
//        }
//    }
    
//    func testRaycastAtCenter() {
//        let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
//
//        guard let query = sceneView.raycastQuery(from: screenCenter, allowing: .existingPlaneGeometry, alignment: .any) else {
//            print("❌ Raycast query failed at screen center.")
//            return
//        }
//
//        let results = sceneView.session.raycast(query)
//        if let firstResult = results.first {
//            let transform = firstResult.worldTransform
//            let worldPosition = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
//            print("✅ Raycast succeeded at screen center: \(worldPosition)")
//        } else {
//            print("❌ No raycast results at screen center.")
//        }
//    }
}
