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

class GameViewController: UIViewController {

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
        let sideLength : Double = 10
        let mesh = TerrainMesh(verticesPerside: kMeshResolution, sideLength: sideLength, vertexHeight: nil)
        
        
        let mat = SCNMaterial()
        mat.diffuse.contents = UIImage(named: "grass1.jpg")
        mat.isDoubleSided = true
        mesh.geometry?.materials = [mat]
        mesh.pivot = SCNMatrix4MakeTranslation(Float(sideLength) / 2, Float(sideLength) / 2, 0)
        
        scene.rootNode.addChildNode(mesh)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.2
        mesh.rotation = SCNVector4Make(1.0, 0, 0, -.pi/4)
        mesh.position = SCNVector3Make(0.0, 2.0, 0.0)
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
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
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
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

}
