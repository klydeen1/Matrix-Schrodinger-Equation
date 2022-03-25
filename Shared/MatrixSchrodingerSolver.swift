//
//  MatrixSchrodingerSolver.swift
//  Matrix-Schrodinger-Equation
//
//  Created by Katelyn Lydeen on 3/11/22.
//

import Foundation
import CorePlot
import Accelerate

class MatrixSchrodingerSolver: NSObject, ObservableObject {
    @Published var validPsiArrays: [[Double]] = []
    @Published var validEnergyArray: [Double] = []
    @Published var enableButton = true
    @Published var dataPoints :[plotDataType] =  []
    
    var rk4PsiCalculator = SchrodingerSolver()
    
    // Parameters and results for the 1D particle in a box
    var xMax = 10.0
    var xStep = 0.01
    var basisPsiArrays: [[Double]] = [] // Solutions to the 1D particle in a box
    var basisEnergies: [Double] = [] // Eigenenergies for the 1D particle in a box
    var numStates = 10
    
    // Parameters and results for the matrix solution
    var hamiltonian: [[Double]] = []
    // Variables relating to the potential
    var xArray = [Double]() // Array holding x-values for the potential
    var VArray = [Double]() // Array holding the potentials V(x)
    var calculatedValidEnergies = [Double]()
    var calculatedValidPsi = [[Double]]()
    var calculatedPsiArray = [Double]()
    var eigenvectors: [[Double]] = []
    
    var oldXMax = 10.0
    var oldXStep = 0.01
    var wellParametersChanged = false
    
    // Data for plots
    var newDataPoints: [plotDataType] =  []
    var allValidPsiPlotData: [[plotDataType]] = []
    var plotDataModel: PlotDataClass? = nil
    
    let hBarSquaredOverM = 7.61996423107385308868
    
    /// getWavefunctions
    /// Calculates the valid wavefunctions and energies for the Schrodinger equation using the matrix form. The basis functions are the 1d particle in a box solution
    func getWavefunctions() async {
        // Reset some arrays to empty
        allValidPsiPlotData = []
        calculatedValidPsi = []
        calculatedValidEnergies = []
        
        // Determine if the well size or number of steps has changed
        if (xMax != oldXMax || xStep != oldXStep) {
            wellParametersChanged = true
            oldXMax = xMax
            oldXStep = xStep
        }
        
        // Calculate the basis wavefunctions only if they haven't been calculated yet or if the well parameters have changed
        if (basisPsiArrays.isEmpty || wellParametersChanged) {
            await getBasisWavefunctions()
        }
        
        // The number of states is based on user input but the number is capped at basisEnergies.count
        if numStates > basisEnergies.count {
            numStates = basisEnergies.count
        }
        
        // Construct the Hamiltonian and find the eigenvalues and eigenvectors
        hamiltonian = []
        await constructHamiltonian()
        if !hamiltonian.isEmpty {
            await calculateHamiltonianEigenvalues()
        }
        
        // Get the wavefunction results as a linear combination of the basis wavefunctions
        if !eigenvectors.isEmpty {
            for (_, eigenvector) in eigenvectors.enumerated() { // Array over all eigenvalues/energies
                calculatedPsiArray = []
                newDataPoints = []
                for i in 0..<eigenvector.count { // Array over each eigenvector component
                    for j in 0..<basisPsiArrays[Int(i)].count { // Array over each value of x
                        if (i == 0) {
                            calculatedPsiArray.append(basisPsiArrays[Int(i)][j]*eigenvector[i])
                        }
                        else {
                            calculatedPsiArray[j] += basisPsiArrays[Int(i)][j]*eigenvector[i]
                            if (i == eigenvector.count - 1) { // This is our last time running this loop
                                // Set the plot data
                                let dataPoint: plotDataType = [.X: xArray[j], .Y: calculatedPsiArray[j]]
                                newDataPoints.append(dataPoint)
                            }
                        }
                    }
                }
                calculatedValidPsi.append(calculatedPsiArray)
                allValidPsiPlotData.append(newDataPoints)
            }
            await updateValidEnergies(energyArray: calculatedValidEnergies)
            await updatePsiArrays(psiArray: calculatedValidPsi)
        }
    }
    
    /// getBasisWavefunctions
    /// Gets the normalized solutions to the 1D particle in a box using the differential form of the equation (solved using Runge Kutta 4)
    func getBasisWavefunctions() async {
        // Get the square well potential
        let potentialCalculator = await OneDPotentials(withData: true)
        potentialCalculator.potentialType = "Square Well"
        potentialCalculator.xMax = xMax
        potentialCalculator.xStep = xStep
        await potentialCalculator.setPotential()
        
        // Get the solutions for the square well between set energy values
        rk4PsiCalculator.xArray = potentialCalculator.xArray
        rk4PsiCalculator.VArray = potentialCalculator.VArray
        rk4PsiCalculator.xStep = xStep
        rk4PsiCalculator.minEnergy = 0.005
        rk4PsiCalculator.maxEnergy = 10000.0
        await rk4PsiCalculator.getWavefunction()
        basisPsiArrays = rk4PsiCalculator.validPsiArrays
        basisEnergies = rk4PsiCalculator.validEnergyArray
    }
    
    /// constructHamiltonian
    /// Creates the Hamiltonian matrix using all wavefunctions in the basis
    func constructHamiltonian() async {
        // The elements of the Hamiltonian are given by:
        // H_ij = <psi_i | H | psi_j> = <psi_i | E_i | psi_j> + <psi_i | V | psi_j>
        print("Number of states: \(numStates)")
        for i in 0..<numStates { // Iteration over rows
            var newRow: [Double] = []
            for j in 0..<numStates { // Iteration over columns
                var newValue = 0.0
                var potentialProduct = 0.0 // Variable for the inner product <psi_i | V | psi_j>
                
                // Handle array length mismatches
                var arrLength = 1
                if (basisPsiArrays[i].count < VArray.count) {
                    arrLength = basisPsiArrays[i].count
                }
                else {
                    arrLength = VArray.count
                }
                
                for x in 0..<arrLength {
                    let potential = VArray[x]
                    let psii = basisPsiArrays[i][x]
                    let psij = basisPsiArrays[j][x]
                    potentialProduct += potential*psii*psij
                    //potentialProduct += VArray[x] * basisPsiArrays[i][x] * basisPsiArrays[j][x]
                }
                potentialProduct /= (Double(arrLength))
                potentialProduct *= (xMax)
                
                if (i == j) {
                    // <psi_i | E_i | psi_j> evaluates to E_i
                    newValue = basisEnergies[i] + potentialProduct
                }
                else {
                    // <psi_i | E_i | psi_j> evaluates to 0
                    newValue = potentialProduct
                }
                newRow.append(newValue)
            }
            hamiltonian.append(newRow)
        }
        print(hamiltonian)
    }
    
    /// calculateHamiltonianEigenvalues
    /// Runs appropriate functions to calculate the eigenvalues and eigenvectors of the Hamiltonian matrix
    func calculateHamiltonianEigenvalues() async {
        calculatedValidEnergies = []
        eigenvectors = []
        allValidPsiPlotData = []
        let fortranArray = pack2dArray(arr: hamiltonian, rows: hamiltonian.count, cols: hamiltonian[0].count)
        _ = calculateEigenvalues(arrayForDiagonalization: fortranArray)
        // print(result)
    }
    
    /// pack2DArray
    /// Converts a 2D array into a linear array in FORTRAN Column Major Format
    /// From code created by Jeff Terry on 1/23/21.
    /// - Parameters:
    ///   - arr: 2D array
    ///   - rows: Number of Rows
    ///   - cols: Number of Columns
    /// - Returns: Column Major Linear Array
    func pack2dArray(arr: [[Double]], rows: Int, cols: Int) -> [Double] {
        var resultArray = Array(repeating: 0.0, count: rows*cols)
        for Iy in 0...cols-1 {
            for Ix in 0...rows-1 {
                let index = Iy * rows + Ix
                resultArray[index] = arr[Ix][Iy]
            }
        }
        return resultArray
    }
    
    /// calculateEigenvalues
    /// Based on code created by Jeff Terry on 1/23/21.
    /// Calculates the eigenvalues and eigenvectors for an inputted array. Adds these to parameters calculatedValidEnergies and eigenvectors
    /// - Parameter arrayForDiagonalization: linear Column Major FORTRAN Array for Diagonalization
    /// - Returns: String consisting of the Eigenvalues and Eigenvectors
    func calculateEigenvalues(arrayForDiagonalization: [Double]) -> String {
        /* Integers sent to the FORTRAN routines must be type Int32 instead of Int */
        //var N = Int32(sqrt(Double(startingArray.count)))
            
        var returnString = ""
            
        var N = Int32(sqrt(Double(arrayForDiagonalization.count)))
        var N2 = Int32(sqrt(Double(arrayForDiagonalization.count)))
        var N3 = Int32(sqrt(Double(arrayForDiagonalization.count)))
        var N4 = Int32(sqrt(Double(arrayForDiagonalization.count)))
            
        var flatArray = arrayForDiagonalization
            
        var error : Int32 = 0
        var lwork = Int32(-1)
        // Real parts of eigenvalues
        var wr = [Double](repeating: 0.0, count: Int(N))
        // Imaginary parts of eigenvalues
        var wi = [Double](repeating: 0.0, count: Int(N))
        // Left eigenvectors
        var vl = [Double](repeating: 0.0, count: Int(N*N))
        // Right eigenvectors
        var vr = [Double](repeating: 0.0, count: Int(N*N))
            
            
        /* Eigenvalue Calculation Uses dgeev */
        /*   int dgeev_(char *jobvl, char *jobvr, Int32 *n, Double * a, Int32 *lda, Double *wr, Double *wi, Double *vl,
            Int32 *ldvl, Double *vr, Int32 *ldvr, Double *work, Int32 *lwork, Int32 *info);*/
            
        /* dgeev_(&calculateLeftEigenvectors, &calculateRightEigenvectors, &c1, AT, &c1, WR, WI, VL, &dummySize, VR, &c2, LWork, &lworkSize, &ok)    */
        /* parameters in the order as they appear in the function call: */
        /* order of matrix A, number of right hand sides (b), matrix A, */
        /* leading dimension of A, array records pivoting, */
        /* result vector b on entry, x on exit, leading dimension of b */
        /* return value =0 for success*/
            
        /* Calculate size of workspace needed for the calculation */
            
        var workspaceQuery: Double = 0.0
        dgeev_(UnsafeMutablePointer(mutating: ("N" as NSString).utf8String), UnsafeMutablePointer(mutating: ("V" as NSString).utf8String), &N, &flatArray, &N2, &wr, &wi, &vl, &N3, &vr, &N4, &workspaceQuery, &lwork, &error)
            
        print("Workspace Query \(workspaceQuery)")
            
        /* size workspace per the results of the query */
            
        var workspace = [Double](repeating: 0.0, count: Int(workspaceQuery))
        lwork = Int32(workspaceQuery)
            
        /* Calculate the size of the workspace */
            
        dgeev_(UnsafeMutablePointer(mutating: ("N" as NSString).utf8String), UnsafeMutablePointer(mutating: ("V" as NSString).utf8String), &N, &flatArray, &N2, &wr, &wi, &vl, &N3, &vr, &N4, &workspace, &lwork, &error)
            
            
        if (error == 0) {
            for index in 0..<wi.count {     /* transform the returned matrices to eigenvalues and eigenvectors */
                if (wi[index]>=0.0) {
                    returnString += "Eigenvalue\n\(wr[index]) + \(wi[index])i\n\n"
                }
                else {
                    returnString += "Eigenvalue\n\(wr[index]) - \(fabs(wi[index]))i\n\n"
                }
                calculatedValidEnergies.append(wr[index])
                            
                returnString += "Eigenvector\n"
                returnString += "["
                            
                            
                /* To Save Memory dgeev returns a packed array if complex */
                /* Must Unpack Properly to Get Correct Result
                             
                    VR is DOUBLE PRECISION array, dimension (LDVR,N)
                    If JOBVR = 'V', the right eigenvectors v(j) are stored one
                    after another in the columns of VR, in the same order
                    as their eigenvalues.
                    If JOBVR = 'N', VR is not referenced.
                    If the j-th eigenvalue is real, then v(j) = VR(:,j),
                    the j-th column of VR.
                    If the j-th and (j+1)-st eigenvalues form a complex
                    conjugate pair, then v(j) = VR(:,j) + i*VR(:,j+1) and
                    v(j+1) = VR(:,j) - i*VR(:,j+1). */
                
                var newEigenvector: [Double] = []
                for j in 0..<N { // Array over each eigenvector component
                    let newEigenvectorComponent = (vr[Int(index)*(Int(N))+Int(j)])
                    newEigenvector.append(newEigenvectorComponent)
                    if(wi[index]==0)
                    {
                        returnString += "\(vr[Int(index)*(Int(N))+Int(j)]) + 0.0i, \n" /* print x */
                    }
                    else if(wi[index]>0)
                    {
                        if(vr[Int(index)*(Int(N))+Int(j)+Int(N)]>=0)
                        {
                            returnString += "\(vr[Int(index)*(Int(N))+Int(j)]) + \(vr[Int(index)*(Int(N))+Int(j)+Int(N)])i, \n"
                        }
                        else
                        {
                            returnString += "\(vr[Int(index)*(Int(N))+Int(j)]) - \(fabs(vr[Int(index)*(Int(N))+Int(j)+Int(N)]))i, \n"
                        }
                    }
                    else
                    {
                        if(vr[Int(index)*(Int(N))+Int(j)]>0)
                        {
                            returnString += "\(vr[Int(index)*(Int(N))+Int(j)-Int(N)]) - \(vr[Int(index)*(Int(N))+Int(j)])i, \n"
                            
                        }
                        else
                        {
                            returnString += "\(vr[Int(index)*(Int(N))+Int(j)-Int(N)]) + \(fabs(vr[Int(index)*(Int(N))+Int(j)]))i, \n"
                            
                        }
                    }
                }
                eigenvectors.append(newEigenvector)
                
                /* Remove the last , in the returned Eigenvector */
                returnString.remove(at: returnString.index(before: returnString.endIndex))
                returnString.remove(at: returnString.index(before: returnString.endIndex))
                returnString.remove(at: returnString.index(before: returnString.endIndex))
                returnString += "]\n\n"
            }
        }
        else {print("An error occurred\n")}
        
        return (returnString)
    }
    
    /// updatePsiArrays
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter psiArray: contains the array of wavefunction values
    @MainActor func updatePsiArrays(psiArray: [[Double]]) async {
        self.validPsiArrays = psiArray
    }
    
    /// updateValidEnergies
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter validEnergyArray: contains the array of energy eigenvalues
    @MainActor func updateValidEnergies(energyArray: [Double]) async {
        self.validEnergyArray = energyArray
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
        
        let xMin = xArray[0]
        let xMax = xArray[xArray.count - 1]
        
        // Set x-axis limits
        await plotDataModel!.changingPlotParameters.xMax = xMax + 0.5
        await plotDataModel!.changingPlotParameters.xMin = xMin - 0.5
        // Set y-axis limits
        await plotDataModel!.changingPlotParameters.yMax = 1.1
        await plotDataModel!.changingPlotParameters.yMin = -1.1
            
        // Set title and other attributes
        await plotDataModel!.changingPlotParameters.title = "Wavefunction Solution"
        await plotDataModel!.changingPlotParameters.xLabel = "Position"
        await plotDataModel!.changingPlotParameters.yLabel = "Psi"
        await plotDataModel!.changingPlotParameters.lineColor = .red()
            
        // Plot the data
        await plotDataModel!.appendData(dataPoint: dataPoints)
    }
    
    /// getPlotDataFromPsiArray
    /// Plots the data of the array at the passed index in allValidPsiPlotData. This data is the solution of psi at the energy eigenvalue
    /// associated with the index. Checks if there is no data and defaults to index 0
    /// - Parameters:
    ///   - index: the array index for the data that will be plotted
    func getPlotDataFromPsiArray(index: Int) async {
        if (index > -1 && index < allValidPsiPlotData.count) { // This is a valid index
            // Plot the data at the given index
            await updateDataPoints(dataPoints: allValidPsiPlotData[index])
            await getPlotData()
        }
        else if !(allValidPsiPlotData.isEmpty) { // The index isn't valid but the data array isn't empty
            // Plot the data at index 0
            await updateDataPoints(dataPoints: allValidPsiPlotData[0])
            await getPlotData()
        }
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
