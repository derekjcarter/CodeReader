//
//  ViewController.swift
//  CodeReader
//
//  Created by Derek Carter on 7/16/19.
//  Copyright © 2019 Derek Carter. All rights reserved.
//

import AVFoundation
import UIKit

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    // View properties
    @IBOutlet var cameraFocusImageView: UIImageView!
    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var messageBackgroundView: UIView! // Spans passed safe area
    @IBOutlet var headerView: UIView!
    @IBOutlet var headerBackgroundView: UIView! // Spans passed safe area
    
    // Copy/paste properties
    var shouldCopyString = false
    
    // Camera properties
    var captureSession = AVCaptureSession()
    var captureVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    var codeView: UIView?
    let metadataObjectTypes = [AVMetadataObject.ObjectType.upce,
                               AVMetadataObject.ObjectType.code39,
                               AVMetadataObject.ObjectType.code39Mod43,
                               AVMetadataObject.ObjectType.ean13,
                               AVMetadataObject.ObjectType.ean8,
                               AVMetadataObject.ObjectType.code93,
                               AVMetadataObject.ObjectType.code128,
                               AVMetadataObject.ObjectType.pdf417,
                               AVMetadataObject.ObjectType.qr,
                               AVMetadataObject.ObjectType.aztec,
                               AVMetadataObject.ObjectType.interleaved2of5,
                               AVMetadataObject.ObjectType.itf14,
                               AVMetadataObject.ObjectType.dataMatrix] // Do not support the `face` type
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the AVCaptureDevice for the back camera
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera],
                                                                mediaType: AVMediaType.video,
                                                                position: .back)
        
        guard let captureDevice = discoverySession.devices.first else {
            print("Failed to get the captureDevice")
            return
        }
        
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            // Setup the input
            captureSession.addInput(captureDeviceInput)
            
            // Setup the output
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Setup the metadata delegate and object types
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = metadataObjectTypes
        }
        catch {
            print("Failed to create the captureSession: \(error)")
            return
        }
        
        // Setup the video preview layer with the session
        captureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        captureVideoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        captureVideoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(captureVideoPreviewLayer!)
        
        // Start capturing the video
        captureSession.startRunning()
        
        // Move views on top of the camera view
        view.bringSubviewToFront(messageBackgroundView)
        view.bringSubviewToFront(messageLabel)
        view.bringSubviewToFront(headerBackgroundView)
        view.bringSubviewToFront(headerView)
        view.bringSubviewToFront(cameraFocusImageView)
        
        // Setup the code view for highlighting and set in front of camera view
        codeView = UIView()
        if let codeView = codeView {
            codeView.layer.borderColor = UIColor.green.cgColor
            codeView.layer.borderWidth = 2
            view.addSubview(codeView)
            view.bringSubviewToFront(codeView)
        }
        
        // Setup tap gesture for message label
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapMessageLabel(_:)))
        messageLabel.addGestureRecognizer(tapGesture)
    }
    
    
    // MARK: - Pasteboard Methods
    
    @objc func tapMessageLabel(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.view != nil else {
            return
        }
        
        if let string = messageLabel.text, shouldCopyString {
            // Copy string to pasteboard
            let pasteboard = UIPasteboard.general
            pasteboard.string = string
            
            // Display to user string is copied
            displayCopiedAlert()
        }
    }
    
    func displayCopiedAlert() {
        if presentedViewController != nil {
            return
        }
        
        // Display the alert
        let alertController = UIAlertController(title: "QR code copied to clipboard.", message: nil, preferredStyle: .alert)
        present(alertController, animated: true, completion: nil)
        
        // Dismiss the alert after short delay
        let delay = DispatchTime.now() + 1.25
        DispatchQueue.main.asyncAfter(deadline: delay) {
            alertController.dismiss(animated: true, completion: nil)
        }
    }
    
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate Methods
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Set defaults if metadataObjects is empty
        if metadataObjects.count == 0 {
            codeView?.frame = CGRect.zero
            cameraFocusImageView.alpha = 0.15
            shouldCopyString = false
            messageLabel.text = "No QR Code Detected"
            return
        }
        
        // Set the first metadata object
        let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // Update the message label if metadata is supported
        if metadataObjectTypes.contains(metadataObject.type) {
            let barCodeObject = captureVideoPreviewLayer?.transformedMetadataObject(for: metadataObject)
            codeView?.frame = barCodeObject!.bounds
            cameraFocusImageView.alpha = 0.0
            
            if metadataObject.stringValue != nil {
                shouldCopyString = true
                messageLabel.text = metadataObject.stringValue
            }
        }
    }
    
}
