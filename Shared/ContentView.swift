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
    @ObservedObject var potentialCalculator = OneDPotentials(withData: true)
    @ObservedObject var matrixPsiCalculator = MatrixSchrodingerSolver()
    
    // User inputted variables
    @State var minEnergyString = "0.01"
    @State var maxEnergyString = "10.0"
    @State var wellSizeString = "10.0"
    @State var xStepString = "0.01"
    
    // Dropdown menu selections
    @State var selectedPotential = "Square Well"
    @State var selectedPlot = "Wavefunction"
    @State var selectedEnergy = ""
    @State var selectedEnergyIndex = 0
    @State var energies = [""]
    var plots = ["Potential", "Wavefunction"]
    var potentials = ["Square Well", "Linear Well", "Parabolic Well", "Square + Linear Well", "Square Barrier", "Triangle Barrier", "Coupled Parabolic Well", "Coupled Square Well + Field", "Harmonic Oscillator", "Kronig - Penney", "KP2-a"]
    
    var body: some View {
        HStack{
            VStack{
                HStack {
                    VStack(alignment: .center) {
                        Text("Well Size (A)")
                            .font(.callout)
                            .bold()
                        TextField("# Well Size (A)", text: $wellSizeString)
                            .padding()
                    }
                    
                    VStack(alignment: .center) {
                        Text("Spacing Between x Values")
                            .font(.callout)
                            .bold()
                        TextField("# Spacing Between x Values", text: $xStepString)
                            .padding()
                    }
                }
                
                HStack {
                    VStack(alignment: .center) {
                        Text("Minimum Energy (eV)")
                            .font(.callout)
                            .bold()
                        TextField("# Minimum Energy (eV)", text: $minEnergyString)
                            .padding()
                    }
                    
                    VStack(alignment: .center) {
                        Text("Maximum Energy (eV)")
                            .font(.callout)
                            .bold()
                        TextField("# Maximum Energy (eV)", text: $maxEnergyString)
                            .padding()
                    }
                }
                
                // Drop down menu (picker) for setting the potential
                VStack {
                    Text("Potential Type")
                        .font(.callout)
                        .bold()
                    Picker("", selection: $selectedPotential) {
                        ForEach(potentials, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                VStack {
                    Text("Plot Type")
                        .font(.callout)
                        .bold()
                    Picker("", selection: $selectedPlot) {
                        ForEach(plots, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                VStack {
                    Text("Energy Value (eV)")
                        .font(.callout)
                        .bold()
                    Picker("", selection: $selectedEnergy) {
                        ForEach(energies, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                HStack {
                    Button("Calculate Data", action: {Task.init{await self.calculateFunctions()}})
                        .padding()
                        .disabled(matrixPsiCalculator.enableButton == false)
                    
                    Button("Update Plot", action: {Task.init{await self.generatePlots()}})
                        .padding()
                        .disabled(matrixPsiCalculator.enableButton == false)
                    
                    Button("Clear", action: {self.clear()})
                        .padding()
                        .disabled(matrixPsiCalculator.enableButton == false)
                }

                if (!matrixPsiCalculator.enableButton){
                    ProgressView()
                }
            }
        
            // Stop the window shrinking to zero.
            Spacer()
            CorePlot(dataForPlot: $plotDataModel.plotData, changingPlotParameters:  $plotDataModel.changingPlotParameters)
                .setPlotPadding(left: 10)
                .setPlotPadding(right: 10)
                .setPlotPadding(top: 10)
                .setPlotPadding(bottom: 10)
                .padding()
            Divider()
        }
    }
    
    /// calculateFunctions
    /// Runs appropriate functions to calculate the potential and wavefunction
    /// Also runs generatePlots to get and display plot data
    func calculateFunctions() async {
        self.energies = [""] // Clear the energy array
        
        // Tell potentialCalculator which potential the user chose
        potentialCalculator.potentialType = selectedPotential
        
        // Disable the calculate button
        matrixPsiCalculator.setButtonEnable(state: false)
        
        // Send the well size and xStep to potentialCalculator
        potentialCalculator.xMax = Double(wellSizeString)!
        potentialCalculator.xStep = Double(xStepString)!
        
        // Get the arrays for x and the potential from potentialCalculator
        await potentialCalculator.setPotential()
        
        // Send the x and potential arrays to psiCalculator
        matrixPsiCalculator.xArray = potentialCalculator.xArray
        matrixPsiCalculator.VArray = potentialCalculator.VArray
        
        // Get the wavefunction result from psiCalculator
        await matrixPsiCalculator.getWavefunctions()
        
        // Set the array of energy eigenvalues used for the picker
        self.energies = []
        for energy in matrixPsiCalculator.validEnergyArray {
            self.energies.append(String(format: "%.3f", energy))
        }
        
        // Plot the data
        await generatePlots()
        
        // Enable the calculate button
        matrixPsiCalculator.setButtonEnable(state: true)
    }
    
    /// setupPlotDataModel
    /// Tells psiCalculator and potentialCalculator which plot data model to use
    @MainActor func setupPlotDataModel() {
        matrixPsiCalculator.plotDataModel = self.plotDataModel
        potentialCalculator.plotDataModel = self.plotDataModel
    }
    
    /// generatePlots
    /// Runs the functions to plot either the wavefunction or the potential depending on user selection
    /// This does not update any data except for the plot type. When choosing different parameters such as potential type, calculateFunctions must be called first
    func generatePlots() async {
        // Disable the calculate button
        matrixPsiCalculator.setButtonEnable(state: false)
        
        // Get the index of the chosen energy eigenvalue
        selectedEnergyIndex = energies.firstIndex(of: selectedEnergy) ?? 0
        
        setupPlotDataModel()
        
        if (selectedPlot == "Wavefunction") {
            await matrixPsiCalculator.getPlotDataFromPsiArray(index: selectedEnergyIndex)
        }
        else if (selectedPlot == "Potential") {
            await potentialCalculator.getPlotData()
        }
        
        // Enable the calculate button
        matrixPsiCalculator.setButtonEnable(state: true)
    }
    
    /// clear
    /// Clears the plot display and empties the array of energies listed in the dropdown menu
    @MainActor func clear() {
        plotDataModel.zeroData()
        self.energies = [""]
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
