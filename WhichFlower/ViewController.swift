//
//  ViewController.swift
//  WhichFlower
//
//  Created by Rohan Ravindran  on 2018-12-23.
//  Copyright © 2018 Rohan Ravindran . All rights reserved.
//

import UIKit
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
    }

    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedimage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let ciimage = CIImage(image: userPickedimage) else {
                fatalError("Could not produce CIImage")
            }
            
            detect(image: ciimage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Could not convert model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            let results = request.results as? [VNClassificationObservation]
    
            if let firstResult = results?.first {
                self.navigationItem.title = firstResult.identifier.capitalized
                self.navigationController?.navigationBar.barTintColor = UIColor.green
                
                let parameters : [String:String] = [
                    "format" : "json",
                    "action" : "query",
                    "prop" : "extracts|pageimages",
                    "exintro" : "",
                    "explaintext" : "",
                    "titles" : firstResult.identifier,
                    "indexpageids" : "",
                    "redirects" : "1",
                    "pithumbsize" : "500"
                    ]
                
                self.getFlowerData(url: self.wikipediaURl, params: parameters)
                
            }
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try? handler.perform([request])
        } catch {
            print("error classify: \(error)")
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    func getFlowerData(url: String, params : [String : String]) {
        Alamofire.request(url, method: .get, parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                print("Success, got the flower data")
                
                let flowerJSON : JSON = JSON(response.result.value!)
                //print(flowerJSON)
                self.parseJSON(flowerDataJSON: flowerJSON)
                
            } else {
                print("error get flower data: \(response.error!)")
                //set label to error
                
            }
            
            
        }
    }
    
    func parseJSON(flowerDataJSON result : JSON) {
        let pageid : String = result["query"]["pageids"][0].stringValue
        let flowerDescription : String = result["query"]["pages"][pageid]["extract"].stringValue
        let flowerImageURL : String = result["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
        
        
        imageView.sd_setImage(with: URL(string: flowerImageURL))
        descriptionLabel.text = flowerDescription
        
        
    }
    
    @IBOutlet weak var descriptionLabel: UILabel!
}

