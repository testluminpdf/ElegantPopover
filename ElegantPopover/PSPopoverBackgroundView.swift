//
//  PSPopoverBackgroundView.swift
//  ElegantPopover
//
//  Created by Prasad on 04/02/20.
//  Copyright © 2020 Prasad Shinde. All rights reserved.
//


import UIKit
import ClippingBezier

open class PSPopoverBackgroundView: UIPopoverBackgroundView {
    
    private struct Arrow {
        var height: CGFloat!
        var apex: CGPoint!
        var base: CGFloat!
        var halfBase: CGFloat {
            return base/2
        }
        var leftCurveRadius: CGFloat!
        var rightCurveRadius: CGFloat!
        var inset: CGFloat!
        
        init (apex: CGPoint, height: CGFloat, base: CGFloat, leftCurveRadius: CGFloat, rightCurveRadius: CGFloat, inset: CGFloat = 0) {
            
            self.inset = inset
            self.height = height
            self.apex = apex
            self.base = base
            self.leftCurveRadius = leftCurveRadius
            self.rightCurveRadius = rightCurveRadius
        }
    }
    
    static weak var currPopover: ElegantPopoverController?
    private var path : UIBezierPath!
    private var arrow: Arrow!
    private var cornerRadius: CGFloat!
    private var _arrowDirection : UIPopoverArrowDirection! = .any
    private var _arrowOffset : CGFloat!
    private var mainRect: CGRect!
    private var subRect: CGRect!
    open var design: PSDesign!
    open var elegantArrow: PSArrow!
    open var shadow: PSShadow?
    private var startPoint: CGPoint!
    private var popoverBounds: CGRect!
    
    private var arcAngle: CGFloat {
        return atan(arrow.height / arrow.halfBase)
    }
    
    private var rightArcX: CGFloat {
        return arrow.apex.x + arrow.halfBase + arrow.rightCurveRadius * tan(arcAngle/2)
    }
    
    private var leftArcX: CGFloat {
        return arrow.apex.x - arrow.halfBase - arrow.leftCurveRadius * tan(arcAngle/2)
    }
    
    private let containerLayer: CALayer = CALayer()
    private let shadowLayer: CALayer = CALayer()

    open override var arrowOffset: CGFloat {
        get {
            return self.arrowOffset
        }
        set {
            _arrowOffset = newValue
        }
    }
    
    open override var arrowDirection: UIPopoverArrowDirection {
        get {
            var string = "any"
            switch self._arrowDirection {
            case UIPopoverArrowDirection.left:
                string = "left"
            case UIPopoverArrowDirection.right:
                string = "right"
            case UIPopoverArrowDirection.up:
                string = "up"
            case UIPopoverArrowDirection.down:
                string = "down"
            default:
                string = "any"
            }
            print("arrowDirection: \(string)")
            return self._arrowDirection
        }
        set {
            self._arrowDirection = newValue
            PSPopoverBackgroundView.currPopover?.setArrowDirection(self._arrowDirection!)
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        self.design = PSPopoverBackgroundView.currPopover?.getDesign()
        self.elegantArrow = PSPopoverBackgroundView.currPopover?.getArrow()
        self.shadow = PSPopoverBackgroundView.currPopover?.getShadow()
        self.layer.addSublayer(self.shadowLayer)
        self.layer.addSublayer(self.containerLayer)
        self.layer.masksToBounds = false
        layer.shadowColor = UIColor.clear.cgColor
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override class func contentViewInsets() -> UIEdgeInsets{
        return UIEdgeInsets.zero
    }
    
    open override class func arrowHeight() -> CGFloat {
        return 0
    }
    
    open override class func arrowBase() -> CGFloat{
        return 0
    }
    
    open override func didMoveToWindow() {
        super.didMoveToWindow()
        if #available(iOS 13, *) {
            // iOS 13 (or newer)
            if let window = UIApplication.shared.keyWindow {
                self.hideShadowViewRecursively(in: window)
//                let transitionViews = window.subviews.filter { String(describing: type(of: $0)) == "UITransitionView" }
//                for transitionView in transitionViews {
//                    let shadowView = transitionView.subviews.filter { String(describing: type(of: $0)) == "_UICutoutShadowView" }.first
//                    shadowView?.isHidden = true
//                }
            }
        }
    }
    
    func hideShadowViewRecursively(in view: UIView) {
        for subview in view.subviews {
            if String(describing: type(of: subview)) == "_UICutoutShadowView" {
                subview.isHidden = true;
                return
            } else {
                self.hideShadowViewRecursively(in: subview)
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.containerLayer.frame = self.layer.bounds
        layoutLayers()
        
        if let contentView = self.findContentViewController()?.view {
            switch self.arrowDirection {
            case .left:
                contentView.frame.origin = CGPoint(x: design.insets.left + arrow.height, y: design.insets.top)
            case .right, .down:
                contentView.frame.origin = CGPoint(x: design.insets.left, y: design.insets.top)
            case .up:
                contentView.frame.origin = CGPoint(x: design.insets.left, y: design.insets.top + arrow.height)
            default:
                break
            }
        }
    }
        
    private func initialize(inset: CGFloat, borderWidth: CGFloat) {
        path = UIBezierPath()
        cornerRadius -= borderWidth
        cornerRadius = max(cornerRadius, 0)
        
        let multiplier: CGFloat = (_arrowDirection! == .left || _arrowDirection! == .down) ? -1 : 1
        var apexX = min(mainRect.width/2 + _arrowOffset * multiplier, mainRect.width - elegantArrow.base/2)
        apexX = max(apexX, elegantArrow.base/2)
        
        arrow = Arrow(apex: CGPoint(x: apexX, y: 0 + inset / cos(atan(elegantArrow.height/(elegantArrow.base/2)))),           height: elegantArrow.height,
                      base: elegantArrow.base,
                      leftCurveRadius: elegantArrow.baseCornerRadius,
                      rightCurveRadius: elegantArrow.baseCornerRadius,
                      inset: inset)
        
        subRect = CGRect(x: 0 + inset,
                         y: arrow.height + inset,
                         width: mainRect.width - 2 * inset,
                         height: mainRect.height - arrow.height - 2 * inset)
                
        if rightArcX > subRect.maxX {
            if arrow.rightCurveRadius * tan(arcAngle/2) <= rightArcX - subRect.maxX {
                arrow.rightCurveRadius = 0
            } else {
                let diff = (rightArcX - subRect.maxX) - arrow.rightCurveRadius * tan(arcAngle/2)
                let rightCurveRadius = (diff / tan(arcAngle/2))
                arrow.rightCurveRadius = rightCurveRadius
            }
        }
        
        if leftArcX < subRect.minX {
            if arrow.leftCurveRadius * tan(arcAngle/2) <= subRect.minX - leftArcX {
                arrow.leftCurveRadius = 0
            } else {
                let diff = (subRect.minX - leftArcX) - arrow.leftCurveRadius * tan(arcAngle/2)
                let leftCurveRadius = (diff / tan(arcAngle/2))
                arrow.leftCurveRadius = leftCurveRadius
            }
        }

    }
    
    open func layoutLayers() {
        let rect = self.bounds
        cornerRadius = design.cornerRadius
        if _arrowDirection! == .up || _arrowDirection! == .down {
            mainRect = rect
        } else {
            mainRect = CGRect(origin: rect.origin,
                              size: CGSize(width: rect.height, height: rect.width))
        }
        elegantArrow.base = min(elegantArrow.base, mainRect.width)
        
        drawPopover()
        rotatePath(using: rect)
        
        fillShadow(with: shadow)

        popoverBounds = path.bounds
        
        var cumulativeBorders = design.borders
        let borders = design.borders
            
        if cumulativeBorders.isEmpty {
            fillPath(with: .pureColor(design.backGroundColor))
            return
        }
        
        fillPath(with: cumulativeBorders[0].filling)
        
        for i in 1..<cumulativeBorders.count {
            drawPopover(inset: cumulativeBorders[i - 1].width,
                        borderWidth: borders[i - 1].width,
                        shouldDrawArrow: design.solidArrowBorderIndex == nil || i <= design.solidArrowBorderIndex!)
            
            rotatePath(using: rect)
            fillPath(with: cumulativeBorders[i].filling)
            cumulativeBorders[i].width += cumulativeBorders[i - 1].width
        }
        
        drawPopover(inset: (cumulativeBorders[cumulativeBorders.endIndex - 1].width),
                    borderWidth: borders[borders.endIndex - 1].width,
                    shouldDrawArrow: design.solidArrowBorderIndex == nil || borders.count <= design.solidArrowBorderIndex!)
        rotatePath(using: rect)
        fillPath(with: .pureColor(design.backGroundColor))

    }
        
    private func drawPopover(inset: CGFloat = 0, borderWidth: CGFloat = 0, shouldDrawArrow: Bool = true) {
        initialize(inset: inset, borderWidth: borderWidth)
        drawLeftLine()
        drawBottomLine()
        drawRightLine()
        drawTopLine(inset, shouldDrawArrow)
        path.close()
        
        let boxPath = UIBezierPath(rect: CGRect(x: subRect.minX,
                                                y: arrow.apex.y,
                                                width: subRect.width,
                                                height: subRect.maxY - arrow.apex.y))
        
        if let newPaths = path.uniqueShapesCreatedFromSlicing(withUnclosedPath: boxPath) {
            for newPath in newPaths {
                if let fullPath = newPath.fullPath(),
                    fullPath.bounds.width <= subRect.width + 1,
                    fullPath.bounds.width >= subRect.width - 1 {
                    path = fullPath
                }
            }
        }
    }
    
    private func fillPath(with filling: PSBorder.Filling) {
        var layerToBeInserted: CALayer
        
        switch filling {
            
        case .layer(let layer):
            layerToBeInserted = layer
            layerToBeInserted.frame = popoverBounds
            
        case .pureColor(let color):
            layerToBeInserted = CALayer()
            layerToBeInserted.frame = popoverBounds
            layerToBeInserted.backgroundColor = color.cgColor
        }
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        layerToBeInserted.mask = shapeLayer

        if popoverBounds == path.bounds {
            if let superview = superview,
               let contentViewController = findContentViewController(in: superview),
               let contentView = contentViewController.view {
                let newShapeLayer = CAShapeLayer()
                newShapeLayer.path = self.path.cgPath
                newShapeLayer.frame = contentView.bounds
                contentView.layer.mask = newShapeLayer
            }

            self.containerLayer.mask = shapeLayer
        }
        
        self.containerLayer.insertSublayer(layerToBeInserted, at: UInt32(self.containerLayer.sublayers?.count ?? 0))
    }
    
    private func findContentViewController() -> UIViewController? {
        if let superview = superview,
           let contentViewController = findContentViewController(in: superview) {
            return contentViewController
        } else {
            return nil
        }
    }
    
    private func findContentViewController(in view: UIView) -> UIViewController? {
        return findContentViewControllerRecursively(in: view)
    }
    
    private func findContentViewControllerRecursively(in view: UIView) -> UIViewController? {
        if let viewController = view.next as? UIViewController {
            return viewController
        }
        for subview in view.subviews {
            if let viewController = self.findContentViewControllerRecursively(in: subview) {
                return viewController
            }
        }
        return nil
    }
    
    private func fillShadow(with shadow: PSShadow?) {
        guard let shadow = shadow else { return }
        self.shadowLayer.shadowOffset = shadow.shadowOffset
        self.shadowLayer.shadowOpacity = shadow.shadowOpacity
        self.shadowLayer.shadowRadius = shadow.shadowRadius
        self.shadowLayer.shadowColor = shadow.shadowColor?.cgColor
        self.shadowLayer.shadowOffset = shadow.shadowOffset
        self.shadowLayer.masksToBounds = false
        if shadow.shadowSpread == 0 {
            self.shadowLayer.shadowPath = self.path.cgPath
        } else {
            let originPath = self.path
            let inset = -shadow.shadowSpread
            drawPopover(inset: inset)
            self.shadowLayer.shadowPath = self.path.cgPath
            self.path = originPath
        }
    }
    
    private func drawLeftLine() {
        
        if leftArcX < subRect.minX + cornerRadius,
            arrow.height > 0 {
            
            let curveRadius = max(leftArcX - subRect.minX, 0)
            
            startPoint = CGPoint(x: leftArcX,
                                 y: subRect.minY)
            
            path.addArc(withCenter: CGPoint(x: leftArcX, y: subRect.minY + leftArcX - subRect.minX),
                        radius: curveRadius,
                        startAngle: getRadians(270),
                        endAngle: getRadians(180),
                        clockwise: false)
        } else {
            startPoint = CGPoint(x: subRect.minX + cornerRadius,
                                 y: subRect.minY)
            
            path.addArc(withCenter: CGPoint(x: subRect.minX + cornerRadius, y: subRect.minY + cornerRadius),
                        radius: cornerRadius,
                        startAngle: getRadians(270),
                        endAngle: getRadians(180),
                        clockwise: false)
        }
        
        path.addLine(to: CGPoint(x: subRect.minX, y: subRect.maxY - cornerRadius))
        path.addArc(withCenter: CGPoint(x: subRect.minX + cornerRadius,y: subRect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: getRadians(180),
                    endAngle: getRadians(90),
                    clockwise: false)
    }
    
    private func drawBottomLine() {
        path.addLine(to: CGPoint(x: subRect.maxX - cornerRadius,
                                 y: subRect.maxY))
    }
    
    private func drawRightLine() {
        path.addArc(withCenter: CGPoint(x: subRect.maxX - cornerRadius, y: subRect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: getRadians(90),
                    endAngle: getRadians(0),
                    clockwise: false)
        
        var curveRadius: CGFloat = self.cornerRadius
                
        if arrow.height > 0,
            rightArcX > (subRect.maxX - curveRadius) {
            curveRadius = max(subRect.maxX - (rightArcX), 0)
        }
        
        path.addLine(to: CGPoint(x: subRect.maxX,
                                 y: subRect.minY + curveRadius))
        
        path.addArc(withCenter: CGPoint(x: subRect.maxX - curveRadius,y: subRect.minY + curveRadius),
                    radius: curveRadius,
                    startAngle: getRadians(0),
                    endAngle: getRadians(270),
                    clockwise: false)
    }
    
    private func drawTopLine(_ inset: CGFloat, _ shouldDrawArrow: Bool) {
        if arrow.height > 0 {
            
            if shouldDrawArrow {
                path.addLine(to: CGPoint(x: rightArcX, y: subRect.minY))
                drawArrow()
            } else if rightArcX < path.currentPoint.x{
                path.addLine(to: CGPoint(x: rightArcX, y: subRect.minY))
            }
        }
        path.addLine(to: startPoint)
    }
    
    private func drawArrow() {
        
        let leftArcY = subRect.minY - arrow.leftCurveRadius - arrow.inset
        let rightArcY = subRect.minY - arrow.rightCurveRadius - arrow.inset
        let leftArcRadius = arrow.leftCurveRadius + arrow.inset
        let rightArcRadius = arrow.rightCurveRadius + arrow.inset
        
        var rightArcEndAngle = getRadians(90) + arcAngle
        var leftArcStartAngle = getRadians(90) - arcAngle
        
        if rightArcX - rightArcRadius * sin(arcAngle) < arrow.apex.x {
            let rightAngle = asin((rightArcX - arrow.apex.x) / rightArcRadius)
            let leftAngle = asin((arrow.apex.x - leftArcX) / leftArcRadius)
            
            rightArcEndAngle = rightAngle + getRadians(90)
            leftArcStartAngle = getRadians(90) - leftAngle
            
            if arrow.rightCurveRadius != 0 {
                path.addArc(withCenter: CGPoint(x: rightArcX, y: rightArcY),
                            radius: rightArcRadius,
                            startAngle: getRadians(90),
                            endAngle: rightArcEndAngle,
                            clockwise: true)
                
                arrow.apex.y = path.currentPoint.y
            }

        } else {
            path.addArc(withCenter: CGPoint(x: rightArcX, y: rightArcY),
                        radius: rightArcRadius,
                        startAngle: getRadians(90),
                        endAngle: rightArcEndAngle,
                        clockwise: true)
            
            path.addLine(to: arrow.apex)
            
            path.addLine(to: CGPoint(x: leftArcX + leftArcRadius * sin(arcAngle),
                                     y: leftArcY + leftArcRadius * cos(arcAngle)))
        }
        
        path.addArc(withCenter: CGPoint(x: leftArcX, y: leftArcY),
                    radius: leftArcRadius,
                    startAngle: leftArcStartAngle,
                    endAngle: getRadians(90),
                    clockwise: true)
    }
    
    private func rotatePath(using rect: CGRect) {
        switch _arrowDirection! {
        case .left:
            path.translateAndRotate(angle: getRadians(-90),translation: (0, rect.height))
        case .right:
            path.translateAndRotate(angle: getRadians(90), translation: (rect.width, 0))
        case .down:
            path.translateAndRotate(angle: getRadians(180), translation: (rect.width, rect.height))
        default:
            break
        }
    }
    
    private func cosOf(_ angle: CGFloat) -> CGFloat {
        return cos(getRadians(angle))
    }
    
    private func sinOf(_ angle: CGFloat) -> CGFloat {
        return sin(getRadians(angle))
    }
    
    private func tanOf(_ angle: CGFloat) -> CGFloat {
        return tan(getRadians(angle))
    }
    
    private func getRadians(_ degree: CGFloat) -> CGFloat {
        return (degree * CGFloat.pi)/180
    }
    
    private func getDegrees(_ radians: CGFloat) -> CGFloat {
        return radians * 180 / .pi
    }
}

extension UIBezierPath {
    
    func translateAndRotate(angle: CGFloat, translation: (x: CGFloat, y: CGFloat)) {
        
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        transform = transform.rotated(by: angle)
        self.apply(transform)
    }
}
