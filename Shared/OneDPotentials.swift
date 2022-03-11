//
//  OneDPotentials.swift
//  1D-Schrodinger-Equation
//
//  Created by Katelyn Lydeen on 2/18/22.
//

import Foundation
import CorePlot

class OneDPotentials: NSObject, ObservableObject {
    @Published var xArray = [Double]() // Array holding x-values for the potential
    @Published var VArray = [Double]() // Array holding the potentials V(x)
    @Published var dataPoints :[plotDataType] =  []
    
    var potentialType = "Square Well"
    var xMin = 0.0
    var xMax = 10.0
    var xStep = 0.1
    //var newXStep = 0.1
    let hBarSquaredOverM = 7.61996423107385308868
    var newXArray = [Double]()
    var newVArray = [Double]()
    var newDataPoints: [plotDataType] =  []
    var plotDataModel: PlotDataClass? = nil
    
    @MainActor init(withData data: Bool) {
        super.init()
        xArray = []
        VArray = []
        dataPoints = []
    }
    
    func setPotential() async {
        await calculatePotential(potentialType: potentialType, xMin: xMin, xMax: xMax, xStep: xStep)
        
        await updateXArray(xArray: newXArray)
        await updateVArray(VArray: newVArray)
        //await updateXStep(xStep: newXStep)
        await updateDataPoints(dataPoints: newDataPoints)
    }
    
    func calculatePotential(potentialType: String, xMin: Double, xMax: Double, xStep: Double) async {
        newXArray = []
        newVArray = []
        newDataPoints = []
        var count = 0
        await clearPotential()
        
        switch potentialType {
        case "Square Well":
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, through: xMax-xStep, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)
                
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            
        case "Linear Well":
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, through: xMax-xStep, by: xStep) {
                newXArray.append(i)
                newVArray.append((i-xMin)*4.0*1.3)
                
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            
        case "Parabolic Well":
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, through: xMax-xStep, by: xStep) {
                newXArray.append(i)
                newVArray.append((pow((i-(xMax+xMin)/2.0), 2.0)/1.0))
                
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            
        case "Square + Linear Well":
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, to: (xMax+xMin)/2.0, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)
                
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            for i in stride(from: (xMin+xMax)/2.0, through: xMax-xStep, by: xStep) {
                newXArray.append(i)
                newVArray.append(((i-(xMin+xMax)/2.0)*4.0*0.1))
                
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            
        case "Square Barrier":
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, to: xMin + (xMax-xMin)*0.4, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)
                
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            for i in stride(from: xMin + (xMax-xMin)*0.4, to: xMin + (xMax-xMin)*0.6, by: xStep) {
                newXArray.append(i)
                newVArray.append(15.000000001)
                
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            for i in stride(from: xMin + (xMax-xMin)*0.6, to: xMax, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)
                
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            
        case "Triangle Barrier":
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, to: xMin + (xMax-xMin)*0.4, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)

                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            for i in stride(from: xMin + (xMax-xMin)*0.4, to: xMin + (xMax-xMin)*0.5, by: xStep) {
                newXArray.append(i)
                newVArray.append((abs(i-(xMin + (xMax-xMin)*0.4))*3.0))
                            
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            for i in stride(from: xMin + (xMax-xMin)*0.5, to: xMin + (xMax-xMin)*0.6, by: xStep) {
                newXArray.append(i)
                newVArray.append((abs(i-(xMax - (xMax-xMin)*0.4))*3.0))
                            
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            for i in stride(from: xMin + (xMax-xMin)*0.6, to: xMax, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)
                            
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            
        case "Coupled Parabolic Well":
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, to: xMin + (xMax-xMin)*0.5, by: xStep) {
                newXArray.append(i)
                newVArray.append((pow((i-(xMin+(xMax-xMin)/4.0)), 2.0)))
                     
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
                 
            for i in stride(from: xMin + (xMax-xMin)*0.5, through: xMax-xStep, by: xStep) {
                newXArray.append(i)
                newVArray.append((pow((i-(xMax-(xMax-xMin)/4.0)), 2.0)))
                     
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            
        case "Coupled Square Well + Field":
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, to: xMin + (xMax-xMin)*0.4, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)
            }
            for i in stride(from: xMin + (xMax-xMin)*0.4, to: xMin + (xMax-xMin)*0.6, by: xStep) {
                newXArray.append(i)
                newVArray.append(4.0)
            }
            for i in stride(from: xMin + (xMax-xMin)*0.6, to: xMax, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)
            }
            for i in 1 ..< (newXArray.count) {
                newVArray[i] += ((newXArray[i]-xMin)*4.0*0.1)
                let dataPoint: plotDataType = [.X: newXArray[i], .Y: newVArray[i]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            
        case "Harmonic Oscillator":
            let xMinHO = -20.0
            let xMaxHO = 20.0
            let xStepHO = 0.001
                    
            startPotential(xMin: xMinHO+xMaxHO, xMax: xMaxHO+xMaxHO, xStep: xStepHO)
            for i in stride(from: xMinHO+xStepHO, through: xMaxHO-xStepHO, by: xStepHO) {
                newXArray.append(i+xMaxHO)
                newVArray.append((pow((i-(xMaxHO+xMinHO)/2.0), 2.0)/15.0))
                        
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMinHO+xMaxHO, xMax: xMaxHO+xMaxHO, xStep: xStepHO)
            
        case "Kronig - Penney":
            let xMinKP = 0.0
            let xStepKP = 0.001
                    
            let numberOfBarriers = 10.0
            let boxLength = 10.0
            let barrierPotential = 100.0*hBarSquaredOverM/2.0
            let latticeSpacing = boxLength/numberOfBarriers
            let barrierWidth = 1.0/6.0*latticeSpacing
            var barrierNumber = 1;
            var currentBarrierPosition = 0.0
            var inBarrier = false;
            let xMaxKP = boxLength
                    
            startPotential(xMin: xMinKP, xMax: xMaxKP, xStep: xStepKP)
                    
            for i in stride(from: xMinKP+xStepKP, through: xMaxKP-xStepKP, by: xStepKP) {
                currentBarrierPosition = -latticeSpacing/2.0 + Double(barrierNumber)*latticeSpacing
                if ((abs(i-currentBarrierPosition)) < (barrierWidth/2.0)) {
                    inBarrier = true
      
                    newXArray.append(i)
                    newVArray.append(barrierPotential)
                            
                    count = newXArray.count
                    let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                    newDataPoints.append(dataPoint)
                }
                else {
                    if (inBarrier) {
                        inBarrier = false
                        barrierNumber += 1
                    }
                            
                    newXArray.append(i)
                    newVArray.append(0.0)
                            
                    count = newXArray.count
                    let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                    newDataPoints.append(dataPoint)
                }
            }
                    
            newXArray.append(xMax)
            newVArray.append(5000000.0)
                    
            let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
            newDataPoints.append(dataPoint)
                    
            /*
            /** Fixes Bug In Plotting Library not displaying the last point **/
            dataPoint = [.X: xMax+xStep, .Y: 5000000.0]
            contentArray.append(dataPoint)
                    
            let xMin = potential.minX(minArray: potential.oneDPotentialXArray)
            let xMax = potential.maxX(maxArray: potential.oneDPotentialXArray)
            let yMin = potential.minY(minArray: potential.oneDPotentialYArray)
            var yMax = potential.maxY(maxArray: potential.oneDPotentialYArray)
                    
            if yMax > 500 { yMax = 10}
                    
            makePlot(xLabel: "x Å", yLabel: "Potential V", xMin: (xMin - 1.0), xMax: (xMax + 1.0), yMin: yMin-1.2, yMax: yMax+0.2)
                    
            contentArray.removeAll()
            */
            
        case "KP2-a":
            var dataPoint: plotDataType = [:]
            var count = 0
                    
            let xMinKP = 0.0
                    
            let xStepKP = 0.001
                    
            // let numberOfBarriers = 2.0
            let boxLength = 10.0
            let barrierPotential = 100.0*hBarSquaredOverM/2.0
            let latticeSpacing = 1.0 //boxLength/numberOfBarriers
            let barrierWidth = 1.0/6.0*latticeSpacing
            var barrierNumber = 1;
            var currentBarrierPosition = 0.0
            var inBarrier = false;
                    
            let xManKP = boxLength
                    
            newXArray.append(xMinKP)
            newVArray.append(5000000.0)
            dataPoint = [.X: newXArray[0], .Y: newVArray[0]]
            newDataPoints.append(dataPoint)
                    
            for i in stride(from: xMinKP+xStepKP, through: xManKP-xStepKP, by: xStepKP) {
                        
                let term = (-latticeSpacing/2.0) * (pow(-1.0, Double(barrierNumber))) - Double(barrierNumber)*Double(barrierNumber-1) * (pow(-1.0, Double(barrierNumber)))
                        
                currentBarrierPosition =  term + Double(barrierNumber)*latticeSpacing*4.0
                        
                if( (abs(i-currentBarrierPosition)) < (barrierWidth/2.0)) {
                            
                    inBarrier = true
                            
                    newXArray.append(i)
                    newVArray.append(barrierPotential)
                            
                    let count = newXArray.count - 1
                    let dataPoint: plotDataType = [.X: newXArray[count], .Y: newVArray[count]]
                    newDataPoints.append(dataPoint)
                            
                }
                else {
                    if (inBarrier){
                        inBarrier = false
                        barrierNumber += 1
                    }
                            
                    newXArray.append(i)
                    newVArray.append(0.0)
                            
                    let count = newXArray.count - 1
                    let dataPoint: plotDataType = [.X: newXArray[count], .Y: newVArray[count]]
                    newDataPoints.append(dataPoint)
                }
            }
                    
            count = newXArray.count
            newXArray.append(xManKP)
            newVArray.append(5000000.0)
            dataPoint = [.X: newXArray[count-1], .Y: newVArray[count-1]]
            newDataPoints.append(dataPoint)
            
        default:
            // Default to the square well
            startPotential(xMin: xMin, xMax: xMax, xStep: xStep)
            for i in stride(from: xMin+xStep, through: xMax-xStep, by: xStep) {
                newXArray.append(i)
                newVArray.append(0.0)
                count = newXArray.count
                let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
                newDataPoints.append(dataPoint)
            }
            finishPotential(xMin: xMin, xMax: xMax, xStep: xStep)
        }
    }
    
    /// clearPotential
    /// Sets the arrays for the x values, potentials, and plot data points to empty arrays
    @MainActor func clearPotential() {
        self.xArray = []
        self.VArray = []
        self.dataPoints = []
    }
    
    func startPotential(xMin: Double, xMax: Double, xStep: Double) {
        var count = 0
        newXArray.append(xMin)
        newVArray.append(10000000.0)
        
        count = newXArray.count
        let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
        newDataPoints.append(dataPoint)
    }
    
    func finishPotential(xMin: Double, xMax: Double, xStep: Double) {
        var count = 0
        newXArray.append(xMax)
        newVArray.append(10000000.0)
        
        count = newXArray.count
        let dataPoint: plotDataType = [.X: newXArray[count-1], .Y: newVArray[count-1]]
        newDataPoints.append(dataPoint)
    }
    
    /// updateXArray
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter xArray: contains the array of x values
    @MainActor func updateXArray(xArray: [Double]) async {
        self.xArray = xArray
    }
    
    /// updateVArray
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter VArray: contains the array of potential values
    @MainActor func updateVArray(VArray: [Double]) async {
        self.VArray = VArray
    }
    
    /// updateXStep
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter xStep: the double value representing the x value difference between points in xArray
    @MainActor func updateXStep(xStep: Double) async {
        self.xStep = xStep
    }
    
    /// updateDataPoints
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter xArray: contains the array of plot data points for the potential vs. x
    @MainActor func updateDataPoints(dataPoints: [plotDataType]) async {
        self.dataPoints = dataPoints
    }
    
    /// getPlotData
    /// Sets plot properties and appends the current value of dataPoints to the plot data model
    /// Note: This does NOT recalculate the potential. calculatePotential must be used before calling this function in order to get the correct data
    func getPlotData() async {
        // Clear any existing plot data
        await plotDataModel!.zeroData()
        
        // Set x-axis limits
        await plotDataModel!.changingPlotParameters.xMax = xMax + 0.5
        await plotDataModel!.changingPlotParameters.xMin = xMin - 0.5
        // Set y-axis limits
        await plotDataModel!.changingPlotParameters.yMax = 100.5
        await plotDataModel!.changingPlotParameters.yMin = -0.5
            
        // Set title and other attributes
        await plotDataModel!.changingPlotParameters.title = potentialType + " Potential"
        await plotDataModel!.changingPlotParameters.xLabel = "Position"
        await plotDataModel!.changingPlotParameters.yLabel = "Potential"
        await plotDataModel!.changingPlotParameters.lineColor = .red()
            
        // Get plot data
        await plotDataModel!.appendData(dataPoint: dataPoints)
    }
}
