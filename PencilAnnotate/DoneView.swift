//
//  DoneView.swift
//  PencilAnnotate
//
//  Created by Emma Costa on 06/02/23.
//

import SwiftUI

struct DoneView: View {
    @EnvironmentObject var viewRouter: ViewRouter
    var colorBackground: UIColor = UIColor (red: 0.96, green: 0.96, blue: 0.96, alpha: 1)
    
    var body: some View {
        ZStack {
            Color(colorBackground).ignoresSafeArea()
            VStack {
                HStack {
                    Button(action: {
                        withAnimation() {
                            viewRouter.transitionImage = .asymmetric(insertion:  .move(edge: .trailing), removal: .move(edge: .trailing))
                            viewRouter.currentPage = .home
                        }
                    })
                    {
                        Image(systemName: "chevron.backward").padding(.horizontal)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(15)
                }
                Spacer()
                Text("Annotazione conclusa").frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .font(.system(size: 25)).foregroundColor(.black)
            }
        }.transition(.asymmetric(insertion:  .move(edge: .trailing), removal: .move(edge: .trailing)))
    }
}

struct DoneView_Previews: PreviewProvider {
    static var previews: some View {
        DoneView()
    }
}
