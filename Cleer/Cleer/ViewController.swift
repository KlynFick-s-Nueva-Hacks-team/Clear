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
import Combine
import RealityKit

//class ARBodyTrackingConfiguration : ARConfiguration{}

class ViewController: UIViewController, ARSCNViewDelegate,  ARSessionDelegate{
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var arView: ARView!
    
    var teststst = 1
    
    var character: BodyTrackedEntity?
    var initialPosition = AnchorEntity()
    let characterOffset: SIMD3<Float> = [0, 0, 0] // Offset the character by one meter to the left
    let characterAnchor = AnchorEntity()
    let anotherAnchor = AnchorEntity()
    
//    func session(_ session: ARSession, didAdd anchors: [ARAnchor]){
//        print("Skeleton recieved")
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set the view's delegate
        arView.session.delegate? = self

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
          guard ARBodyTrackingConfiguration.isSupported else {
              fatalError("This feature is only supported on devices with an A12 chip")
          }

          // Run a body tracking configration.
          let configuration = ARBodyTrackingConfiguration()
          arView.session.run(configuration)
          
          arView.scene.addAnchor(characterAnchor)
          arView.scene.addAnchor(anotherAnchor)
        
          
          // Asynchronously load the 3D character.
          var cancellable: AnyCancellable? = nil
          cancellable = Entity.loadBodyTrackedAsync(named: "character/robot").sink(
              receiveCompletion: { completion in
                  if case let .failure(error) = completion {
                      print("Error: Unable to load model: \(error.localizedDescription)")
                  }
                  cancellable?.cancel()
          }, receiveValue: { (character: Entity) in
              if let character = character as? BodyTrackedEntity {
                  // Scale the character to human size
                  character.scale = [1.0, 1.0, 1.0]
                  self.character = character
                  cancellable?.cancel()
              } else {
                  print("Error: Unable to load model as BodyTrackedEntity")
              }
          })
    }
    
    func violation() {
        print("stapit")
        AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
        
    }
    
        func session(_ session: ARSession, didUpdate frame: ARFrame, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
                
                // Update the position of the character anchor's position.
                let bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
                characterAnchor.position = bodyPosition + characterOffset
                
                let transform = frame.camera.transform
                var Distance: Float = 0
                var halfwayPoint: SIMD3<Float> = [0, 0, 0]
                for i in (0..<3) {
                    Distance += Float((pow(Double((Double(bodyPosition[i])-Double(transform[3][i]))),Double(2))))
                    halfwayPoint[i] = transform[3][i]+(bodyPosition[i]-transform[3][i])
                }
                Distance = Float(sqrt(Distance))
                
                let box = MeshResource.generateBox(width: 0.03, height: 0.03, depth: Distance) // size in metres
                //let plane = MeshResource.generatePlane(width: 0.03, depth: characterAnchor.position.z )
                let material = SimpleMaterial(color: .green, isMetallic: false)
                let entity = ModelEntity(mesh: box, materials: [material])
                //let entity2 = ModelEntity(mesh: plane, materials: [material])
                
                anotherAnchor.addChild(entity)
                anotherAnchor.setPosition(halfwayPoint, relativeTo: initialPosition)
    //            anotherAnchor.addChild(entity2)
                
    //            anotherAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
    //            anotherAnchor.position = Transform(matrix: <#T##float4x4#>)
                
                
    //            print(characterAnchor.position)
                print(characterAnchor.position.z)
                if abs(characterAnchor.position.z) <= 3 {
                    violation()
                }
        }
    }
    /*
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]){
        
    }*/
                
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.frameSemantics.insert(.personSegmentationWithDepth)

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(teststst)
        // Pause the view's session
        sceneView.session.pause()
    }


}
