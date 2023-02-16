//
//  DrawingView.swift
//  PencilAnnotate
//

import SwiftUI
import PencilKit
import Foundation

struct DrawingView: UIViewRepresentable {
   
    
    @Binding var canvas: PKCanvasView
    @Binding var type: PKInkingTool.InkType
    @Binding var color: Color
    @Binding var sent: Bool
    @Binding var img: UIImage
    @Binding var isDrawing: Bool
    
    
     var width: CGFloat = 2
     var ink : PKInkingTool {
        
         PKInkingTool(type, color: UIColor(color), width: width)
         
    }
   
    
    func makeUIView(context: Context) -> PKCanvasView {
        print("new view!")
        canvas.isOpaque = false
        canvas.backgroundColor = UIColor.white
        
        canvas.becomeFirstResponder()
        
        let imgView = UIImageView(image: img)
        
        let content = canvas.subviews[0]
        content.addSubview(imgView)
        content.sendSubviewToBack(imgView)
        canvas.subviews[1].isOpaque = false
        canvas.drawingPolicy = .anyInput
        
        canvas.tool = ink
        canvas.delegate = context.coordinator

        return canvas
    }
    
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        print("trying update")
        
        /*if (sent) {
            print("sent!")
            let imgView = UIImageView(image: img)
            print(imgView)
            if uiView.subviews[0].accessibilityElementCount() > 2 {
                print(uiView.subviews.description)
                uiView.subviews[0].removeFromSuperview()
                print("changing image")
                
                let newContent = uiView.subviews[0]
                newContent.addSubview(imgView)
                newContent.sendSubviewToBack(imgView)
                
                print("done change")
            }
            
           
        }*/
        if (isDrawing) {
            uiView.tool = ink
        }
        else {
            uiView.drawingGestureRecognizer.isEnabled = false
        }
        
        
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
        var maximumToClose: CGFloat = 50
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
                    print("_______________________")
                    check = false
                    
                    //check if a stroke has been deleted; the number of strokes could have decreased because a stroke has been closed
                    //so I check with lastClosed that this isn't the case; if it is, closePoints and orderedPoints are empty
                    let newNumOfStrokes = canvasView.drawing.strokes.count
                    print("prev number of strokes: ", numOfStrokes)
                    print("current number of strokes: ", newNumOfStrokes)
                    if newNumOfStrokes < numOfStrokes && !lastClosed {
                        print("deleting points")
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
                        let ink = canvasView.drawing.strokes.last!.ink
                        
                           
                            // add points of open line to array closePoints
                            closePoints.append((path?.first?.location)!)
                            closePoints.append((path?.last?.location)!)
                            print("closePointsHere1: ", closePoints)
                        
                            // case sigle stroke is closed
                            if searchEdges(points: [(path?.first?.location)!, (path?.last?.location)!], numStrokes: 1, strokes: [canvasView.drawing.strokes.last!] ) {
                                print("closing single stroke")
                                while canvasView.drawing.strokes.count > 1 {
                                    canvasView.drawing.strokes.removeFirst()
                                    if closePoints.count > 2 {
                                        closePoints.removeFirst()
                                        closePoints.removeFirst()
                                    }
                                }
                                orderedPoints = []
                                orderedPoints.append([closePoints[0], closePoints[1]])
                                print("ordered points of single stroke", orderedPoints)
                                toClose = true
                                
                            }
                        
                            print("closePointsHere: ", closePoints)
                            
                            // no single stroke to close
                            if !toClose {
                                print("not a single stroke")
                                // check if the strokes in the drawing form a closed stroke
                                toClose = searchEdges(points: closePoints, numStrokes: newNumOfStrokes, strokes: canvasView.drawing.strokes)
                                
                            }
                            if toClose {
                                
                                if lastClosed && canvasView.drawing.strokes.count > 1 {
                                    canvasView.drawing.strokes.removeFirst()
                                }
                                print("strokes to unite: ", canvasView.drawing.strokes)
                                print("edges found")
                                print("uniting edges: ", orderedPoints)
                                
                                var closedStroke: [PKStroke] = []
                                for couple in orderedPoints {
                                    
                                    let p1 = PKStrokePoint(location: couple[0], timeOffset: 0.1, size: (path?.first!.size)!, opacity: 1, force: 1, azimuth: 0, altitude: 0)
                                    let p2 = PKStrokePoint(location: couple[1], timeOffset: 0.1, size: (path?.last!.size)!, opacity: 1, force: 1, azimuth: 0, altitude: 0)
                                    let path1 = PKStrokePath(controlPoints: [p1, p2], creationDate: Date())
                                    
                                    let stroke = PKStroke(ink: parent.drawing.strokes.last!.ink, path: path1)
                                    //add strokes that close the drawen path to closedStroke
                                    closedStroke.append(stroke)
                                }
                                
                                closePoints = []
                                
                                for stroke in canvasView.drawing.strokes {
                                    print("stroke to append: ", stroke)
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
                                let myStroke = PKStroke(ink: ink, path: newPath)
                                orderedPoints = []
                                lastClosed = true
                                toClose = false
                                canvasView.drawing.strokes.append(myStroke)
                                
                                check = true
                            }
                            else {
                                
                                check = false
                                print("ordered points: ", orderedPoints.count)
                                // check if the new stroke is far from the previous one; in that case, the previous is deleted
                                if (orderedPoints == [] && lastClosed &&  closePoints.count == 2) {
                                    print("deleting first stroke")
                                    canvasView.drawing.strokes.removeFirst()
                                }
                                // check if the new stroke is far from the previous multiple strokes (which are close to each other); in that case, the previous strokes are deleted
                                if (!lastClosed && (closePoints.count > orderedPoints.count*2+2)) {
                                    print("deleting first strokes")
                                    
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
                                            
                                    
                                print("points that are close:", closePoints )
                                print("num of strokes: ", canvasView.drawing.strokes.count)
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
                    print(points)
                    for i in 0..<points.count {
                        for j in 0..<points.count {
                            if i != j {
                                print("first point: ", points[i].x, points[i].y, " second point: ", points[j].x, points[j].y)
                                if (abs(points[i].x-points[j].x)<maximumToClose && abs(points[i].y-points[j].y)<maximumToClose) {
                                    print("here1")
                                    if !orderedPoints.contains([points[i],points[j]]) && !orderedPoints.contains([points[j],points[i]]) {
                                        orderedPoints.append([points[i],points[j]])
                                        var newPoints = points
                                        newPoints.remove(at: i)
                                        newPoints.remove(at: j-1)
                                        print("points: ", newPoints)
                                        let newNumStrokes = numStrokes-1
                                        print("to insert: ", [points[i],points[j]])
                                        
                                        print("ordered points: ", orderedPoints)
                                        print("inside searchedges numofstrokes: ", newNumStrokes)
                                        if orderedPoints.count == count || (count == 2 && lastClosed) {
                                            return true
                                        }
                                        else {
                                            print("inside recursive num strokes: ", newNumStrokes)
                                            return searchEdges(points: newPoints, numStrokes: newNumStrokes, strokes: strokes)
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                    print("no")
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
