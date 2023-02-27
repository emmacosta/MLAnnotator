//
//  ContentView.swift
//  PencilAnnotate
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var network: Network
    @State var notLoaded = false
    var colorBackground: UIColor = UIColor (red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
  
    var body: some View {
        
        switch viewRouter.currentPage {
        
        case .login:
            LoginView(username: (UserDefaults.standard.string(forKey: "user") ?? "")!, psw: (UserDefaults.standard.string(forKey: "psw") ?? "")!)
        case .home:
            HomeView()
                
        case .image:
            if network.done {
                DoneView()
            } else {
                // image not yet loaded
                if (network.currentImage.ui == UIImage()) {
                    ZStack {
                        Color(colorBackground).ignoresSafeArea()
                        VStack {
                            Button(action: {
                                withAnimation() {
                                    viewRouter.currentPage = .home
                                }
                            })
                            {
                                Image(systemName: "chevron.backward")
                            }.frame(maxWidth: .infinity, alignment: .topLeading).padding()
                            Text("Carico immagine...").frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .font(.system(size: 25)).foregroundColor(.black)
                        }.padding(10)
                        
                        
                    }.onAppear {
                        print("is empty")
                        if network.localImages.isEmpty {
                            network.getImage(endpoint: "get_img/")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                                notLoaded = true
                            }
                        }
                        
                    }.alert(isPresented: $notLoaded) {
                        Alert(title: Text("Caricamento non riuscito"), dismissButton:
                                .default(Text("Torna alla home")) { viewRouter.currentPage = .home }
                        )
                    }
                    
                    .transition(.asymmetric(insertion:  .move(edge: .trailing), removal: .move(edge: .trailing)))
                } else {
                    // image loaded
                    AnnotateView()
                        .onAppear {
                            notLoaded = false
                            print("nuovo ID:", network.currentImage.id)
                            print("nuovo UI:", $network.currentImage.ui)
                        }
                }
            }
            
        case .done:
            DoneView()
            
        // loading next image
        case .changing:
            ZStack {
                Color(colorBackground).ignoresSafeArea()
                VStack {
                    Button(action: {
                        withAnimation() {
                            viewRouter.currentPage = .home
                        }
                    })
                    {
                        Image(systemName: "chevron.backward")
                    }.frame(maxWidth: .infinity, alignment: .topLeading).padding()
                    Text("Carico immagine...").frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .font(.system(size: 25)).foregroundColor(.black)
                }.padding(10)
                
                
            }.onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewRouter.currentPage = .image
                }
                
                
            }.alert(isPresented: $notLoaded) {
                Alert(title: Text("Caricamento non riuscito"), dismissButton:
                        .default(Text("Torna alla home")) { viewRouter.currentPage = .home }
                )
            }
            
        }
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(Network())
    }
}
