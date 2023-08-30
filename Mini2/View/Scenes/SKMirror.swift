//
//  SKMirrorNode.swift
//  Mini2
//
//  Created by Gustavo Munhoz Correa on 27/08/23.
//

import SpriteKit

class SKMirror: SKSpriteNode {
    weak var delegate: SKMirrorDelegate?
    var touchArea:    SKShapeNode!
    var isReflecting = false
    var lastReflectedBeamID: UUID?
    
    init(position: CGPoint, size: CGSize) {
        super.init(texture: nil, color: .gray, size: size)
        
        self.position = position
        self.name     = "mirror"
        
        addTouchArea()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addTouchArea() {
        let radius = max(self.size.width, self.size.height) / 2 + 30
        
        touchArea = SKShapeNode(circleOfRadius: radius)
        touchArea.strokeColor = .clear
        touchArea.name = "touchArea"
        
        addChild(touchArea)
    }
    
    func getMirrorEndpoints() -> (start: CGPoint, end: CGPoint) {
        // A metade da altura do espelho.
        let halfHeight = self.size.height / 2.0
        
        // Calculando as coordenadas dos pontos inicial e final do espelho, levando em consideração a rotação.
        let dx = halfHeight * sin(self.zRotation)
        let dy = halfHeight * cos(self.zRotation)
        
        // Calculando os pontos de início e fim com base na posição e na rotação do espelho.
        let startPoint = CGPoint(x: self.position.x - dx, y: self.position.y + dy)
        let endPoint   = CGPoint(x: self.position.x + dx, y: self.position.y - dy)
        
        return (start: startPoint, end: endPoint)
    }
    
    func getNormalVectors() -> (CGVector, CGVector) {
        let points = getMirrorEndpoints()
        
        let dx = points.end.x - points.start.x
        let dy = points.end.y - points.start.y
        
        let normal1 = CGVector(dx: dy, dy: -dx)
        let normal2 = CGVector(dx: -dy, dy: dx)
        
        return (normal1, normal2)
    }
    
    private func calculateAngleOfIncidence(_ incidentVector: CGVector, withNormal normalVector: CGVector) -> CGFloat {
        let dotProduct = incidentVector.dx * normalVector.dx + incidentVector.dy * normalVector.dy
        let magnitudes = sqrt(incidentVector.dx * incidentVector.dx + incidentVector.dy * incidentVector.dy)
                            * sqrt(normalVector.dx * normalVector.dx + normalVector.dy * normalVector.dy)
        
        let cosineTheta = dotProduct / magnitudes
        
        // Retornar o ângulo em graus
        return acos(cosineTheta) * 180 / .pi
    }
    
    
    func didDetectLight(incidentPoint: CGPoint, incidentVector: CGVector) {
        var reflectedVector: CGVector?
        
        if isReflecting {
            if let existingBeamID = lastReflectedBeamID,
               let existingBeam = (scene as! LightPuzzleScene).findLightBeam(byID: existingBeamID) {
                existingBeam.updateDirectionAndStartPoint(
                    newStartPoint: incidentPoint,
                    newDirection: reflectedVector ?? CGVector(dx: 0, dy: 0))
            }
        } else {
            let normals = getNormalVectors()
            let anglePair = [(normal: normals.0, angle: calculateAngleOfIncidence(incidentVector, withNormal: normals.0)),
                            (normal: normals.1, angle: calculateAngleOfIncidence(incidentVector, withNormal: normals.1))]
            
            for (normal, angle) in anglePair {
                if angle < 90 {
                    reflectedVector = reflect(incidentVector: incidentVector, normalVector: normal)
                }
            }
            
            let newLightBeam = SKLightBeam(startPoint: incidentPoint, direction: reflectedVector ?? CGVector(dx: 0, dy: 0))
            newLightBeam.strokeColor = .blue
            newLightBeam.lineWidth   = 5
            
            delegate?.didGenerateNewLightBeam(newLightBeam)
            
            lastReflectedBeamID = newLightBeam.id
            (scene as! LightPuzzleScene).addLightBeam(newLightBeam)
            
            isReflecting = true
        }
    }

    
    func reflect(incidentVector: CGVector, normalVector: CGVector) -> CGVector {
        let dotProduct = incidentVector.dx * normalVector.dx + incidentVector.dy * normalVector.dy
        
        let reflectedVector = CGVector(
            dx: incidentVector.dx - 2 * dotProduct * normalVector.dx,
            dy: incidentVector.dy - 2 * dotProduct * normalVector.dy
        )
        
        return reflectedVector
    }

}
