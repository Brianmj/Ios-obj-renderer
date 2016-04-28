//
//  obj_source.swift
//  ios_cube_loader
//
//  Created by Brian Jones on 2/27/16.
//  Copyright © 2016 Brian Jones. All rights reserved.
//

import Foundation
import Metal

struct PointXYZ {
    var x: Float
    var y: Float
    var z: Float
    
    init() {
        x = 0.0
        y = 0.0
        z = 0.0
    }
    
    init(x: Float, y: Float, z:Float){
        self.x = x
        self.y = y
        self.z = z
    }
}

struct PointXYZW {
    var x: Float
    var y: Float
    var z: Float
    var w: Float
    
    init() {
        x = 0.0
        y = 0.0
        z = 0.0
        w = 1.0
    }
    
    init(x: Float, y: Float, z:Float, w: Float){
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
}
enum ObjFormat {
    case VERTEX
    case VERTEX_TEXTURE
    case VERTEX_TEXTURE_NORMAL
    case VERTEX_NORMAL
}

struct ObjMesh {
    
    var materialToUse = ""
    var indicesCount: Int = 0
    var vertexIndices = Array<Int>()
    var texCoordIndices = Array<Int>()
    var normalIndices = Array<Int>()
    
    var hasTexCoords: Bool {
        get { return !texCoordIndices.isEmpty }
    }
    
    var hasNormals: Bool {
        get { return !normalIndices.isEmpty }
    }
}

class ObjReader {
    
    private static let VERTEX_HEADER = "v "
    private static let NORMAL_HEADER = "vn"
    private static let FACE_HEADER = "f "
    private static let NEW_MATERIAL_HEADER = "usemtl"
    
    private static let NEW_MESH_REGEX_PATTERN = "usemtl (\\w+)"
    private static let VERTEX_NORMAL_REGEX_PATTERN = "(\\d+)//(\\d+)"
    
    var vertices: [PointXYZW]
    var normals: [PointXYZW]
    
    var mesh: [ObjMesh]
    
    var objFormat: ObjFormat!
    
    init (objFileName: String) {
        
        vertices = [PointXYZW]()
        normals = [PointXYZW]()
        
        mesh = [ObjMesh]()
        
        var objStr = String()
        do{
            let objUrl = NSBundle.mainBundle().URLForResource(objFileName, withExtension: "obj")
            
                objStr = try String(contentsOfURL: objUrl!)
        }catch let error as NSError {
            fatalError(error.debugDescription)
        }
        
        print(objStr)
        
        parseObjFile(objStr)
    }
    
    func arrayData() -> [PointXYZW] {
        
        var data:[PointXYZW] = [PointXYZW]()
        
        switch objFormat! {
        case .VERTEX:
            for i in 0.stride(to: (mesh.first?.indicesCount)!, by: 1) {
                let vIndex = mesh.first?.vertexIndices[i]
                
                let vertex = vertices[vIndex!]
                
                data.append(vertex)
            }
            
        case.VERTEX_NORMAL:
            
            for i in 0.stride(to: (mesh.first?.indicesCount)!, by: 1) {
                let vIndex = mesh.first?.vertexIndices[i]
                let nIndex = mesh.first?.normalIndices[i]
                
                let vertex = vertices[vIndex!]
                let normal = normals[nIndex!]
                
                data.append(vertex)
                data.append(normal)
            }
            
        case .VERTEX_TEXTURE:
            fatalError("Vertex texture array construction not implemented yet")
            
        case .VERTEX_TEXTURE_NORMAL:
            fatalError("Vertex texture normal array construction not implemented yet")

        }
        
        return data
    }
    
    private func parseObjFile(objStr: String) {
        let lines = objStr.componentsSeparatedByString("\n")
        for line in lines {
            
            if line.hasPrefix(ObjReader.NORMAL_HEADER) {
                print("normal")
                readNormal(line)
                
            }
            
            if line.hasPrefix(ObjReader.VERTEX_HEADER) {
                print("vertex")
                readVertex(line)
            }
            
            if line.hasPrefix(ObjReader.FACE_HEADER) {
                print("face")
                readFace(line)
                
            }
            
            if line.hasPrefix(ObjReader.NEW_MATERIAL_HEADER) {
                print("New material")
                
                // ====== Create the new mesh
                mesh.append(ObjMesh())

                readNewMesh(line)
            }
        }
        
        guard mesh.isEmpty != true else {
            fatalError("How does this obj not have any faces?")
        }
        
        setModelFormat()
        setMeshIndexCount()
    }
    
    private func readVertex(line: String) {
        let scanner: NSScanner = NSScanner(string: line)
        let skipSet = NSCharacterSet(charactersInString: "-123456789.")
        
        scanner.charactersToBeSkipped = skipSet.invertedSet
        
        var floatVal1: Float = 0.0
        var floatVal2: Float = 0.0
        var floatVal3: Float = 0.0
        scanner.scanFloat(&floatVal1)
        scanner.scanFloat(&floatVal2)
        scanner.scanFloat(&floatVal3)
        
        let v = PointXYZW(x: floatVal1, y: floatVal2, z: floatVal3, w: 1.0)
        vertices.append(v)
        
    }
    
    private func readNormal(line: String) {
        let scanner: NSScanner = NSScanner(string: line)
        let skipSet = NSCharacterSet(charactersInString: "-123456789.")
        
        scanner.charactersToBeSkipped = skipSet.invertedSet
        
        var floatVal1: Float = 0.0
        var floatVal2: Float = 0.0
        var floatVal3: Float = 0.0
        scanner.scanFloat(&floatVal1)
        scanner.scanFloat(&floatVal2)
        scanner.scanFloat(&floatVal3)
        
        let n = PointXYZW(x: floatVal1, y: floatVal2, z: floatVal3, w: 0.0)
        normals.append(n)
    }
    
    private func readNewMesh(line: String) {
        do {
            struct StaticRegex {
                
                static let regex = try! NSRegularExpression(pattern: ObjReader.NEW_MESH_REGEX_PATTERN, options: .CaseInsensitive)
      
            }
            
            let numberOfMatches = StaticRegex.regex.numberOfMatchesInString(line, options: [], range: NSMakeRange(0, line.characters.count))
            
            // should be 1 for usemtl
            if numberOfMatches == 1 {
                let match = StaticRegex.regex.matchesInString(line, options: [], range: NSMakeRange(0, line.characters.count))
                
                let numberOfRanges = match[0].numberOfRanges
                
                if numberOfRanges != 0 {
                    let range1 = match[0].rangeAtIndex(1)
                    let subStringContainingNewMaterial = (line as NSString).substringWithRange(range1)
                    print(subStringContainingNewMaterial)
                    
                    // set material for last mesh
                    mesh[mesh.count - 1].materialToUse = subStringContainingNewMaterial
                }
                
                
            }
        }catch let error as NSError {
            fatalError(error.localizedDescription)
        }
    }
    
    private func readFace(line: String) {
        do{
        struct StaticRegex {
            static let regex = try! NSRegularExpression(pattern: ObjReader.VERTEX_NORMAL_REGEX_PATTERN, options: .CaseInsensitive)
            }
            
            let vertexNormalMatchCount = StaticRegex.regex.numberOfMatchesInString(line, options: [], range: NSMakeRange(0, line.characters.count))
            let matches = StaticRegex.regex.matchesInString(line, options: [], range: NSMakeRange(0, line.characters.count))
            // for now, only capturing faces with vertex and normal components
            if vertexNormalMatchCount != 0 {
                for i in 0..<vertexNormalMatchCount {
                    let match = matches[i]
                    
                    // should be 3 ranges for vertex/normal, the first being the whole line, the second being the vertex and the third being the normal
                    let numberOfRanges = match.numberOfRanges
                    if numberOfRanges == 3 {
                        let range1 = match.rangeAtIndex(1)
                        let range2 = match.rangeAtIndex(2)
                        let subStringContainingVertexIndex = (line as NSString).substringWithRange(range1)
                        let subStringContainingNormalIndex = (line as NSString).substringWithRange(range2)
                        
                        let vertexIndex = Int(subStringContainingVertexIndex)
                        
                        let normalIndex = Int(subStringContainingNormalIndex)
                        
                        guard let vertexIdx = vertexIndex else {
                            fatalError("Could not extract vertex index from string: \(subStringContainingVertexIndex)")
                        }
                        
                        // don't forget to subtract 1 from the index
                        mesh[mesh.count - 1].vertexIndices.append(vertexIdx - 1)
                        
                        guard let normalIdx = normalIndex else {
                            fatalError("Could not extract normal index from string: \(subStringContainingNormalIndex)")
                        }
                        
                        // don't forget to subtract 1 from the index because .obj indices start at 1, not 0
                        mesh[mesh.count - 1].normalIndices.append(normalIdx - 1)
                        
                    
                    }
                }
            }
            
        } catch let error as NSError {
                fatalError(error.localizedDescription)
        }
    }

    private func setModelFormat() {
        let m = mesh.first!
        
        if m.hasNormals && m.hasTexCoords {
            objFormat = ObjFormat.VERTEX_TEXTURE_NORMAL
        }else if m.hasNormals && !m.hasTexCoords {
            objFormat = ObjFormat.VERTEX_NORMAL
        }else if !m.hasNormals && m.hasTexCoords {
            objFormat = ObjFormat.VERTEX_TEXTURE
        }else if !m.hasNormals && !m.hasTexCoords {
            objFormat = ObjFormat.VERTEX
        }else {
            fatalError("How did we get to this point")
        }
    }
    
    private func setMeshIndexCount() {
        for index in 0..<mesh.count {
            mesh[index].indicesCount = mesh[index].vertexIndices.count
        }
    }
}

class MaterialReader {
    
}

class Obj {
    let buffer: MTLBuffer! = nil
    
    init(objFileName: String, device: MTLDevice) {
        
    }
    
    func prepareModel(objFileName: String) {
        
    }
}