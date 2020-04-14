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
        
        let opacity: CGFloat = 0.5
        
        let sphere = SCNSphere(radius: 0.1)
        
        let sphereNode = SCNNode(geometry: sphere)
        
        
        sphereNode.position = SCNVector3(0, 0, -0.5)
        sphereNode.opacity = opacity
        
        scene.rootNode.addChildNode(sphereNode)
        
        
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }


}
