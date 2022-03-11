//
//  ContentView.swift
//  Shared
//
//  Created by Katelyn Lydeen on 3/11/22.
//

import SwiftUI
import CorePlot

typealias plotDataType = [CPTScatterPlotField : Double]

struct ContentView: View {
    @ObservedObject var plotDataModel = PlotDataClass(fromLine: true)
    @ObservedObject var matrixPsiCalculator = MatrixSchrodingerSolver()
    
    var body: some View {
        HStack {
            Button("Calculate Data", action: {Task.init{await self.calculateFunctions()}})
                .padding()
                .disabled(matrixPsiCalculator.enableButton == false)
        }
    }
    
    func calculateFunctions() async {
        await matrixPsiCalculator.getBasisWavefunctions()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
