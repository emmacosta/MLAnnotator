//
//  HomeView.swift
//  PencilAnnotate
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var network: Network
    var colorBackground: UIColor = UIColor (red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
    
    var body: some View {
        ZStack {
            
            Color(colorBackground).ignoresSafeArea()
            
            VStack(alignment: .center) {
                HStack {
                    Text("ML Annotator").font(.largeTitle)
                    Image(systemName: "hand.draw").font(.system(size: 35)).foregroundColor(.black).padding(15)
                }.padding(10)
                Button(action: {
                        withAnimation() {
                            print("user: ", (UserDefaults.standard.string(forKey: "user"))! as Any)
                            print("psw: ", (UserDefaults.standard.string(forKey: "psw"))! as Any)
                            //print("image: ", (UserDefaults.standard.integer(forKey: "image")) as Any)
                            print("ids: ", (UserDefaults.standard.stringArray(forKey: "ids")) as Any)
                           
                            viewRouter.transitionHome = .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading))
                            viewRouter.currentPage = .image
                        }
                    }
                ) {
                    Text("Comincia annotazione").frame(alignment: .center).padding(10)
                    Spacer()
                    Image(systemName: "chevron.right").frame(alignment: .center).padding(10)
                }.padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    .foregroundColor(.black)
                    .background(Rectangle().cornerRadius(15)
                        .foregroundColor(Color.white))
                    .shadow(radius: 10)
                    
                    
                Spacer()
                HStack {
                    Text("User: ").padding(5).font(.system(size: 20))
                    Text((UserDefaults.standard.string(forKey: "user"))!).font(.system(size: 20, weight: .bold))
                }
            }.padding(10)
        }
        .transition(viewRouter.transitionHome)
        
    }
    
}

struct HomeView_Previews: PreviewProvider {
    
    static var previews: some View {
        HomeView().environmentObject(Network())
        
    }
}
