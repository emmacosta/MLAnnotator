//
//  PencilAnnotateApp.swift
//  PencilAnnotate
//

import SwiftUI

@main
struct Annotator: App {
    @StateObject var viewRouter = ViewRouter()
    @StateObject var newtork = Network()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(viewRouter).environmentObject(newtork)//.environmentObject(newtork)
                
        }
    }
}
