//
//  ContentView.swift
//  PencilAnnotate

import SwiftUI
import Foundation
import PencilKit
import UIKit


struct AnnotateView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var network: Network
    var colorBackground: UIColor = UIColor (red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
    @State var canvas = PKCanvasView()
    @State var color: Color = .red
    @State var previousScale: CGFloat = 1.0
    @State var currentScale:CGFloat = 1.0
    @State var minZoomScale: CGFloat = 1.0
    @State var maxZoomScale: CGFloat = 5.0
    @State var currentOffset: CGSize = CGSize.zero
    @State var previousOffset: CGSize = CGSize.zero
    @State var showSent: Bool = false
    @State var showSkip: Bool = false
    //@State var isDrawing: Bool = true
    @State var sent: Bool = false
    @State var showAlert: Bool = false
    @State var sendingAlert: Bool = false
    @State var showErrorSent:Bool = false
    @State var viewPoints: [CGPoint] = []
    var maximumToClose: CGFloat = 50
    var username: String = (UserDefaults.standard.string(forKey: "user"))!
    var psw: String = (UserDefaults.standard.string(forKey: "psw"))!
    @State private var activeAlert: ActiveAlert = .sending
    
   
    
    enum ActiveAlert {
        case sending
        case maskError
    }
    
    
    var body: some View {
        
        ZStack{
            Color(colorBackground).ignoresSafeArea()
            // canva
            DrawingView(canvas: $canvas, color: $color, sent: $sent, img: $network.currentImage.ui)
                    .scaleEffect(max(self.currentScale, 1.0))
                    .offset(currentOffset)
                    .environmentObject(network)
                    
                    
                    .gesture(DragGesture(minimumDistance: 1)
                        .onChanged { gesture in
                                //if (!isDrawing) {
                                   
                                    self.currentOffset = CGSize(width: gesture.translation.width + self.previousOffset.width, height: gesture.translation.height + self.previousOffset.height)
                                    print("dragging")
                              // }
                                
                            }
                        .onEnded { value in
                                //if (!isDrawing) {
                                    self.currentOffset = CGSize(width: value.translation.width + self.previousOffset.width, height: value.translation.height + self.previousOffset.height)
                                    self.previousOffset = self.currentOffset
                                    
                                    print("drag ended")
                                //}
                            }
                        
                            
                        )
                    .gesture(withAnimation(.easeInOut) {
                            MagnificationGesture()
                                .onChanged { value in
                                    withAnimation {
                                        print("Now current scale:", self.currentScale)
                                        print("value:", value)
                                        print("previous scale", self.previousScale)
                                        let delta = value / self.previousScale
                                        self.previousScale = value
                                        if currentScale>maxZoomScale {
                                            self.currentScale = maxZoomScale
                                        }
                                        if currentScale<minZoomScale {
                                            self.currentScale = minZoomScale
                                            
                                            self.currentOffset = .zero
                                        }
                                        self.currentScale = self.currentScale * delta
                                    }
                                    
                                }
                                .onEnded { value in
                                    self.previousScale = 1.0
                                }
                                
                            
                        
                    })
                    .frame(width: network.currentImage.ui.size.width, height: network.currentImage.ui.size.height)
             
            // back button, save and send mask
            HStack {
                Button(action: {
                    withAnimation() {
                        viewRouter.currentPage = .home
                    }
                })
                {
                    Image(systemName: "chevron.backward").padding(.horizontal)
                }.frame(maxWidth: 200, alignment: .leading)
                Spacer()
                Text(network.currentImage.id).padding(15).background(Rectangle().opacity(0.5).foregroundColor(.white).cornerRadius(15))
                Spacer()
                HStack {
                    Button(action: {
                        showSkip = true
                        if network.localImages.count < 2 {
                            network.getNext(endpoint: "get_next/")
                        }
                    }, label: {
                        
                        Text("Salta").padding(15).background(Rectangle().cornerRadius(15).foregroundColor(.white))
                            .foregroundColor(.red)
                    }).alert(isPresented: $showSkip) {
                        
                        Alert(title: Text("Salta annotazione"),message: Text("Vuoi saltare l'annotazione di questa immagine?"), primaryButton: .destructive(Text("Chiudi")), secondaryButton: .default(Text("Salta")) {
                            let confirm = network.sendCoords(points: [], id: network.currentImage.id)
                            if confirm {
                                handleNext()
                                showSent = false
                            }
                            else {
                                sendingAlert = true
                            }
                            
                            print(network.localImages[UserDefaults.standard.integer(forKey: "image")].id)
                        })
                    }
                    Button(action: {
                        saveMask()
                        if showSent {
                            self.showAlert(.sending)
                        } else {
                            self.showAlert(.maskError)
                        }
                        if network.localImages.count < 2 {
                            network.getNext(endpoint: "get_next/")
                        }
                        
                    }, label: {
                        
                        Text("Invia").padding(15).background(Rectangle().cornerRadius(15).foregroundColor(Color(UIColor.systemBlue))).foregroundColor(.white)
                        
                    })
                    .alert(isPresented: $showAlert) {
                        switch activeAlert {
                            case .sending:
                            
                                return Alert(title: Text("Inviare annotazione?"), primaryButton: .destructive(Text("Annulla")), secondaryButton:  .default(Text("Conferma")) {
                                    let confirm = network.sendCoords(points: viewPoints, id: network.currentImage.id)
                                    if confirm {
                                       handleNext()
                                       showSent = false
                                    }
                                    else {
                                        self.showAlert(.maskError)
                                        showSent = false
                                    }
                                    
                                    
                                    
                                })
                            case .maskError:
                                return Alert(title: Text("Errore"), message: Text("Invio non riuscito"), dismissButton: .default(Text("Chiudi")))
                            
                        
                            
                        }
                        
                        
                    }
                }.frame(maxWidth: 200, alignment: .trailing)
                
                    
                
            }.padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            // drawing/dragging buttons, delete last stroke, zoom
            HStack {
                /*Button(action: {  // pencil tool
                    isDrawing = true
                }) {
                    
                    Image(systemName: "pencil.and.outline")
                        .font(.largeTitle)
                }.padding(.trailing).disabled(isDrawing)
                
               Button(action: {  // moveimage
                    isDrawing = false
                    
                   }){
                    
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.largeTitle)
                }.disabled(!isDrawing).padding(.trailing)
                */
                
                Button {
                    _ = canvas.drawing.strokes.popLast()
                    
                } label: {
                    
                    Image(systemName: "trash")
                        .font(.largeTitle)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut){
                        //currentOffset = .zero
                        previousScale = currentScale
                        if currentScale<=minZoomScale {
                            currentScale = 1
                            currentOffset = .zero
                            previousOffset = .zero
                        }
                        else { currentScale = previousScale - 0.5
                        }
                        
                    }
                }) {
                    Image(systemName: "minus.circle").font(.largeTitle)
                }
                
                Text("Zoom").padding(10)
                
                Button(action: {
                    withAnimation(.easeInOut) {
                        previousScale = currentScale
                        if currentScale>=maxZoomScale {
                            currentScale = 5
                        }
                        else { currentScale = previousScale + 0.5 }
                    }
                    
                }) {
                    Image(systemName: "plus.circle").font(.largeTitle)
                }
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom).padding(15)
            
        }
        .transition(viewRouter.transitionImage)

    }
    
  
    func showAlert(_ active: ActiveAlert) -> Void {
        DispatchQueue.global().async {
            activeAlert = active
            showAlert = true
            print(self.showAlert)
        }
            
    }
    
    // call when "next" or "send mask" are called
    func handleNext() {
        if network.localImages.count<4 {
           network.getNext(endpoint: "get_next/")
           network.getNext(endpoint: "get_next/")
           network.getNext(endpoint: "get_next/")
            
        }
        sent = true
        
        viewPoints = []
        var ids = UserDefaults.standard.stringArray(forKey: "ids")
        if ids == nil {
            UserDefaults.standard.set([network.currentImage.id], forKey: "ids")
        } else {
            ids?.append(network.currentImage.id)
            UserDefaults.standard.set(ids, forKey: "ids")
            print("current ids: ", ids as Any)
        }
        print(network.localImages.count)
        if network.localImages.count>1 {
            viewRouter.currentPage = .changing
            network.currentImage = network.localImages[1]
            canvas.drawing.strokes.removeAll()
            network.localImages.removeFirst()
            sent = true
            canvas.drawing.strokes.removeAll()
            
            
        } else {
            canvas.drawing.strokes.removeAll()
            viewRouter.transitionImage = .asymmetric(insertion:  .move(edge: .trailing), removal: .move(edge: .leading))
            viewRouter.currentPage = .done
        }
    }
                        
    // create mask to send
    func saveMask() {
        if !canvas.drawing.strokes.isEmpty {
            for stroke in canvas.drawing.strokes {
                if (abs((stroke.path.first?.location.x)! - (stroke.path.last?.location.x)!) < 10 &&
                    abs((stroke.path.first?.location.y)! - (stroke.path.last?.location.y)!) < 10) {
                    for pt in stroke.path.interpolatedPoints(by: .distance(3)) {
                        viewPoints.append(pt.location)
                        
                    }
                }
            }
            if !viewPoints.isEmpty {
                showSent = true
                print("show sent", showSent)
                
            }
        }
        
    }
}

struct AnnotateView_Previews: PreviewProvider {
    static var previews: some View {
        AnnotateView()
    }
}
