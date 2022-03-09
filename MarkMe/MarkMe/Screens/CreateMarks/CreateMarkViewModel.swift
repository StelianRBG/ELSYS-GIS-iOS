//
//  CreateMarkViewModel.swift
//  MarkMe
//
//  Created by Stelian Todorichkov on 28.02.22.
//

import UIKit.UIImage
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage


class CreateMarkViewModel {
    let db = Firestore.firestore()
    let storage = Storage.storage().reference()
    let geoCodder = CLGeocoder()
    var markTypes = [MarkType]()
    var creator = ""
    
    init() {
        getMarkTypes()
        getCreator()
    }
    
    func getMarkTypes() {
        db.collection("MarkType").addSnapshotListener { [weak self] (querySnapshot, err) in
            guard err == nil, querySnapshot?.documents.isEmpty == false, let documents = querySnapshot?.documents else {
                print(err.debugDescription)
                return
            }
            self?.markTypes = documents.compactMap { (document) -> MarkType? in
                return try? document.data(as: MarkType.self)
            }
        }
    }
    
    func getCreator() {
        guard let curUser = Auth.auth().currentUser else{
            return
        }

        if curUser.providerData[0].providerType == .email {
            db.collection("User").getDocuments() { [weak self] (querySnapshot, err) in
                guard err == nil, querySnapshot?.documents.isEmpty == false, let documents = querySnapshot?.documents else {
                    print(err.debugDescription)
                    return
                }
                let users = documents.compactMap { (document) -> User? in
                    return try? document.data(as: User.self)
                }
                self?.creator = users.filter({ $0.uid == curUser.uid }).map({ $0.username })[0]
            }
        }
        else {
            guard let name = curUser.displayName else {
                return
            }
            self.creator = name
        }
    }
    
    func findAddress(address: String?, completion: @escaping (Result<CLLocationCoordinate2D, AlertError>)->()) {
        guard let address = address, !address.isEmpty else {
            completion(.failure(AlertError(title: ErrorTitle.validation.rawValue, message: "Search field is epmty")))
            return
        }

        geoCodder.geocodeAddressString(address) { (placemark, error) in
            guard error == nil, let location = placemark?[0].location?.coordinate else {
                completion(.failure(AlertError(title: ErrorTitle.address.rawValue, message: "Address not found")))
                return
            }
            completion(.success(location))
        }
    }
    
    func validateData(title: String?,description: String?, type: String?, location: CLLocationCoordinate2D) -> Mark? {
        // check form is completed
        guard  let title = title,
               let description = description,
               let type = type,
               !title.isEmpty,
               !description.isEmpty,
               !type.isEmpty
        else {
            return nil
        }
        return Mark(title: title, description: description, geolocation: GeoPoint(latitude: location.latitude, longitude: location.longitude), type: type, creator: creator)
    }
    
    func validateMarkType(type: String, completion: (AlertError?) -> ()){
        if markTypes.contains(where: { $0.type == type }) {
            completion(nil)
            return
        }
        completion(AlertError(title: ErrorTitle.validation.rawValue, message: "Mark type is invalid!"))
    }
    
    func addMark(mark: Mark) -> AlertError? {
        do {
            let _ = try db.collection("Mark").addDocument(from: mark)
            return nil
        }
        catch {
            return AlertError(title: ErrorTitle.db.rawValue, message: error.localizedDescription)
        }
    }
    
    func saveImageInStorage(path: String, image: UIImage, completion: @escaping (Result<String, AlertError>) -> ()) {
        let ref = self.storage.child(path)
        ref.putData(image.pngData()!, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(AlertError(title: ErrorTitle.storage.rawValue, message: error.localizedDescription)))
                return
            }
            ref.downloadURL() { (url, error) in
                if let error = error {
                    completion(.failure(AlertError(title: ErrorTitle.storage.rawValue, message: error.localizedDescription)))
                    return
                }
                guard let urlString = url?.absoluteString else {
                    completion(.failure(AlertError(title: ErrorTitle.storage.rawValue, message: "Can't get url")))
                    return
                }
                completion(.success(urlString))
            }
        }
    }
    
    
    func createMark(title: String?,description: String?, type: String?, location: CLLocationCoordinate2D, image: UIImage?, completion: @escaping (Result<Void, AlertError>) -> ()) {
        // validate form
        guard let vaidationResult = validateData(title: title, description: description, type: type, location: location) else {
            completion(.failure(AlertError(title: ErrorTitle.validation.rawValue, message: "The form must be completed!")))
            return
        }
        var newMark = vaidationResult
        
        // check mark type is valid
        validateMarkType(type: newMark.type) { (markAlert) in
            if let markAlert = markAlert {
                completion(.failure(markAlert))
                return
            }
            
            // check for image
            if let image = image {
                // set path for image
                let path = "images/" + newMark.creator + "/" + newMark.title + ".png"
                
                // try to sava image in storage
                saveImageInStorage(path: path, image: image) { [weak self] (result) in
                    switch result {
                    case .success(let urlString):
                        newMark.imgPath = urlString
                        // try to save mark in db
                        if let dbResult = self?.addMark(mark: newMark) {
                            completion(.failure(dbResult))
                            return
                        }
                        completion(.success(()))
                    case .failure(let alert):
                        completion(.failure(alert))
                    }
                }
            }
            else {
                // try to save mark in db
                if let dbResult = addMark(mark: newMark) {
                    completion(.failure(dbResult))
                    return
                }
                completion(.success(()))
            }
        }
    }
}
