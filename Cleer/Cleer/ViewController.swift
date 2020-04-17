//
//  ViewController.swift
//  Ar_attempt
//
//  Created by Enquirer on 4/13/20.
//  Copyright © 2020 Enquirer. All rights reserved.
//

import UIKit
//import SceneKit
import ARKit
import Combine
import RealityKit

//class ARBodyTrackingConfiguration : ARConfiguration{}

class ViewController: UIViewController,  ARSessionDelegate {
    
   // @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var arView: ARView!
    
    //var teststst = 1
    
    var character: BodyTrackedEntity?
    var initialPosition = AnchorEntity()
    let characterOffset: SIMD3<Float> = [0, 0, 0]
    var characterAnchor = AnchorEntity()
    var anotherAnchor = AnchorEntity()
    var bodyPosition: SIMD3<Float> = [0, 0, 0]
    var frameCount = 0
    
//    func session(_ session: ARSession, didAdd anchors: [ARAnchor]){
//        print("Skeleton recieved")
//    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Set the view's delegate
        arView.session.delegate/*?*/ = self

          guard ARBodyTrackingConfiguration.isSupported else {
              fatalError("This feature is only supported on devices with an A12 chip")
          }

          // Run a body tracking configration.
          let configuration = ARBodyTrackingConfiguration()
          arView.session.run(configuration)
          
          arView.scene.addAnchor(characterAnchor)
          arView.scene.addAnchor(anotherAnchor)
          arView.scene.addAnchor(initialPosition)
        
          
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
    
    func session(_ session: ARSession,/* */ didUpdate anchors: [ARAnchor]/* didUpdate frame: ARFrame*/) {
        print(":P")
        for anchor in anchors {
            print("EEEEEEeeeEEEEEEEeeEEEEEe")
            guard let bodyAnchor = anchor as? ARBodyAnchor else { continue }
            
            // Update the position of the character anchor's position.
            self.bodyPosition = simd_make_float3(bodyAnchor.transform.columns.3)
            characterAnchor.position = bodyPosition + characterOffset
            /*
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
//            anotherAnchor.addChild(entity2) */
            
//            anotherAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
//            anotherAnchor.position = Transform(matrix: <#T##float4x4#>)
            characterAnchor.orientation = Transform(matrix: bodyAnchor.transform).rotation
            
            if let character = character, character.parent == nil {
                characterAnchor.addChild(character)
            }
//            print(characterAnchor.position)
            print(characterAnchor.position.z)
            if abs(characterAnchor.position.z) <= 3 {
                violation()
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame){
        if (frameCount % 5 == 0){
            let transform = frame.camera.transform
            var Distance: Float = 0
            var deltaDistanceArray = [Float]()
            var halfwayPointArray = [Float]()
            for i in (0..<3) {
                Distance += Float((pow(Double((Double(bodyPosition[i])-Double(transform[3][i]))), Double(2))))
                halfwayPointArray.append((transform[3][i]+bodyPosition[i])/2)
                deltaDistanceArray.append(bodyPosition[i]-transform[3][i])
            }
            let halfwayPoint: SIMD3<Float> = [(halfwayPointArray[0]), (halfwayPointArray[1]), halfwayPointArray[2]] // TODO: Fix bad math w/ atan and crap
            Distance = Float(sqrt(Distance))
//            print(Distance)
//            print(halfwayPoint)
            let box = MeshResource.generateBox(width: 0.03, height: 0.01, depth: Distance) // size in metres

            //let plane = MeshResource.generatePlane(width: 0.03, depth: characterAnchor.position.z )
            let material = SimpleMaterial(color: .green, isMetallic: false)
            let entity = ModelEntity(mesh: box, materials: [material])
            //let entity2 = ModelEntity(mesh: plane, materials: [material])
            for child in anotherAnchor.children {
                anotherAnchor.removeChild(child)
            }

            let thetaY = atan(deltaDistanceArray[2]/deltaDistanceArray[1])
            let thetaX = atan(deltaDistanceArray[1]/deltaDistanceArray[0])
            
            let rotateX = simd_float4x4.init(
                SIMD4<Float>.init(1, 0, 0, 0),
                SIMD4<Float>.init(0, cos(thetaX), -sin(thetaX), 0),
                SIMD4<Float>.init(0, sin(thetaX), cos(thetaX), 0),
                SIMD4<Float>.init(0, 0, 0, 1))
            
            let rotateY = simd_float4x4.init(
                SIMD4<Float>.init(cos(thetaY), 0, sin(thetaY), 0),
                SIMD4<Float>.init(0, 1, 0, 0),
                SIMD4<Float>.init(-sin(thetaY), 0, cos(thetaY), 0),
                SIMD4<Float>.init(0, 0, 0, 1))
            
            print(thetaX, thetaY)
            //print(thetaY)
            anotherAnchor.addChild(entity)
            anotherAnchor.setPosition(halfwayPoint, relativeTo: initialPosition)
            anotherAnchor.setTransformMatrix(rotateX, relativeTo: initialPosition)
            anotherAnchor.setTransformMatrix(rotateY, relativeTo: initialPosition)
        }
        //            anotherAnchor.addChild(entity2)
        frameCount += 1
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
        //sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //print(teststst)
        // Pause the view's session
        //sceneView.session.pause()
    }


}
