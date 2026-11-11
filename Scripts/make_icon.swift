// Renders the app icon to a 1024px PNG. Usage: swift Scripts/make_icon.swift out.png
import AppKit

let out = CommandLine.arguments.dropFirst().first ?? "icon.png"
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let inset: CGFloat = 100
let rect = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
let shape = NSBezierPath(roundedRect: rect, xRadius: 185, yRadius: 185)

NSGraphicsContext.current?.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
shadow.shadowBlurRadius = 24
shadow.shadowOffset = NSSize(width: 0, height: -10)
shadow.set()
NSColor.white.setFill()
shape.fill()
NSGraphicsContext.current?.restoreGraphicsState()

NSGradient(colors: [
    NSColor(srgbRed: 0.13, green: 0.72, blue: 0.62, alpha: 1),
    NSColor(srgbRed: 0.10, green: 0.42, blue: 0.80, alpha: 1),
])!.draw(in: shape, angle: -70)

let config = NSImage.SymbolConfiguration(pointSize: 420, weight: .medium)
    .applying(.init(paletteColors: [.white]))
if let symbol = NSImage(systemSymbolName: "menubar.arrow.up.rectangle", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let s = symbol.size
    symbol.draw(in: NSRect(x: (size - s.width) / 2, y: (size - s.height) / 2 - 10, width: s.width, height: s.height))
}

image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
