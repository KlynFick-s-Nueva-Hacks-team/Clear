//
//  ViewController.swift
//  Ar_attempt
//
//  Created by Enquirer on 4/13/20.
//  Copyright © 2020 Enquirer. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
   
    
    
    
    

    @IBOutlet var sceneView: ARSCNView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        
        let sphere = SCNSphere(radius: 0.1)
        let torus = SCNTorus(ringRadius: 1.0, pipeRadius: 0.05)
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
    
        
        
//        let opacity: CGFloat = 0.7
        
        let material = SCNMaterial()
        

        
//        material.diffuse.contents = UIImage(named: "grimyMetal.png")
        material.diffuse.contents = UIImage(named: "spruceWood.png")

//        material.diffuse.contents = UIColor.red
        
        torus.materials = [material]
        sphere.materials = [material]
//        box.materials = [material]
        
      
        let torusNode = SCNNode(geometry: torus)
        //let sphereNode = SCNNode(geometry: sphere)
        let boxNode = SCNNode(geometry: box)
       
      
        
        torusNode.position = SCNVector3(0, 0, 0)
        //sphereNode.position = SCNVector3(0, 0, -0.5)
        boxNode.position = SCNVector3(0,0,-0.5)
        
//        sphereNode.opacity = opacity
//        torusNode.opacity = opacity
        
        
        //scene.rootNode.addChildNode(sphereNode)
        scene.rootNode.addChildNode(torusNode)
//        scene.rootNode.addChildNode(boxNode)
        
        
       
        
        
        
        
        
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.frameSemantics.insert(.personSegmentationWithDepth)
        sceneView.session.run(configuration)

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }


}
