//
//  Network.swift
//  PencilAnnotate
//
//  Created by Emma Costa on 16/01/23.
//

import Foundation
import SwiftUI


class Network: ObservableObject {
    
    @Published var currentImage: LocalImage = LocalImage(ui: UIImage(), ratio: 1.0, id: "")
    @Published var localImages: [LocalImage] = []
    @Published var images: [ImagesType] = []
    @Published var done = false
    @Published var sendError = false
    var ratio: CGFloat = 1
    var ids: [String] = []
    var width: CGFloat = (UIScreen.main.nativeBounds.width / UIScreen.main.nativeScale) - 250
    let psw: String = UserDefaults.standard.string(forKey: "psw") ?? ""
    
    var url = "https://develop.ewlab.di.unimi.it/apollo/api/"

    // resize the image to make it fit into the screen
    func resizeImage(image: UIImage, newWidth: CGFloat) -> (UIImage, CGFloat) {
        //print("width:", image.size.width)
        //print("height:", image.size.height)
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let ui = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return (ui, scale)
        
        
    }
    
    // reconvert the coordinates of the points according to the original size of the image
    func convertPoints(points: [CGPoint]) -> [CGPoint] {
        var pointsToSend: [CGPoint] = []
        for i in 0..<points.count {
            pointsToSend.append(CGPoint(x: points[i].x/self.currentImage.ratio, y: points[i].y/self.currentImage.ratio))
        }
        return pointsToSend
    }
    
    
    // LOGIN
    func login(usr: String, psw:String) -> Bool {
        guard let url = URL(string: self.url + "login/") else { fatalError("No URL")}
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        print(usr, psw)
        var res = false
        let semaphore = DispatchSemaphore(value: 0)
        let encoder = JSONEncoder()
        let jsonData = try? encoder.encode(User(usr: usr, psw: psw))
        
        urlRequest.httpBody = jsonData!
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
         URLSession.shared.dataTask(with: urlRequest) {
             (data, response, error) in
            if let error = error {
                print("Login error: ", error)
                semaphore.signal()
                return
            }
            guard let response = response as? HTTPURLResponse
                else {
                semaphore.signal()
                 return }
            
            if response.statusCode == 200 {
                print(String(bytes: data!, encoding: .utf8) as Any)
                res = true
                semaphore.signal()
                return
                
            } else {
                print(response.statusCode)
                print(response.description)
                semaphore.signal()
                return
            }
                
            
        }.resume()
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return res
    }
    
    
    // SEND POINTS
    func sendCoords(points: [CGPoint], id: String) -> Bool {
        
        let myPoints = convertPoints(points: points)
        //print("mypoints: ", myPoints)
        let mask = Mask(id: self.currentImage.id, points: myPoints,
                        size: CGSize(width: (self.currentImage.ui.size.width/self.currentImage.ratio), height: (self.currentImage.ui.size.height/self.currentImage.ratio)))
        let encoder = JSONEncoder()
        let encodedInfo = try! encoder.encode(mask)
        let encodedStr = String(bytes: encodedInfo, encoding: .utf8)!
        print(encodedStr)
        
        guard let url = URL(string: self.url + "send_coord/") else { fatalError("No URL") }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        urlRequest.setValue("\(String(describing: encodedInfo.count))", forHTTPHeaderField: "Content-Length")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(UserDefaults.standard.string(forKey: "user"), forHTTPHeaderField: "usr")
        urlRequest.setValue(UserDefaults.standard.string(forKey: "psw"), forHTTPHeaderField: "psw")
        
        urlRequest.httpBody = encodedInfo
        
        let semaphore = DispatchSemaphore(value: 0)
        var res = false
        
        URLSession.shared.dataTask(with: urlRequest) {
             (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                semaphore.signal()
                return
            }
            guard let response = response as? HTTPURLResponse
                else {
                semaphore.signal()
                 return
                
            }
            
            if response.statusCode == 200 {
                print(String(bytes: data!, encoding: .utf8) as Any)
                res = true
                semaphore.signal()
                return
                
                }
            else {
                semaphore.signal()
                print(response.statusCode)
                return
            }
    
                
            
        }.resume()
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return res
        
        
    }
    
    
    // GET NEXT ( SINGLE IMAGE )
    func getNext(endpoint: String) {
        print("downloading")
        guard let url = URL(string: self.url + endpoint) else { fatalError("No URL") }
        
        var urlRequest = URLRequest(url: url)
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(UserDefaults.standard.string(forKey: "user"), forHTTPHeaderField: "usr")
        urlRequest.setValue(UserDefaults.standard.string(forKey: "psw"), forHTTPHeaderField: "psw")
        
        URLSession.shared.dataTask(with: urlRequest) {
             (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }
            guard let response = response as? HTTPURLResponse
                else {
                 return }
            
            if response.statusCode == 200 {
                var decodedResponse = ""
                var responseObject = ImagesType(id: "", base64: "")
                let decoder = JSONDecoder()
                
                //let strData = String(data: data!.prefix(100), encoding: .utf8)!
                //print(strData)
                
                do {
                    
                    decodedResponse = try decoder.decode(String.self, from: data!)
                    responseObject = try decoder.decode(ImagesType.self, from: decodedResponse.data(using: .utf8)!)
                    
                } catch { return }
                
                DispatchQueue.main.async {
                    let ids = UserDefaults.standard.stringArray(forKey: "ids")
                    print(ids as Any)
                    
                        var uiImage = UIImage()
                        var ratio: CGFloat = 1.0
                        guard let ui = responseObject.base64.imageFromBase64 else {
                            print("Error, couldn't create image")
                            return
                        }
                        (uiImage, ratio) = self.resizeImage(image: ui, newWidth: self.width)
                        if ids == nil || !(ids?.contains(responseObject.id) ?? true) {
                                self.localImages.append(LocalImage(ui: uiImage, ratio: ratio, id: responseObject.id))
                                print(responseObject.id)
                                self.ids.append(responseObject.id)
                            
                        
                    }
                    
                    print("num of images:", self.localImages.count)
                    if self.localImages.count != 0 {
                        self.currentImage = self.localImages[0]
                    }  else {
                        self.done = true
                    }
                    
                }
            
            }
        }.resume()
    }
        
    
    // GET FIRST IMAGES
    func getImage(endpoint: String) {
        print("downloading")
        guard let url = URL(string: self.url + endpoint) else { fatalError("No URL") }
        
        var urlRequest = URLRequest(url: url)
        
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(UserDefaults.standard.string(forKey: "user"), forHTTPHeaderField: "usr")
        urlRequest.setValue(UserDefaults.standard.string(forKey: "psw"), forHTTPHeaderField: "psw")
        
        URLSession.shared.dataTask(with: urlRequest) {
             (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }
            guard let response = response as? HTTPURLResponse
                else {
                 return }
            
            if response.statusCode == 200 {
                var decodedResponse = ""
                var responseObject = Response(images: [])
                let decoder = JSONDecoder()
                
                //let strData = String(data: data!.prefix(100), encoding: .utf8)!
                //print(strData)
                
                do {
                    decodedResponse = try decoder.decode(String.self, from: data!)
                    responseObject = try decoder.decode(Response.self, from: decodedResponse.data(using: .utf8)!)
                    
                } catch { return }
                
                DispatchQueue.main.async {
                    let ids = UserDefaults.standard.stringArray(forKey: "ids")
                    
                    for img in responseObject.images {
                        
                        var uiImage = UIImage()
                        var ratio: CGFloat = 1.0
                        guard let ui = img.base64.imageFromBase64 else {
                            print("Error, couldn't create image")
                            return
                        }
                        (uiImage, ratio) = self.resizeImage(image: ui, newWidth: self.width)
                        if ids == nil || !(ids?.contains(img.id) ?? true) {
                                self.localImages.append(LocalImage(ui: uiImage, ratio: ratio, id: img.id))
                               
                                self.ids.append(img.id)
                            
                        }
                    }
                    
                    print(self.localImages.count)
                    if !self.localImages.isEmpty {
                        self.currentImage = self.localImages[0]
                    }  else {
                        self.getNext(endpoint: "get_next/")
                        self.getNext(endpoint: "get_next/")
                        
                    }
                    
                }
            
            }
        }.resume()
    }
    
}

struct User: Encodable {
    var usr: String
    var psw: String
}

struct Response: Decodable {
    var images: [ImagesType]
}

struct ImagesType: Decodable, Identifiable {
    var id: String
    var base64: String
}

struct LocalImage {
    var ui: UIImage
    var ratio: CGFloat
    var id: String
}

struct Mask: Encodable {
    var id: String
    var points: [CGPoint]
    var size: CGSize
}
    
extension UIImage {
    var base64: String? {
        self.jpegData(compressionQuality: 1)?.base64EncodedString()
    }
}

extension String {
    var imageFromBase64: UIImage? {
        guard let imageData = Data(base64Encoded: self) else {
            return nil
        }
        return UIImage(data: imageData)
    }
}
