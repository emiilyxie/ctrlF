//
//  QRCodeScanner.swift
//  ctrlF-AR
//
//  Created by Emily Xie on 2/8/25.
//

import ARKit
import Vision

class QRCodeScanner {
    static func detectQRCode(in frame: CVPixelBuffer, completion: @escaping (SCNVector3?) -> Void) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: frame, options: [:])
        
        let request = VNDetectBarcodesRequest { request, error in
            guard let results = request.results as? [VNBarcodeObservation] else { return }
            
            for result in results {
                if let payload = result.payloadStringValue, payload == "ctrlF app" {
                    print("✅ QR Code Detected!")

                    // Convert QR Code screen position to ARKit world space
                    let qrPosition = SCNVector3(
                        Float(result.boundingBox.origin.x),
                        Float(result.boundingBox.origin.y),
                        Float(result.boundingBox.origin.x) // Placeholder - update to real position conversion
                    )
                    completion(qrPosition)
                }
            }
        }
        
        try? requestHandler.perform([request])
    }
}

