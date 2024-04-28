//
//  ViewController.swift
//  MAD_Grad_Bandi_Divya_Sravani
//
//  Created by Bandi, Divya Sravani on 4/26/24.
//
import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    //Create a select image button
    let selectImageButton: UIButton = {
        // Initialize a UIButton
        let button = UIButton()
        button.setTitle("Select Image", for: .normal) // Set button title
        button.setTitleColor(.black, for: .normal) // Set button title color
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16) // Set button title font to bold system font with size 16
        button.backgroundColor = UIColor.orange // Set button background color to orange
        button.addTarget(self, action: #selector(selectImage), for: .touchUpInside) // Add target for button tap event
        button.translatesAutoresizingMaskIntoConstraints = false // Disable translating autoresizing mask into constraints
        // Set width and height constraints for the button
        button.widthAnchor.constraint(equalToConstant: 200).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
        }()
    // Initialize Core ML model
    let model = Boxcarclassifier2()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(selectImageButton)// Add selectImageButton to the view
        view.backgroundColor = .black// Set background color of the view to black
        // Configure imageView properties
        imageView.layer.cornerRadius = 10
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.systemBackground.cgColor
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Apply Auto Layout constraints for imageView
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        // Configure resultLabel properties
        resultLabel.textAlignment = .center
        resultLabel.textColor = .white
        resultLabel.font = UIFont.systemFont(ofSize: 18)
        resultLabel.numberOfLines = 0
    
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        // Apply Auto Layout constraints for resultLabel
        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            resultLabel.heightAnchor.constraint(equalToConstant: 150)
        ])
        // Apply Auto Layout constraints for selectImageButton
        NSLayoutConstraint.activate([
                    selectImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    selectImageButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 100)])
    }
    // Method called when the select image button is tapped
    @IBAction func selectImage(_ sender: UIButton) {
        let imagePicker = UIImagePickerController() // Create and present UIImagePickerController
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    // Delegate method called when an image is picked
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        // Get the picked image
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        // Set the picked image to imageView and classify it
        imageView.image = image
        classifyImage(image)
    }

    // Method to classify the image
    func classifyImage(_ image: UIImage) {// Create VNCoreMLModel from Core ML model
        guard let model = try? VNCoreMLModel(for: Boxcarclassifier2(configuration: MLModelConfiguration()).model) else {
            fatalError("Loading ML model failed")
        }
        // Create CIImage from UIImage
        guard let ciImage = CIImage(image: image) else{
            fatalError("Unable to load image")
        }
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))!// Get image orientation
        // Create VNCoreMLRequest for image classification
        let request = VNCoreMLRequest(model: model, completionHandler: {[weak self] request, error in
                guard let results = request.results as? [VNClassificationObservation], let firstResult = results.first else {// Handle classification results
                    self?.resultLabel.text = "Unable to classify"
                    return
                }
                
            DispatchQueue.main.async {
                // Determine classification label based on corrosion and rust level
                print("rthtjlkgrl;f,;")
                print(firstResult.identifier)
                var classificationLabel = ""
                classificationLabel = firstResult.identifier
                
                    if firstResult.identifier == "worst" {
                        classificationLabel = "Highly corroded and rusty"
                    } else if firstResult.identifier == "bad" {
                        classificationLabel = "Very rusty and more corrosion"
                    } else if firstResult.identifier == "average" {
                        classificationLabel = "Moderate rust or corrosion"
                    } else if firstResult.identifier == "good" {
                        classificationLabel = "Light rust or little corrosion"
                    } else {
                        classificationLabel = "Best (No rust and corrosion)"
                    }

                // Update resultLabel with classification label
                self?.resultLabel.text = "\(classificationLabel)"
            }
        })
        // Set compute device for the request based on environment
            #if targetEnvironment(simulator)
                if #available(iOS 17.0, *) {
                    let allDevices = MLComputeDevice.allComputeDevices

                    for device in allDevices {
                        if(device.description.contains("MLCPUComputeDevice")){
                            request.setComputeDevice(.some(device), for: .main)
                            break
                        }
                    }

                } else {
                    request.usesCPUOnly = true
                }
            #endif
        // Create VNImageRequestHandler and perform image classification asynchronously
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
        DispatchQueue.global(qos: .userInitiated).async {
        do {
            try handler.perform([request])
         } catch {
        print("Error performing classification: \(error)")
                }
            }
        }
    
}
