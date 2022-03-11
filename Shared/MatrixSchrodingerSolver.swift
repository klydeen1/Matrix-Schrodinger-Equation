//
//  MatrixSchrodingerSolver.swift
//  Matrix-Schrodinger-Equation
//
//  Created by Katelyn Lydeen on 3/11/22.
//

import Foundation
import CorePlot

class MatrixSchrodingerSolver: NSObject, ObservableObject {
    @Published var enableButton = true
    
    var rk4PsiCalculator = SchrodingerSolver()
    
    // Parameters and results for the 1D particle in a box
    var xMax = 10.0
    let xStep = 0.01
    var basisPsiArrays: [[Double]] = [] // Solutions to the 1D particle in a box
    var basisEnergyArray: [Double] = [] // Eigenenergies for the 1D particle in a box
    
    // Data for plots
    var newDataPoints: [plotDataType] =  []
    var plotDataModel: PlotDataClass? = nil
    
    let hBarSquaredOverM = 7.61996423107385308868
    
    func getWavefunction() async {
        // Calculate the basis wavefunctions only if they haven't been calculated yet
        if basisPsiArrays.isEmpty {
            await getBasisWavefunctions()
        }
        
        //
    }
    
    /// getBasisWavefunctions
    /// Gets the solutions to the 1D particle in a box using the differential form of the equation (solved using Runge Kutta 4)
    func getBasisWavefunctions() async {
        // Get the square well potential
        let potentialCalculator = await OneDPotentials(withData: true)
        potentialCalculator.potentialType = "Square Well"
        potentialCalculator.xMax = xMax
        potentialCalculator.xStep = xStep
        await potentialCalculator.setPotential()
        
        // Get the solutions for the square well between 0.01 and 10.0 eV
        rk4PsiCalculator.xArray = potentialCalculator.xArray
        rk4PsiCalculator.VArray = potentialCalculator.VArray
        rk4PsiCalculator.xStep = xStep
        rk4PsiCalculator.minEnergy = 0.005
        rk4PsiCalculator.maxEnergy = 10.0
        await rk4PsiCalculator.getWavefunction()
        basisPsiArrays = rk4PsiCalculator.validPsiArrays
        basisEnergyArray = rk4PsiCalculator.validEnergyArray
        /*
        for (_, energy) in basisEnergyArray.enumerated() {
            print(energy)
        }
         */
    }
    
    /// setButton Enable
    /// Toggles the state of the Enable Button on the Main Thread
    /// - Parameter state: Boolean describing whether the button should be enabled.
    @MainActor func setButtonEnable(state: Bool) {
        if state {
            Task.init {
                await MainActor.run {
                    self.enableButton = true
                }
            }
        }
        else{
            Task.init {
                await MainActor.run {
                    self.enableButton = false
                }
            }
        }
    }

}
