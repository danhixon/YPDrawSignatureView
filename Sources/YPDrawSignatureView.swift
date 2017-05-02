// YPDrawSignatureView is open source
// Version 1.0
//
// Copyright (c) 2014 - 2016 Yuppielabel and the project contributors
// Available under the MIT license
//
// See https://github.com/GJNilsen/YPDrawSignatureView/blob/master/LICENSE for license information
// See https://github.com/GJNilsen/YPDrawSignatureView/blob/master/README.md for the list project contributors

import UIKit

// MARK: Class properties and initialization
/// # Class: YPDrawSignatureView
/// Accepts touches and draws an image to an UIView
/// ## Description
/// This is an UIView based class for capturing a signature drawn by a finger in iOS.
/// ## Usage
/// Add the YPSignatureDelegate to the view to exploit the optional delegate methods
/// - startedDrawing()
/// - finishedDrawing()
/// - Add an @IBOutlet, and set its delegate to self
/// - Clear the signature field by calling clear() to it
/// - Retrieve the signature from the field by either calling
/// - getSignature() or
/// - getCroppedSignature()
@IBDesignable
public class YPDrawSignatureView: UIView {
    
    weak var delegate: YPDrawSignatureViewDelegate?
    
    // MARK: - Public properties
    @IBInspectable public var strokeWidth: CGFloat = 2.0 {
        didSet {
            self.path.lineWidth = strokeWidth
        }
    }
    
    @IBInspectable public var strokeColor: UIColor = UIColor.black {
        didSet {
            self.strokeColor.setStroke()
        }
    }
    
    @IBInspectable public var signatureBackgroundColor: UIColor = UIColor.white {
        didSet {
            self.backgroundColor = signatureBackgroundColor
        }
    }
    
    @IBInspectable public var circularDots: Bool = true
    
    // Computed Property returns true if the view actually contains a signature
    public var containsSignature: Bool {
        get {
            if self.path.isEmpty {
                return false
            } else {
                return true
            }
        }
    }
    
    // MARK: - Private properties
    private var path = UIBezierPath()
    private var pts = [CGPoint](repeating: CGPoint(), count: 5)
    private var ctr = 0
    
    // MARK: - Init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    private func initialize() {
        self.backgroundColor = self.signatureBackgroundColor
        self.path.lineWidth = self.strokeWidth
        self.path.lineJoinStyle = CGLineJoin.round
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: - Draw
    override public func draw(_ rect: CGRect) {
        self.strokeColor.setStroke()
        self.path.stroke()
    }
    
    // MARK: - Touch handling functions
    override public func touchesBegan(_ touches: Set <UITouch>, with event: UIEvent?) {
        
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.location(in: self)
            self.ctr = 0
            self.pts[0] = touchPoint
        }
        
        
        delegate?.startedSignatureDrawing!()
    }
    
    override public func touchesMoved(_ touches: Set <UITouch>, with event: UIEvent?) {
        
        if let firstTouch = touches.first {
            let touchPoint = firstTouch.location(in: self)
            self.ctr += 1
            self.pts[self.ctr] = touchPoint
            if (self.ctr == 4) {
                self.pts[3] = CGPoint( x: (self.pts[2].x + self.pts[4].x)/2.0, y: (self.pts[2].y + self.pts[4].y)/2.0 )
                self.path.move(to: self.pts[0])
                self.path.addCurve(to: self.pts[3], controlPoint1:self.pts[1], controlPoint2:self.pts[2])
                
                self.setNeedsDisplay()
                self.pts[0] = self.pts[3]
                self.pts[1] = self.pts[4]
                self.ctr = 1
            }
            
            self.setNeedsDisplay()
        }
    }
    
    override public func touchesEnded(_ touches: Set <UITouch>, with event: UIEvent?) {
        self.ctr = 0
        delegate?.finishedSignatureDrawing!()
    }
    
    @objc private func viewTapped(g: UIGestureRecognizer) {
        let touchPoint = self.pts[0]
        self.path.move( to: CGPoint( x: touchPoint.x-1.0,y: touchPoint.y ) )
        if circularDots {
            self.path.addArc(withCenter: touchPoint, radius: 0.7, startAngle: 0, endAngle: CGFloat(2*π), clockwise: true)
        } else {
            self.path.addLine( to: CGPoint( x: touchPoint.x+1.0, y: touchPoint.y ) )
        }
        self.setNeedsDisplay()
    }
    
    // MARK: - Methods for interacting with Signature View
    
    // Clear the Signature View
    public func clearSignature() {
        self.path.removeAllPoints()
        self.setNeedsDisplay()
    }
    
    // Save the Signature as an UIImage
    public func getSignature(scale:CGFloat = 1) -> UIImage? {
        if !containsSignature { return nil }
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, scale)
        self.path.stroke()
        let signature = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return signature
    }
    
    // Save the Signature (cropped of outside white space) as a UIImage
    public func getSignatureCropped(scale:CGFloat = 1) -> UIImage? {
        guard let fullRender = getSignature(scale:scale) else { return nil }
        let bounds = scaleRect(rect: path.bounds.insetBy(dx: -strokeWidth/2, dy: -strokeWidth/2), byFactor: scale)
        guard let imageRef = fullRender.cgImage!.cropping(to: bounds) else { return nil }
        return UIImage(cgImage: imageRef)
    }
    
    func scaleRect(rect: CGRect, byFactor factor: CGFloat) -> CGRect
    {
        var scaledRect = rect
        scaledRect.origin.x *= factor
        scaledRect.origin.y *= factor
        scaledRect.size.width *= factor
        scaledRect.size.height *= factor
        return scaledRect
    }
}

// MARK: - Optional Protocol Methods for YPDrawSignatureViewDelegate
@objc protocol YPDrawSignatureViewDelegate: class {
    @objc optional func startedSignatureDrawing()
    @objc optional func finishedSignatureDrawing()
}
