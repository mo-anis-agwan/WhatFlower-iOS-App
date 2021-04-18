//
//  ViewController.swift
//  WhatFlower
//
//  Created by Anis on 18/04/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    //MARK:- Variables
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    //MARK:- IBOutlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var flowerNameLabel: UILabel!
    @IBOutlet weak var flowerInfoLabel: UILabel!
    @IBOutlet weak var flowerInfoImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot import model")
        }
        
        let request = VNCoreMLRequest(model: model) { (vnRequest, error) in
            guard let classification = vnRequest.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify")
            }
            
            self.flowerNameLabel.text = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500",
        ]
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if case .success(let value) = response.result {
                print("Got the wikipedia info")
                //print(response)
                //print(value)
                
                let flowerJSON: JSON = JSON(value)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.flowerInfoImage.sd_setImage(with: URL(string: flowerImageURL))
                
                self.flowerInfoLabel.text = flowerDescription
                
            }
        }
    }

    //MARK:- IBActions
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    //MARK:- ImagePicker Delegates
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert UIImage to CIImage")
            }
            
            detect(image: ciImage)
            
        }
        
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
}

