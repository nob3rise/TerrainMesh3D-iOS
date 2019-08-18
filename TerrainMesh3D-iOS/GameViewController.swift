//
//  GameViewController.swift
//  TerrainMesh3DiOS
//
//  Created by Nob on 2019/08/02.
//  Copyright © 2019 Nob. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, UIGestureRecognizerDelegate {

    var presetPanRecognizer : UIPanGestureRecognizer!
    var presetPinchRecognizer : UIPinchGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        if let image = UIImage(named: "sky2.jpg") {
            scene.background.contents = image
        }
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        configureDefalutLighting()
        
        let kMeshResolution = 40
        let sideLength : Float = 10
        let mesh = TerrainMesh(verticesPerside: kMeshResolution, width: sideLength, height: sideLength, vertexHeight: nil)
        
        
        let mat = SCNMaterial()
        mat.diffuse.contents = UIImage(named: "grass1.jpg")
        mat.isDoubleSided = true
        mesh.geometry?.materials = [mat]
        mesh.pivot = SCNMatrix4MakeTranslation(Float(sideLength) / 2, Float(sideLength) / 2, 0)
        
        scene.rootNode.addChildNode(mesh)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.2
        mesh.rotation = SCNVector4Make(1.0, 0, 0, -.pi/2)
        SCNTransaction.commit()
        
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        
        for recognizer in scnView.gestureRecognizers! {
            if (recognizer.isKind(of: UIPanGestureRecognizer.self)) {
                presetPanRecognizer = recognizer as? UIPanGestureRecognizer
            
            } else if (recognizer.isKind(of: UIPinchGestureRecognizer.self)) {
                presetPinchRecognizer = recognizer as? UIPinchGestureRecognizer
            }
        }
        
        scnView.addGestureRecognizer(panGesture)
    }
    
    func configureDefalutLighting() {
        let scene = SCNScene()
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
    }
    
    @objc
    func handlePan(_ gestureRecognize: UIGestureRecognizer) {
        guard presetPanRecognizer.state != .changed else { return }
        guard presetPinchRecognizer.state != .changed else { return }
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            let node = result.node
            
            if (node.isKind(of: TerrainMesh.self)) {
                let mesh = node as! TerrainMesh
                let meshSize = mesh.width
                
                let relativeLocation = CGPoint(x: CGFloat(result.localCoordinates.x / meshSize), y: CGFloat(result.localCoordinates.y / meshSize))
                
                let deformDirection = (scnView.defaultCameraController.pointOfView?.position.y)! >= Float(0.0) ? 1.0 : -1.0
                
                mesh.deformTerrainAt(point: relativeLocation, brushRadius: 0.25, intensity: Float(0.025 * deformDirection))
                
                if (presetPanRecognizer.state != .changed) {
                    presetPanRecognizer.state = .cancelled
                }
                if (presetPinchRecognizer.state != .changed) {
                    presetPinchRecognizer.state = .cancelled
                }
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    // UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
