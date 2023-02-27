//
//  DrawingView.swift
//  PencilAnnotate
//

import SwiftUI
import PencilKit
import Foundation

struct DrawingView: UIViewRepresentable {
   
    
    @Binding var canvas: PKCanvasView
    @Binding var color: Color
    @Binding var sent: Bool
    @Binding var img: UIImage
    
    
     var width: CGFloat = 2
     var ink : PKInkingTool {
        
         PKInkingTool(.pen, color: UIColor(color), width: width)
         
    }
   
    
    func makeUIView(context: Context) -> PKCanvasView {
        //print("new view!")
        canvas.isOpaque = false
        canvas.backgroundColor = UIColor.white
        
        canvas.becomeFirstResponder()
        
        let imgView = UIImageView(image: img)
        
        let content = canvas.subviews[0]
        content.addSubview(imgView)
        content.sendSubviewToBack(imgView)
        canvas.subviews[1].isOpaque = false
        canvas.drawingPolicy = .pencilOnly
        
        canvas.tool = ink
        canvas.delegate = context.coordinator

        return canvas
    }
    
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        
        //if (isDrawing) {
            uiView.tool = ink
        /*}
        else {
            uiView.drawingGestureRecognizer.isEnabled = false
        }*/
        
        
    }
    
    func makeCoordinator() -> Coordinator {
        
        return Coordinator(self.canvas)
    }
    

    class Coordinator: NSObject, PKCanvasViewDelegate {
        
        @State var parent: PKCanvasView
       
        var check: Bool
        var closePoints: [CGPoint]
        var orderedPoints: [[CGPoint]]
        var numOfStrokes: Int
        var distancePoints: CGFloat = 2
        var maximumToClose: CGFloat = 25
        var lastClosed: Bool = false
        var toClose: Bool = false

        init(_ parent: PKCanvasView) {
            self.parent = parent
            self.check = true
            self.closePoints = []
            self.orderedPoints = []
            self.numOfStrokes = 0
            
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
          
            
            if !canvasView.drawing.strokes.isEmpty {
                
                // check if last stroke is out of bounds
                for point in (canvasView.drawing.strokes.last?.path)!.interpolatedPoints(by: .distance(distancePoints)) {
                    if point.location.x > canvasView.bounds.width || point.location.y > canvasView.bounds.height || point.location.x < 0 || point.location.y < 0 {
                        
                        print("out of bounds")
                        canvasView.drawing.strokes.removeAll()
                        
                        
                    }
                }
            }
            if !canvasView.drawing.strokes.isEmpty {
                
                if check {
                    check = false
                    
                    //check if a stroke has been deleted; the number of strokes could have decreased because a stroke has been closed
                    //so I check with lastClosed that this isn't the case; if it is, closePoints and orderedPoints are empty
                    let newNumOfStrokes = canvasView.drawing.strokes.count
                    
                    if newNumOfStrokes < numOfStrokes && !lastClosed {
                        if !closePoints.isEmpty {
                            closePoints.removeLast()
                            closePoints.removeLast()
                            if !orderedPoints.isEmpty {
                                orderedPoints.removeLast()
                            }
                        }
                        check = true
                    } else {
                        
                        let path = canvasView.drawing.strokes.last?.path
                        
                           
                            // add points of open line to array closePoints
                            closePoints.append((path?.first?.location)!)
                            closePoints.append((path?.last?.location)!)
                        
                            // case sigle stroke is closed
                            if searchEdges(points: [(path?.first?.location)!, (path?.last?.location)!], numStrokes: 1, strokes: [canvasView.drawing.strokes.last!] ) {
                                
                                while canvasView.drawing.strokes.count > 1 {
                                    canvasView.drawing.strokes.removeFirst()
                                    if closePoints.count > 2 {
                                        closePoints.removeFirst()
                                        closePoints.removeFirst()
                                    }
                                }
                                orderedPoints = []
                                orderedPoints.append([closePoints[0], closePoints[1]])
                                toClose = true
                                
                            }
                        
                            
                            // no single stroke to close
                            if !toClose {
                                // check if the strokes in the drawing form a closed stroke
                                toClose = searchEdges(points: closePoints, numStrokes: newNumOfStrokes, strokes: canvasView.drawing.strokes)
                                
                            }
                            if toClose {
                               
                                if lastClosed && canvasView.drawing.strokes.count > 1 {
                                    canvasView.drawing.strokes.removeFirst()
                                }
                                
                                var closedStroke: [PKStroke] = []
                                for couple in orderedPoints {
                                    
                                    let p1 = PKStrokePoint(location: couple[0], timeOffset: 0.1, size: (path?.first!.size)!, opacity: 1, force: 1, azimuth: 0, altitude: 0)
                                    let p2 = PKStrokePoint(location: couple[1], timeOffset: 0.1, size: (path?.last!.size)!, opacity: 1, force: 1, azimuth: 0, altitude: 0)
                                    let path1 = PKStrokePath(controlPoints: [p1, p2], creationDate: Date())
                                    let stroke = PKStroke(ink: PKInk(.pen, color: .red), path: path1)
                                    //add strokes that close the drawen path to closedStroke
                                    closedStroke.append(stroke)
                                }
                                
                                closePoints = []
                                
                                for stroke in canvasView.drawing.strokes {
                                    closedStroke.append(stroke)
                                }
                                canvasView.drawing.strokes.removeAll()
                                //group of points that will make the final closed stroke
                                var strokePoints: [PKStrokePoint] = []
                                
                                // create final stroke (not ordered)
                                for stroke in closedStroke {
                                    for point in stroke.path.interpolatedPoints(by: .distance(distancePoints)) {
                                        strokePoints.append(point)
                                        
                                    }
                                }
                                
                                //order final stroke
                                var orderPoints: [PKStrokePoint] = []
                                var firstPoint = strokePoints.removeFirst()
                                orderPoints.append(firstPoint)
                                while strokePoints.count != 0 {
                                    strokePoints = strokePoints.sorted(by: {distance(point1: $0, point2: firstPoint)<distance(point1: $1, point2: firstPoint)})
                                    firstPoint = strokePoints.first!
                                    orderPoints.append(strokePoints.removeFirst())
                                }
                                
                                let newPath = PKStrokePath(controlPoints: orderPoints, creationDate: Date())
                                let myStroke = PKStroke(ink: PKInk(.pen, color: .green), path: newPath)
                                orderedPoints = []
                                lastClosed = true
                                toClose = false
                                canvasView.drawing.strokes.append(myStroke)
                                
                                parent.tool =  PKInkingTool(.pen, color: UIColor(.red), width: 2)
                                
                                check = true
                            }
                            else {
                                
                                check = false
                                // check if the new stroke is far from the previous one; in that case, the previous is deleted
                                if (orderedPoints == [] && lastClosed &&  closePoints.count == 2) {
                                    //print("deleting first stroke")
                                    canvasView.drawing.strokes.removeFirst()
                                }
                                // check if the new stroke is far from the previous multiple strokes (which are close to each other); in that case, the previous strokes are deleted
                                if (!lastClosed && (closePoints.count > orderedPoints.count*2+2)) {
                                    //print("deleting first strokes")
                                    
                                    let toDelete = closePoints.count/2
                                    
                                        for _ in 0..<toDelete-1 {
                                            if canvasView.drawing.strokes.count > 1 {
                                                canvasView.drawing.strokes.removeFirst()
                                                
                                            }
                                            closePoints.removeFirst()
                                            closePoints.removeFirst()
                                        }
                                    orderedPoints = []
                                    
                                }
                                            
                                
                                check = true
                                lastClosed = false
                            }
                        }
                    // get new number od strokes in drawing
                        numOfStrokes = canvasView.drawing.strokes.count
                    }
                    
            }
            else {
                // drawing is empty
                orderedPoints = []
                closePoints = []
                numOfStrokes = 0
                lastClosed = false
            }
            
            
            
        }
        
        // for every couple of points - first and last point of every stroke - i search for couples of close ones to cloe them
        // every time i find a couple i call the function again without the couple: if the array remains empty, it means all vertices have a match so the stroke is closed
        func searchEdges(points: [CGPoint], numStrokes: Int, strokes: [PKStroke]) -> Bool {
            let count = strokes.count
                    for i in 0..<points.count {
                        for j in 0..<points.count {
                            if i != j {
                                //print("first point: ", points[i].x, points[i].y, " second point: ", points[j].x, points[j].y)
                                if (abs(points[i].x-points[j].x)<maximumToClose && abs(points[i].y-points[j].y)<maximumToClose) {
                                    if !orderedPoints.contains([points[i],points[j]]) && !orderedPoints.contains([points[j],points[i]]) {
                                        orderedPoints.append([points[i],points[j]])
                                        var newPoints = points
                                        newPoints.remove(at: i)
                                        newPoints.remove(at: j-1)
                                        let newNumStrokes = numStrokes-1
                                        
                                        //print("inside searchedges numofstrokes: ", newNumStrokes)
                                        if orderedPoints.count == count || (count == 2 && lastClosed) {
                                            return true
                                        }
                                        else {
                                            return searchEdges(points: newPoints, numStrokes: newNumStrokes, strokes: strokes)
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                    return false
                }
                
        
        //calculate distance between two points
        func distance(point1: PKStrokePoint, point2: PKStrokePoint) -> CGFloat
            {
                let distanceX = abs(point1.location.x-point2.location.x)*abs(point1.location.x-point2.location.x)
                let distanceY = abs(point1.location.y-point2.location.y)*abs(point1.location.y-point2.location.y)
                let distance = sqrt(distanceX+distanceY)
                return distance
            }
        
        
    }
    
  
}
