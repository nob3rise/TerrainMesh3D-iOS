//
//  TerrainMesh.swift
//  TerrainMesh3DiOS
//
//  Created by Nob on 2019/08/03.
//  Copyright © 2019 Nob. All rights reserved.
//

import Foundation
import SceneKit

class TerrainMesh : SCNNode {
    private var meshVertices : [SCNVector3]! = nil
    private var normals : [SCNVector3]! = nil
    private var triangleIndices : [Int32]! = nil
    private var textureCoordinates : [Float]! = nil
    private var deformHistory : [(CGPoint, Float, Float)] = []
    
    private var vertexHeightComputationBlock : ((Int, Int) -> Float)?
    private let verticesPerSide : Int
    var width : Float
    var height : Float
    
    init(verticesPerside : Int, width : Float, height : Float, vertexHeight : ((Int, Int) -> Float)?) {
        //        guard verticesPerside >= 2 else { return nil }
        
        self.verticesPerSide = verticesPerside
        self.width = width
        self.height = height
        self.vertexHeightComputationBlock = vertexHeight
        
        super.init()
        
        self.allocateDataBuffers()
        self.populateDataBuffersWithStartingValues()
        self.configureGeometry()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func allocateDataBuffers() {
        let totalVertices = verticesPerSide * verticesPerSide
        let squaresPerside = verticesPerSide - 1
        let totalSquares = squaresPerside * squaresPerside
        let totalTriangles = totalSquares * 2
        
        self.meshVertices = Array<SCNVector3>(repeating: SCNVector3(x: 0, y: 0, z: 0), count: totalVertices)
        self.normals = Array<SCNVector3>(repeating: SCNVector3(x: 0, y: 0, z: 0), count: totalVertices)
        self.triangleIndices = Array<Int32>(repeating: 0, count: totalTriangles * 3)
        self.textureCoordinates = Array<Float>(repeating: 0, count: totalVertices * 2)
    }
    
    private func populateDataBuffersWithStartingValues() {
        let totalVertices = verticesPerSide * verticesPerSide
        let squaresPerside = verticesPerSide - 1
        let totalSquares = squaresPerside * squaresPerside
        let totalTriangles = totalSquares * 2
        
        for i in 0 ..< totalVertices
        {
            let ix = i % verticesPerSide
            let iy = i / verticesPerSide
            
            let ixf = Float(ix) / Float(verticesPerSide - 1)
            let iyf = Float(iy) / Float(verticesPerSide - 1)
            let x = ixf * Float(width);
            let y = iyf * Float(height);
            
            /*  Create vertices */
            
            var vertexZDepth : Float = 0.0
            
            if let vartexHeghtComputation = vertexHeightComputationBlock {
                vertexZDepth = vartexHeghtComputation(ix, iy)
            }
            
            self.meshVertices[i] = SCNVector3Make(Float(x), Float(y), Float(vertexZDepth));
            
            /*  Create normals for each vertex */
            self.normals[i] = SCNVector3Make(0, 0, 1)
            
            /*  Create texture coords (an X,Y pair for each vertex) */
            let ti = i * 2
            self.textureCoordinates[ti] = Float(ixf)
            self.textureCoordinates[ti+1] = 1.0 - Float(iyf)
        }
        
        for i in stride(from: 0, to: totalTriangles, by: 2) {
            /*  Define the triangles that make up the terrain mesh */
            let squareIndex = (i / 2)
            let squareX = squareIndex % squaresPerside
            let squareY = squareIndex / squaresPerside
            
            let vPerSide = verticesPerSide
            let toprightIndex = ((squareY + 1) * vPerSide) + squareX + 1
            let topleftIndex = toprightIndex - 1
            let bottomleftIndex = toprightIndex - vPerSide - 1
            let bottomrightIndex = toprightIndex - vPerSide
            
            let i1 = i * 3
            
            self.triangleIndices[i1] = Int32(toprightIndex)
            self.triangleIndices[i1+1] = Int32(topleftIndex)
            self.triangleIndices[i1+2] = Int32(bottomleftIndex)
            
            self.triangleIndices[i1+3] = Int32(toprightIndex)
            self.triangleIndices[i1+4] = Int32(bottomleftIndex)
            self.triangleIndices[i1+5] = Int32(bottomrightIndex)
            
        }
    }
    
    func configureGeometry() {
        let originalMaterials = self.geometry?.materials
        
        let totalVertices = verticesPerSide * verticesPerSide
        let squaresPerSide = (verticesPerSide - 1)
        let totalSquares = squaresPerSide * squaresPerSide
        let totalTriangles = totalSquares * 2
        
        
        let textureData = NSData(bytes: UnsafeRawPointer(textureCoordinates), length: totalVertices * MemoryLayout<float2>.size)
        
        let textureSource = SCNGeometrySource(data: textureData as Data,
                                              semantic: .texcoord,
                                              vectorCount: totalVertices,
                                              usesFloatComponents: true,
                                              componentsPerVector: 2,
                                              bytesPerComponent: MemoryLayout<Float>.size,
                                              dataOffset: 0,
                                              dataStride: MemoryLayout<float2>.size)
        
        
        let vertexSource = SCNGeometrySource(vertices: meshVertices)
        
        let normalSource = SCNGeometrySource(normals: normals)
        
        let indexData = NSData(bytes: UnsafeRawPointer(triangleIndices), length: MemoryLayout<Int32>.size * totalTriangles * 3)
        
        
        let element = SCNGeometryElement(data: indexData as Data, primitiveType: .triangles, primitiveCount: totalTriangles, bytesPerIndex: MemoryLayout<Int32>.size)
        
        let geometry = SCNGeometry(sources: [vertexSource, normalSource, textureSource], elements: [element])
        
        if let materials = originalMaterials {
            geometry.materials = materials
        }
        
        
        self.geometry = geometry
    }
    
    func updateGeometry(vertexComputationBlock: ((Int, Int) -> Float)?) {
        if let computationBlock = vertexComputationBlock {
            self.vertexHeightComputationBlock = computationBlock
            self.populateDataBuffersWithStartingValues()
            self.configureGeometry()
        }
    }
    
    func deformTerrainAt(point: CGPoint, brushRadius: Float, intensity: Float) {
        deformTerrainAtWithoutHistory(point: point, brushRadius: brushRadius, intensity: intensity)
        deformHistory.append((point, brushRadius, intensity))
    }
    
    private func deformTerrainAtWithoutHistory(point: CGPoint, brushRadius: Float, intensity: Float) {
        let radiusInIndices = brushRadius * Float(verticesPerSide)
        let vx = Float(CGFloat(verticesPerSide) * point.x)
        let vy = Float(CGFloat(verticesPerSide) * point.y)
        
        for y in 0 ..< verticesPerSide {
            
            for x in 0 ..< verticesPerSide {
                let xDelta = vx - Float(x)
                let yDelta = vy - Float(y)
                let dist = sqrt((xDelta * xDelta) + (yDelta * yDelta))
                
                if( dist < radiusInIndices) {
                    let index = Int(y * verticesPerSide) + x
                    
                    var relativeIntensity = (1.0 - (dist / radiusInIndices))
                    
                    relativeIntensity = sin(relativeIntensity * .pi / 2)
                    relativeIntensity *= intensity
                    
                    meshVertices[index].z += Float(relativeIntensity)
                }
            }
        }
        self.configureGeometry()
    }
}
