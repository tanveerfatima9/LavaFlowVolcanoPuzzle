import SpriteKit

protocol LavaGameSceneDelegate: AnyObject {
    func gameScene(_ scene: LavaGameScene, didComplete targetsReached: Int, totalTargets: Int, elementsUsed: Int)
}

final class LavaGameScene: SKScene {
    
    weak var gameDelegate: LavaGameSceneDelegate?
    
    private let level: Level
    private var gridCells: [[SKSpriteNode]] = []
    private var placedElements: [GameElement] = []
    private var availableElements: [GameElement] = []
    private var elementNodes: [SKSpriteNode] = []
    private var volcanoNode: SKSpriteNode!
    private var targetNodes: [SKSpriteNode] = []
    private var lavaNodes: [SKNode] = []
    private var draggedNode: SKSpriteNode?
    private var draggedElement: GameElement?
    private var originalPosition: CGPoint = .zero
    private var elementsPanel: SKSpriteNode!
    private var gridStartY: CGFloat = 0
    private var cellSize: CGFloat = 0
    private var isLavaFlowing = false
    private var reachedTargets: Set<Int> = []
    private var activeLavaFlows = 0
    private var elementsContainer: SKNode!
    private var elementsPanelScrollOffset: CGFloat = 0
    private var maxScrollOffset: CGFloat = 0
    
    private let darkBlue1 = UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1.0)
    private let darkBlue2 = UIColor(red: 0.08, green: 0.12, blue: 0.25, alpha: 1.0)
    private let darkBlue3 = UIColor(red: 0.12, green: 0.18, blue: 0.32, alpha: 1.0)
    private let lavaColor = UIColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 1.0)
    private let lavaGlow = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 0.6)
    
    init(size: CGSize, level: Level) {
        self.level = level
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        setupBackground()
        setupGrid()
        setupVolcano()
        setupTargets()
        setupElementsPanel()
        setupAvailableElements()
        setupTutorialHint()
    }
    
    private func setupBackground() {
        let background = SKSpriteNode(color: darkBlue1, size: size)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -10
        addChild(background)
        
        for i in 0..<5 {
            let gradientNode = SKSpriteNode(color: darkBlue2.withAlphaComponent(0.3), size: CGSize(width: size.width, height: size.height / 5))
            gradientNode.position = CGPoint(x: size.width / 2, y: CGFloat(i) * size.height / 5 + size.height / 10)
            gradientNode.zPosition = -9
            addChild(gradientNode)
        }
        
        addParticleEffects()
    }
    
    private func addParticleEffects() {
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
            particle.fillColor = UIColor(red: 0.3, green: 0.4, blue: 0.7, alpha: 0.3)
            particle.strokeColor = .clear
            particle.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            particle.zPosition = -8
            addChild(particle)
            
            let moveAction = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -20...20), duration: Double.random(in: 2...4)),
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -20...20), duration: Double.random(in: 2...4))
            ])
            particle.run(SKAction.repeatForever(moveAction))
        }
    }
    
    private func setupGrid() {
        let gridWidth = Int(level.gridSize.width)
        let gridHeight = Int(level.gridSize.height)
        
        let topPadding: CGFloat = 80
        let bottomPadding: CGFloat = 150
        let sidePadding: CGFloat = 20
        
        let availableWidth = max(size.width - sidePadding * 2, 100)
        let availableHeight = max(size.height - topPadding - bottomPadding, 100)
        
        cellSize = max(min(availableWidth / CGFloat(gridWidth), availableHeight / CGFloat(gridHeight)), 20)
        
        let totalGridWidth = cellSize * CGFloat(gridWidth)
        let totalGridHeight = cellSize * CGFloat(gridHeight)
        
        let startX = (size.width - totalGridWidth) / 2 + cellSize / 2
        gridStartY = bottomPadding + (availableHeight - totalGridHeight) / 2 + cellSize / 2
        
        for row in 0..<gridHeight {
            var rowCells: [SKSpriteNode] = []
            for col in 0..<gridWidth {
                let cell = SKSpriteNode(color: darkBlue3, size: CGSize(width: cellSize - 4, height: cellSize - 4))
                cell.position = CGPoint(x: startX + CGFloat(col) * cellSize, y: gridStartY + CGFloat(row) * cellSize)
                cell.zPosition = 0
                cell.name = "cell_\(col)_\(row)"
                
                cell.alpha = 0.6
                
                let border = SKShapeNode(rectOf: CGSize(width: cellSize - 2, height: cellSize - 2), cornerRadius: 4)
                border.strokeColor = UIColor(red: 0.2, green: 0.3, blue: 0.5, alpha: 0.5)
                border.lineWidth = 1
                border.fillColor = .clear
                cell.addChild(border)
                
                addChild(cell)
                rowCells.append(cell)
            }
            gridCells.append(rowCells)
        }
    }
    
    private func setupVolcano() {
        volcanoNode = SKSpriteNode(color: .clear, size: CGSize(width: cellSize * 1.5, height: cellSize * 1.5))
        
        let volcanoShape = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -cellSize * 0.6, y: -cellSize * 0.5))
        path.addLine(to: CGPoint(x: -cellSize * 0.2, y: cellSize * 0.5))
        path.addLine(to: CGPoint(x: cellSize * 0.2, y: cellSize * 0.5))
        path.addLine(to: CGPoint(x: cellSize * 0.6, y: -cellSize * 0.5))
        path.closeSubpath()
        
        volcanoShape.path = path
        volcanoShape.fillColor = UIColor(red: 0.3, green: 0.2, blue: 0.15, alpha: 1.0)
        volcanoShape.strokeColor = UIColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0)
        volcanoShape.lineWidth = 2
        volcanoNode.addChild(volcanoShape)
        
        let lavaTop = SKShapeNode(ellipseOf: CGSize(width: cellSize * 0.5, height: cellSize * 0.3))
        lavaTop.fillColor = lavaColor
        lavaTop.strokeColor = .clear
        lavaTop.position = CGPoint(x: 0, y: cellSize * 0.4)
        lavaTop.zPosition = 1
        volcanoNode.addChild(lavaTop)
        
        let glowAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        lavaTop.run(SKAction.repeatForever(glowAction))
        
        let volcanoGridX = Int(level.volcanoPosition.x * level.gridSize.width)
        let volcanoGridY = Int(level.volcanoPosition.y * level.gridSize.height)
        
        if volcanoGridY < gridCells.count && volcanoGridX < gridCells[0].count {
            volcanoNode.position = gridCells[volcanoGridY][volcanoGridX].position
        } else {
            volcanoNode.position = CGPoint(x: size.width * level.volcanoPosition.x, y: gridStartY + CGFloat(Int(level.gridSize.height) - 1) * cellSize)
        }
        
        volcanoNode.zPosition = 5
        addChild(volcanoNode)
    }
    
    private func setupTargets() {
        for (index, target) in level.targets.enumerated() {
            let targetNode = SKSpriteNode(color: .clear, size: CGSize(width: cellSize, height: cellSize))
            
            let shape: SKShapeNode
            var targetColor: UIColor
            
            switch target.type {
            case .village:
                shape = SKShapeNode(rectOf: CGSize(width: cellSize * 0.6, height: cellSize * 0.5), cornerRadius: 4)
                targetColor = UIColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1.0)
                
                let roof = SKShapeNode()
                let roofPath = CGMutablePath()
                roofPath.move(to: CGPoint(x: -cellSize * 0.35, y: cellSize * 0.15))
                roofPath.addLine(to: CGPoint(x: 0, y: cellSize * 0.4))
                roofPath.addLine(to: CGPoint(x: cellSize * 0.35, y: cellSize * 0.15))
                roofPath.closeSubpath()
                roof.path = roofPath
                roof.fillColor = UIColor(red: 0.6, green: 0.3, blue: 0.2, alpha: 1.0)
                roof.strokeColor = .clear
                targetNode.addChild(roof)
                
            case .altar:
                shape = SKShapeNode(circleOfRadius: cellSize * 0.35)
                targetColor = UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0)
                
                let glow = SKShapeNode(circleOfRadius: cellSize * 0.45)
                glow.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 0.3)
                glow.strokeColor = .clear
                glow.zPosition = -1
                targetNode.addChild(glow)
                
            case .garden:
                shape = SKShapeNode(rectOf: CGSize(width: cellSize * 0.7, height: cellSize * 0.5), cornerRadius: 8)
                targetColor = UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
                
                for i in 0..<3 {
                    let flower = SKShapeNode(circleOfRadius: 4)
                    flower.fillColor = UIColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 1.0)
                    flower.strokeColor = .clear
                    flower.position = CGPoint(x: CGFloat(i - 1) * 12, y: cellSize * 0.15)
                    targetNode.addChild(flower)
                }
            }
            
            shape.fillColor = targetColor
            shape.strokeColor = targetColor.withAlphaComponent(0.8)
            shape.lineWidth = 2
            shape.position = CGPoint(x: 0, y: -cellSize * 0.1)
            shape.name = "mainShape"
            targetNode.addChild(shape)
            
            let targetLabel = SKLabelNode(text: "TARGET")
            targetLabel.fontName = "Helvetica-Bold"
            targetLabel.fontSize = 10
            targetLabel.fontColor = .white
            targetLabel.position = CGPoint(x: 0, y: cellSize * 0.5)
            targetLabel.zPosition = 2
            targetNode.addChild(targetLabel)
            
            let pulseRing = SKShapeNode(circleOfRadius: cellSize * 0.6)
            pulseRing.strokeColor = targetColor
            pulseRing.fillColor = .clear
            pulseRing.lineWidth = 2
            pulseRing.alpha = 0.8
            pulseRing.zPosition = -2
            pulseRing.name = "pulseRing"
            targetNode.addChild(pulseRing)
            
            let pulseAction = SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.5, duration: 1.0),
                    SKAction.fadeAlpha(to: 0, duration: 1.0)
                ]),
                SKAction.group([
                    SKAction.scale(to: 1.0, duration: 0),
                    SKAction.fadeAlpha(to: 0.8, duration: 0)
                ])
            ])
            pulseRing.run(SKAction.repeatForever(pulseAction))
            
            let targetGridX = Int(target.position.x * level.gridSize.width)
            let targetGridY = Int(target.position.y * level.gridSize.height)
            
            if targetGridY < gridCells.count && targetGridX < gridCells[0].count {
                targetNode.position = gridCells[targetGridY][targetGridX].position
            } else {
                targetNode.position = CGPoint(x: size.width * target.position.x, y: gridStartY + CGFloat(targetGridY) * cellSize)
            }
            
            targetNode.zPosition = 3
            targetNode.name = "target_\(index)"
            addChild(targetNode)
            targetNodes.append(targetNode)
        }
    }
    
    private func setupElementsPanel() {
        elementsPanel = SKSpriteNode(color: darkBlue2, size: CGSize(width: size.width, height: 120))
        elementsPanel.position = CGPoint(x: size.width / 2, y: 65)
        elementsPanel.zPosition = 10
        addChild(elementsPanel)
        
        let panelLabel = SKLabelNode(text: "⬅ SWIPE TO SEE MORE • DRAG TO GRID ➡")
        panelLabel.fontName = "Helvetica-Bold"
        panelLabel.fontSize = 10
        panelLabel.fontColor = UIColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0)
        panelLabel.position = CGPoint(x: 0, y: 45)
        elementsPanel.addChild(panelLabel)
        
        elementsContainer = SKNode()
        elementsContainer.position = .zero
        elementsContainer.zPosition = 11
        elementsPanel.addChild(elementsContainer)
    }
    
    private func setupTutorialHint() {
        let hintBg = SKShapeNode(rectOf: CGSize(width: size.width - 30, height: 95), cornerRadius: 12)
        hintBg.fillColor = UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 0.95)
        hintBg.strokeColor = UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 0.8)
        hintBg.lineWidth = 2
        hintBg.position = CGPoint(x: size.width / 2, y: size.height - 95)
        hintBg.zPosition = 20
        hintBg.name = "tutorialHint"
        addChild(hintBg)
        
        let hintText = SKLabelNode(text: "Guide lava from VOLCANO to TARGETS!")
        hintText.fontName = "Helvetica-Bold"
        hintText.fontSize = 13
        hintText.fontColor = .white
        hintText.position = CGPoint(x: 0, y: 28)
        hintBg.addChild(hintText)
        
        let hintText2 = SKLabelNode(text: "Drag elements to grid to direct the flow:")
        hintText2.fontName = "Helvetica"
        hintText2.fontSize = 11
        hintText2.fontColor = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
        hintText2.position = CGPoint(x: 0, y: 10)
        hintBg.addChild(hintText2)
        
        let legendText = SKLabelNode(text: "↕ Straight  ↱ Corner  ⊥ T-Split  ✚ Cross  ⛔ Block")
        legendText.fontName = "Helvetica-Bold"
        legendText.fontSize = 10
        legendText.fontColor = UIColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0)
        legendText.position = CGPoint(x: 0, y: -10)
        hintBg.addChild(legendText)
        
        let tapHint = SKLabelNode(text: "💡 Double-tap placed element to rotate")
        tapHint.fontName = "Helvetica"
        tapHint.fontSize = 10
        tapHint.fontColor = UIColor(red: 0.6, green: 0.8, blue: 0.6, alpha: 1.0)
        tapHint.position = CGPoint(x: 0, y: -28)
        hintBg.addChild(tapHint)
        
        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 6.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ])
        hintBg.run(fadeOut)
        
        let volcanoLabel = SKLabelNode(text: "🌋 VOLCANO")
        volcanoLabel.fontName = "Helvetica-Bold"
        volcanoLabel.fontSize = 11
        volcanoLabel.fontColor = lavaColor
        volcanoLabel.position = CGPoint(x: volcanoNode.position.x, y: volcanoNode.position.y + cellSize * 0.9)
        volcanoLabel.zPosition = 6
        addChild(volcanoLabel)
        
        let arrowDown = SKLabelNode(text: "▼")
        arrowDown.fontName = "Helvetica-Bold"
        arrowDown.fontSize = 20
        arrowDown.fontColor = lavaColor
        arrowDown.position = CGPoint(x: volcanoNode.position.x, y: volcanoNode.position.y - cellSize * 0.8)
        arrowDown.zPosition = 6
        arrowDown.name = "lavaArrow"
        addChild(arrowDown)
        
        let arrowPulse = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -5, duration: 0.3),
            SKAction.moveBy(x: 0, y: 5, duration: 0.3)
        ])
        arrowDown.run(SKAction.repeatForever(arrowPulse))
    }
    
    private func setupAvailableElements() {
        availableElements.removeAll()
        elementNodes.forEach { $0.removeFromParent() }
        elementNodes.removeAll()
        
        elementsContainer.removeAllChildren()
        elementsContainer.position = .zero
        elementsPanelScrollOffset = 0
        
        let elementTypes = GameElementType.allCases
        let count = level.difficulty.availableElements
        
        let elementWidth: CGFloat = 60
        let spacing: CGFloat = 12
        let totalWidth = CGFloat(count) * elementWidth + CGFloat(count - 1) * spacing
        let visibleWidth = size.width - 40
        
        maxScrollOffset = max(0, totalWidth - visibleWidth)
        
        let startX = -totalWidth / 2 + elementWidth / 2
        
        for i in 0..<count {
            let type = elementTypes[i % elementTypes.count]
            let element = GameElement(type: type)
            availableElements.append(element)
            
            let node = createElementNode(for: element)
            let elementPosition = CGPoint(x: startX + CGFloat(i) * (elementWidth + spacing), y: 8)
            node.position = elementPosition
            node.name = "element_\(i)"
            node.zPosition = 11
            elementsContainer.addChild(node)
            elementNodes.append(node)
            element.node = node
            element.panelPosition = elementPosition
            
            let typeLabel = SKLabelNode(text: type.hint)
            typeLabel.fontName = "Helvetica-Bold"
            typeLabel.fontSize = 12
            typeLabel.fontColor = UIColor(red: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
            typeLabel.position = CGPoint(x: startX + CGFloat(i) * (elementWidth + spacing), y: -28)
            typeLabel.name = "label_\(i)"
            typeLabel.zPosition = 11
            elementsContainer.addChild(typeLabel)
        }
        
        setupScrollIndicator()
    }
    
    private func setupScrollIndicator() {
        elementsPanel.childNode(withName: "scrollIndicatorBg")?.removeFromParent()
        elementsPanel.childNode(withName: "scrollIndicator")?.removeFromParent()
        
        guard maxScrollOffset > 0 else { return }
        
        let indicatorWidth: CGFloat = 60
        let indicatorHeight: CGFloat = 4
        
        let bgNode = SKShapeNode(rectOf: CGSize(width: indicatorWidth, height: indicatorHeight), cornerRadius: 2)
        bgNode.fillColor = UIColor(white: 0.3, alpha: 0.5)
        bgNode.strokeColor = .clear
        bgNode.position = CGPoint(x: 0, y: -48)
        bgNode.zPosition = 12
        bgNode.name = "scrollIndicatorBg"
        elementsPanel.addChild(bgNode)
        
        let thumbWidth: CGFloat = 20
        let thumbNode = SKShapeNode(rectOf: CGSize(width: thumbWidth, height: indicatorHeight), cornerRadius: 2)
        thumbNode.fillColor = UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)
        thumbNode.strokeColor = .clear
        thumbNode.position = CGPoint(x: -(indicatorWidth - thumbWidth) / 2, y: -48)
        thumbNode.zPosition = 13
        thumbNode.name = "scrollIndicator"
        elementsPanel.addChild(thumbNode)
    }
    
    private func updateScrollIndicator() {
        guard maxScrollOffset > 0, let thumb = elementsPanel.childNode(withName: "scrollIndicator") else { return }
        
        let indicatorWidth: CGFloat = 60
        let thumbWidth: CGFloat = 20
        let scrollRange = indicatorWidth - thumbWidth
        
        let progress = elementsPanelScrollOffset / maxScrollOffset
        let thumbX = -(scrollRange / 2) + (progress * scrollRange)
        thumb.position.x = thumbX
    }
    
    private func createElementNode(for element: GameElement) -> SKSpriteNode {
        let node = SKSpriteNode(color: .clear, size: CGSize(width: 44, height: 44))
        let pipeColor = UIColor(red: 0.6, green: 0.5, blue: 0.4, alpha: 1.0)
        let pipeWidth: CGFloat = 14
        
        switch element.type {
        case .straight:
            let pipe = SKShapeNode(rectOf: CGSize(width: pipeWidth, height: 40), cornerRadius: 3)
            pipe.fillColor = pipeColor
            pipe.strokeColor = pipeColor.withAlphaComponent(0.6)
            pipe.lineWidth = 2
            node.addChild(pipe)
            
            let hole1 = SKShapeNode(circleOfRadius: 4)
            hole1.fillColor = darkBlue1
            hole1.strokeColor = .clear
            hole1.position = CGPoint(x: 0, y: 16)
            node.addChild(hole1)
            
            let hole2 = SKShapeNode(circleOfRadius: 4)
            hole2.fillColor = darkBlue1
            hole2.strokeColor = .clear
            hole2.position = CGPoint(x: 0, y: -16)
            node.addChild(hole2)
            
        case .corner:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -pipeWidth/2, y: 20))
            path.addLine(to: CGPoint(x: -pipeWidth/2, y: -pipeWidth/2))
            path.addLine(to: CGPoint(x: 20, y: -pipeWidth/2))
            path.addLine(to: CGPoint(x: 20, y: pipeWidth/2))
            path.addLine(to: CGPoint(x: pipeWidth/2, y: pipeWidth/2))
            path.addLine(to: CGPoint(x: pipeWidth/2, y: 20))
            path.closeSubpath()
            let corner = SKShapeNode(path: path)
            corner.fillColor = pipeColor
            corner.strokeColor = pipeColor.withAlphaComponent(0.6)
            corner.lineWidth = 2
            node.addChild(corner)
            
            let hole1 = SKShapeNode(circleOfRadius: 4)
            hole1.fillColor = darkBlue1
            hole1.strokeColor = .clear
            hole1.position = CGPoint(x: 0, y: 16)
            node.addChild(hole1)
            
            let hole2 = SKShapeNode(circleOfRadius: 4)
            hole2.fillColor = darkBlue1
            hole2.strokeColor = .clear
            hole2.position = CGPoint(x: 16, y: 0)
            node.addChild(hole2)
            
        case .tSplit:
            let vertical = SKShapeNode(rectOf: CGSize(width: pipeWidth, height: 24), cornerRadius: 2)
            vertical.fillColor = pipeColor
            vertical.strokeColor = pipeColor.withAlphaComponent(0.6)
            vertical.lineWidth = 2
            vertical.position = CGPoint(x: 0, y: 8)
            node.addChild(vertical)
            
            let horizontal = SKShapeNode(rectOf: CGSize(width: 40, height: pipeWidth), cornerRadius: 2)
            horizontal.fillColor = pipeColor
            horizontal.strokeColor = pipeColor.withAlphaComponent(0.6)
            horizontal.lineWidth = 2
            horizontal.position = CGPoint(x: 0, y: -4)
            node.addChild(horizontal)
            
            let hole1 = SKShapeNode(circleOfRadius: 4)
            hole1.fillColor = darkBlue1
            hole1.strokeColor = .clear
            hole1.position = CGPoint(x: 0, y: 16)
            node.addChild(hole1)
            
            let hole2 = SKShapeNode(circleOfRadius: 4)
            hole2.fillColor = darkBlue1
            hole2.strokeColor = .clear
            hole2.position = CGPoint(x: -16, y: -4)
            node.addChild(hole2)
            
            let hole3 = SKShapeNode(circleOfRadius: 4)
            hole3.fillColor = darkBlue1
            hole3.strokeColor = .clear
            hole3.position = CGPoint(x: 16, y: -4)
            node.addChild(hole3)
            
        case .cross:
            let vertical = SKShapeNode(rectOf: CGSize(width: pipeWidth, height: 40), cornerRadius: 2)
            vertical.fillColor = pipeColor
            vertical.strokeColor = pipeColor.withAlphaComponent(0.6)
            vertical.lineWidth = 2
            node.addChild(vertical)
            
            let horizontal = SKShapeNode(rectOf: CGSize(width: 40, height: pipeWidth), cornerRadius: 2)
            horizontal.fillColor = pipeColor
            horizontal.strokeColor = pipeColor.withAlphaComponent(0.6)
            horizontal.lineWidth = 2
            node.addChild(horizontal)
            
            let center = SKShapeNode(circleOfRadius: 6)
            center.fillColor = UIColor(red: 0.8, green: 0.5, blue: 0.3, alpha: 1.0)
            center.strokeColor = .clear
            node.addChild(center)
            
        case .block:
            let block = SKShapeNode(rectOf: CGSize(width: 36, height: 36), cornerRadius: 4)
            block.fillColor = UIColor(red: 0.5, green: 0.3, blue: 0.3, alpha: 1.0)
            block.strokeColor = UIColor(red: 0.7, green: 0.4, blue: 0.4, alpha: 1.0)
            block.lineWidth = 3
            node.addChild(block)
            
            let x1 = SKShapeNode(rectOf: CGSize(width: 4, height: 30))
            x1.fillColor = UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
            x1.strokeColor = .clear
            x1.zRotation = .pi / 4
            node.addChild(x1)
            
            let x2 = SKShapeNode(rectOf: CGSize(width: 4, height: 30))
            x2.fillColor = UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0)
            x2.strokeColor = .clear
            x2.zRotation = -.pi / 4
            node.addChild(x2)
        }
        
        return node
    }
    
    private var lastPanelTouchX: CGFloat = 0
    private var isPanningPanel = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isLavaFlowing else { return }
        let location = touch.location(in: self)
        let containerLocation = touch.location(in: elementsContainer)
        
        if elementsPanel.contains(convert(location, to: elementsPanel.parent!)) {
            lastPanelTouchX = location.x
            isPanningPanel = true
        }
        
        for (index, node) in elementNodes.enumerated() {
            let nodeFrame = CGRect(
                x: node.position.x - 30,
                y: node.position.y - 30,
                width: 60,
                height: 60
            )
            if nodeFrame.contains(containerLocation) && !availableElements[index].isPlaced {
                isPanningPanel = false
                draggedNode = node
                draggedElement = availableElements[index]
                originalPosition = node.position
                
                node.removeFromParent()
                node.position = location
                node.setScale(1.2)
                node.zPosition = 100
                addChild(node)
                return
            }
        }
        
        let nodesAtPoint = nodes(at: location)
        for node in nodesAtPoint {
            if let element = placedElements.first(where: { $0.node === node }) {
                isPanningPanel = false
                let tapCount = touch.tapCount
                if tapCount == 2 && element.type.canRotate {
                    element.rotate()
                    return
                }
                
                if tapCount == 1 {
                    draggedNode = node as? SKSpriteNode
                    draggedElement = element
                    originalPosition = node.position
                    node.zPosition = 100
                }
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if let node = draggedNode {
            node.position = location
            isPanningPanel = false
        } else if isPanningPanel && maxScrollOffset > 0 {
            let deltaX = location.x - lastPanelTouchX
            lastPanelTouchX = location.x
            
            elementsPanelScrollOffset = max(0, min(maxScrollOffset, elementsPanelScrollOffset - deltaX))
            elementsContainer.position.x = elementsPanelScrollOffset - maxScrollOffset / 2
            updateScrollIndicator()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPanningPanel = false
        
        guard let node = draggedNode, let element = draggedElement else { return }
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        var placed = false
        
        for (rowIndex, row) in gridCells.enumerated() {
            for (colIndex, cell) in row.enumerated() {
                let cellFrame = CGRect(
                    x: cell.position.x - cellSize / 2,
                    y: cell.position.y - cellSize / 2,
                    width: cellSize,
                    height: cellSize
                )
                
                if cellFrame.contains(location) {
                    let isOccupied = placedElements.contains { placedElement in
                        placedElement !== element && placedElement.gridPosition == CGPoint(x: colIndex, y: rowIndex)
                    }
                    
                    let isVolcanoCell = isVolcanoPosition(col: colIndex, row: rowIndex)
                    let isTargetCell = isTargetPosition(col: colIndex, row: rowIndex)
                    
                    if !isOccupied && !isVolcanoCell && !isTargetCell {
                        node.position = cell.position
                        node.setScale(1.0)
                        node.zPosition = 5
                        
                        if !element.isPlaced {
                            element.isPlaced = true
                            placedElements.append(element)
                        }
                        
                        element.gridPosition = CGPoint(x: colIndex, y: rowIndex)
                        placed = true
                        break
                    }
                }
            }
            if placed { break }
        }
        
        if !placed {
            let panelFrame = CGRect(
                x: 0,
                y: 0,
                width: size.width,
                height: 130
            )
            let droppedOnPanel = panelFrame.contains(location)
            
            if droppedOnPanel || !element.isPlaced {
                if element.isPlaced {
                    if let index = placedElements.firstIndex(where: { $0 === element }) {
                        placedElements.remove(at: index)
                    }
                    element.isPlaced = false
                }
                
                node.removeFromParent()
                node.position = element.panelPosition
                node.setScale(1.0)
                node.zPosition = 11
                node.zRotation = 0
                element.rotation = 0
                elementsContainer.addChild(node)
            } else {
                node.position = originalPosition
                node.zPosition = 5
            }
        }
        
        draggedNode = nil
        draggedElement = nil
    }
    
    private func isVolcanoPosition(col: Int, row: Int) -> Bool {
        let volcanoGridX = Int(level.volcanoPosition.x * level.gridSize.width)
        let volcanoGridY = Int(level.volcanoPosition.y * level.gridSize.height)
        return col == volcanoGridX && row == volcanoGridY
    }
    
    private func isTargetPosition(col: Int, row: Int) -> Bool {
        for target in level.targets {
            let targetGridX = Int(target.position.x * level.gridSize.width)
            let targetGridY = Int(target.position.y * level.gridSize.height)
            if col == targetGridX && row == targetGridY {
                return true
            }
        }
        return false
    }
    
    func launchLava() {
        guard !isLavaFlowing else { return }
        isLavaFlowing = true
        reachedTargets.removeAll()
        
        if let hint = childNode(withName: "tutorialHint") {
            hint.removeFromParent()
        }
        if let arrow = childNode(withName: "lavaArrow") {
            arrow.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.3), SKAction.removeFromParent()]))
        }
        
        for targetNode in targetNodes {
            if let ring = targetNode.childNode(withName: "pulseRing") {
                ring.removeAllActions()
            }
        }
        
        let volcanoGridX = Int(level.volcanoPosition.x * level.gridSize.width)
        let volcanoGridY = Int(level.volcanoPosition.y * level.gridSize.height)
        
        activeLavaFlows = 0
        simulateLavaFlow(fromCol: volcanoGridX, fromRow: volcanoGridY, direction: .down, emptyCount: 0)
    }
    
    private let maxEmptyCells = 3
    
    private func simulateLavaFlow(fromCol: Int, fromRow: Int, direction: FlowDirection, emptyCount: Int = 0) {
        activeLavaFlows += 1
        
        let nextCol = fromCol + Int(direction.vector.dx)
        let nextRow = fromRow + Int(direction.vector.dy)
        
        guard nextRow >= 0 && nextRow < gridCells.count &&
              nextCol >= 0 && nextCol < gridCells[0].count else {
            lavaFlowEnded()
            return
        }
        
        for (index, target) in level.targets.enumerated() {
            let targetGridX = Int(target.position.x * level.gridSize.width)
            let targetGridY = Int(target.position.y * level.gridSize.height)
            if nextCol == targetGridX && nextRow == targetGridY {
                reachedTargets.insert(index)
                animateTargetReached(index: index)
                lavaFlowEnded()
                return
            }
        }
        
        let cell = gridCells[nextRow][nextCol]
        
        let lavaNode = SKShapeNode(circleOfRadius: cellSize * 0.3)
        lavaNode.fillColor = lavaColor
        lavaNode.strokeColor = .clear
        lavaNode.position = volcanoNode.position
        lavaNode.zPosition = 4
        addChild(lavaNode)
        lavaNodes.append(lavaNode)
        
        let moveAction = SKAction.move(to: cell.position, duration: 0.3)
        
        lavaNode.run(moveAction) { [weak self] in
            guard let self = self else { return }
            
            if let element = self.placedElements.first(where: {
                Int($0.gridPosition.x) == nextCol && Int($0.gridPosition.y) == nextRow
            }) {
                if element.type == .block {
                    self.lavaFlowEnded()
                    return
                }
                
                let outputDirections = element.getOutputDirections(inputDirection: direction)
                if outputDirections.isEmpty {
                    self.lavaFlowEnded()
                } else {
                    self.activeLavaFlows += outputDirections.count - 1
                    for outputDir in outputDirections {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.continueLavaFlow(fromCol: nextCol, fromRow: nextRow, direction: outputDir, emptyCount: 0)
                        }
                    }
                }
            } else {
                let newEmptyCount = emptyCount + 1
                if newEmptyCount >= self.maxEmptyCells {
                    self.showLavaCooledEffect(at: cell.position)
                    self.lavaFlowEnded()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.continueLavaFlow(fromCol: nextCol, fromRow: nextRow, direction: direction, emptyCount: newEmptyCount)
                    }
                }
            }
        }
    }
    
    private func continueLavaFlow(fromCol: Int, fromRow: Int, direction: FlowDirection, emptyCount: Int) {
        let nextCol = fromCol + Int(direction.vector.dx)
        let nextRow = fromRow + Int(direction.vector.dy)
        
        guard nextRow >= 0 && nextRow < gridCells.count &&
              nextCol >= 0 && nextCol < gridCells[0].count else {
            lavaFlowEnded()
            return
        }
        
        for (index, target) in level.targets.enumerated() {
            let targetGridX = Int(target.position.x * level.gridSize.width)
            let targetGridY = Int(target.position.y * level.gridSize.height)
            if nextCol == targetGridX && nextRow == targetGridY {
                reachedTargets.insert(index)
                animateTargetReached(index: index)
                lavaFlowEnded()
                return
            }
        }
        
        let cell = gridCells[nextRow][nextCol]
        
        let lavaNode = SKShapeNode(circleOfRadius: cellSize * 0.3)
        lavaNode.fillColor = lavaColor
        lavaNode.strokeColor = .clear
        lavaNode.position = cell.position
        lavaNode.zPosition = 4
        lavaNode.alpha = 0
        addChild(lavaNode)
        lavaNodes.append(lavaNode)
        
        lavaNode.run(SKAction.fadeIn(withDuration: 0.15)) { [weak self] in
            guard let self = self else { return }
            
            if let element = self.placedElements.first(where: {
                Int($0.gridPosition.x) == nextCol && Int($0.gridPosition.y) == nextRow
            }) {
                if element.type == .block {
                    self.lavaFlowEnded()
                    return
                }
                
                let outputDirections = element.getOutputDirections(inputDirection: direction)
                if outputDirections.isEmpty {
                    self.lavaFlowEnded()
                } else {
                    self.activeLavaFlows += outputDirections.count - 1
                    for outputDir in outputDirections {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.continueLavaFlow(fromCol: nextCol, fromRow: nextRow, direction: outputDir, emptyCount: 0)
                        }
                    }
                }
            } else {
                let newEmptyCount = emptyCount + 1
                if newEmptyCount >= self.maxEmptyCells {
                    self.showLavaCooledEffect(at: cell.position)
                    self.lavaFlowEnded()
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.continueLavaFlow(fromCol: nextCol, fromRow: nextRow, direction: direction, emptyCount: newEmptyCount)
                    }
                }
            }
        }
    }
    
    private func lavaFlowEnded() {
        activeLavaFlows -= 1
        if activeLavaFlows <= 0 && isLavaFlowing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.finishLavaFlow()
            }
        }
    }
    
    private func showLavaCooledEffect(at position: CGPoint) {
        let cooledNode = SKShapeNode(circleOfRadius: cellSize * 0.25)
        cooledNode.fillColor = UIColor(red: 0.3, green: 0.2, blue: 0.2, alpha: 1.0)
        cooledNode.strokeColor = UIColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0)
        cooledNode.lineWidth = 2
        cooledNode.position = position
        cooledNode.zPosition = 4
        addChild(cooledNode)
        lavaNodes.append(cooledNode)
        
        for _ in 0..<5 {
            let smoke = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            smoke.fillColor = UIColor(white: 0.5, alpha: 0.6)
            smoke.strokeColor = .clear
            smoke.position = position
            smoke.zPosition = 5
            addChild(smoke)
            
            let moveUp = SKAction.moveBy(x: CGFloat.random(in: -15...15), y: CGFloat.random(in: 20...40), duration: 1.0)
            let fadeOut = SKAction.fadeOut(withDuration: 1.0)
            let remove = SKAction.removeFromParent()
            smoke.run(SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove]))
        }
    }
    
    private func animateTargetReached(index: Int) {
        guard index < targetNodes.count else { return }
        let targetNode = targetNodes[index]
        
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        
        targetNode.run(SKAction.sequence([scaleUp, scaleDown]))
        
        if let shape = targetNode.childNode(withName: "mainShape") as? SKShapeNode {
            shape.fillColor = lavaColor
            shape.strokeColor = lavaColor.withAlphaComponent(0.8)
        }
        
        if let ring = targetNode.childNode(withName: "pulseRing") as? SKShapeNode {
            ring.strokeColor = lavaColor
        }
        
        for _ in 0..<10 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = lavaGlow
            particle.strokeColor = .clear
            particle.position = targetNode.position
            particle.zPosition = 6
            addChild(particle)
            
            let randomX = CGFloat.random(in: -30...30)
            let randomY = CGFloat.random(in: -30...30)
            let moveAction = SKAction.move(by: CGVector(dx: randomX, dy: randomY), duration: 0.5)
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let removeAction = SKAction.removeFromParent()
            
            particle.run(SKAction.sequence([SKAction.group([moveAction, fadeAction]), removeAction]))
        }
    }
    
    private func finishLavaFlow() {
        guard isLavaFlowing else { return }
        isLavaFlowing = false
        gameDelegate?.gameScene(self, didComplete: reachedTargets.count, totalTargets: level.targets.count, elementsUsed: placedElements.count)
    }
    
    func getPlacedElementsCount() -> Int {
        return placedElements.count
    }
    
    func resetLevel() {
        lavaNodes.forEach { $0.removeFromParent() }
        lavaNodes.removeAll()
        
        placedElements.removeAll()
        
        for node in elementNodes {
            node.removeFromParent()
        }
        elementNodes.removeAll()
        availableElements.removeAll()
        
        setupAvailableElements()
        
        for (index, targetNode) in targetNodes.enumerated() {
            targetNode.removeAllActions()
            targetNode.setScale(1.0)
            targetNode.colorBlendFactor = 0
            
            let target = level.targets[index]
            var targetColor: UIColor
            switch target.type {
            case .village:
                targetColor = UIColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 1.0)
            case .altar:
                targetColor = UIColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0)
            case .garden:
                targetColor = UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
            }
            
            if let shape = targetNode.childNode(withName: "mainShape") as? SKShapeNode {
                shape.removeAllActions()
                shape.fillColor = targetColor
                shape.strokeColor = targetColor.withAlphaComponent(0.8)
            }
            
            if let ring = targetNode.childNode(withName: "pulseRing") as? SKShapeNode {
                ring.removeAllActions()
                ring.setScale(1.0)
                ring.alpha = 0.8
                ring.strokeColor = targetColor
                
                let pulseAction = SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.5, duration: 1.0),
                        SKAction.fadeAlpha(to: 0, duration: 1.0)
                    ]),
                    SKAction.group([
                        SKAction.scale(to: 1.0, duration: 0),
                        SKAction.fadeAlpha(to: 0.8, duration: 0)
                    ])
                ])
                ring.run(SKAction.repeatForever(pulseAction))
            }
        }
        
        reachedTargets.removeAll()
        isLavaFlowing = false
        activeLavaFlows = 0
        
        setupTutorialHint()
    }
}

