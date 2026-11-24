// Draws assets/default-icon.png (1024x1024): a white bell on a warm gradient.
// Run: swift assets/make-default-icon.swift assets/default-icon.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "default-icon.png"
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Rounded-square background, macOS icon proportions (824 box inside 1024).
let box = NSRect(x: 100, y: 100, width: 824, height: 824)
let bg = NSBezierPath(roundedRect: box, xRadius: 185, yRadius: 185)
NSGradient(starting: NSColor(red: 1.00, green: 0.62, blue: 0.25, alpha: 1),
           ending: NSColor(red: 0.91, green: 0.27, blue: 0.36, alpha: 1))!.draw(in: bg, angle: -90)

NSColor.white.setFill()
let cx: CGFloat = 512
// Bell body: dome on top, flaring out to a wide rim.
let bell = NSBezierPath()
bell.move(to: NSPoint(x: cx - 250, y: 360))
bell.line(to: NSPoint(x: cx + 250, y: 360))
bell.curve(to: NSPoint(x: cx + 175, y: 470), controlPoint1: NSPoint(x: cx + 250, y: 400), controlPoint2: NSPoint(x: cx + 175, y: 420))
bell.line(to: NSPoint(x: cx + 175, y: 590))
bell.curve(to: NSPoint(x: cx - 175, y: 590), controlPoint1: NSPoint(x: cx + 175, y: 790), controlPoint2: NSPoint(x: cx - 175, y: 790))
bell.line(to: NSPoint(x: cx - 175, y: 470))
bell.curve(to: NSPoint(x: cx - 250, y: 360), controlPoint1: NSPoint(x: cx - 175, y: 420), controlPoint2: NSPoint(x: cx - 250, y: 400))
bell.close()
bell.fill()
// Knob on top and clapper below.
NSBezierPath(ovalIn: NSRect(x: cx - 42, y: 715, width: 84, height: 84)).fill()
NSBezierPath(ovalIn: NSRect(x: cx - 70, y: 245, width: 140, height: 140)).fill()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print(out)
