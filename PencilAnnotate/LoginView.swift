//
//  LoginView.swift
//  PencilAnnotate
//
//  Created by Emma Costa on 26/01/23.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    @EnvironmentObject var network: Network
    var colorBackground: UIColor = UIColor (red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
    @State var username: String = ""
    @State var psw: String = ""
    // ee095a3061f7a59bfdac6d3d739239ed
    @State var showEmptyAlert: Bool = false
    
    
    var body: some View {
        ZStack {
            
            Color(colorBackground).ignoresSafeArea()
            VStack(alignment: .center) {
                HStack {
                    Text("ML Annotator").font(.largeTitle)
                    Image(systemName: "hand.draw").font(.system(size: 35)).foregroundColor(.black).padding(15)
                }.padding(10)
                VStack {
                    HStack {
                        
                        Text("Username: ")
                        TextField("username", text: $username)
                        
                    }.padding(15).background(Rectangle().cornerRadius(15).foregroundColor(.white)).shadow(radius: 10)
                    
                    HStack {
                        
                        Text("Password: ")
                        SecureField("password", text: $psw)
                        //TextField("password", text: $psw)
                        
                    }.padding(15).background(Rectangle().cornerRadius(15).foregroundColor(.white)).shadow(radius: 10)
                    
                    Button(action: {
                        withAnimation() {
                            if (!username.isEmpty && !psw.isEmpty && network.login(usr: username, psw: psw)) {
                                
                                print("username: ", username)
                                print("psw: ", psw)
                                UserDefaults.standard.set(self.username, forKey: "user")
                                UserDefaults.standard.set(self.psw, forKey: "psw")
                                
                                viewRouter.currentPage = .home
                            
                            }
                            else {
                                showEmptyAlert = true
                            }
                        }
                    }){
                        Text("Accedi").padding(15).background(Rectangle().cornerRadius(15).foregroundColor(.accentColor).frame(width: 100))
                            .foregroundColor(.white).font(.system(size: 18, weight: .bold))
                    }.alert(isPresented: $showEmptyAlert) {
                        
                        Alert(title: Text("Login fallito"),message: Text("Impossibile effettuare il login"), dismissButton: .cancel(Text("Chiudi")))
                    }
                            
                    
                }
                    
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center).padding(10)
         
        }.transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(username: "", psw: "")
    }
}
