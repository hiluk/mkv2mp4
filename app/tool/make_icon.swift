// Рисует иконку приложения 1024×1024: swift tool/make_icon.swift <out.png>
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"

let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext

// Сетка иконок macOS: тело 824×824 с отступом 100 и радиусом ~185.
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

// Тень
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28,
              color: NSColor.black.withAlphaComponent(0.35).cgColor)
ctx.addPath(shape)
ctx.setFillColor(NSColor.black.cgColor)
ctx.fillPath()
ctx.restoreGState()

// Градиент индиго → фиолетовый
ctx.saveGState()
ctx.addPath(shape)
ctx.clip()
let colors = [
    NSColor(srgbRed: 0.36, green: 0.42, blue: 0.98, alpha: 1).cgColor,
    NSColor(srgbRed: 0.55, green: 0.27, blue: 0.86, alpha: 1).cgColor,
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100), options: [])
// Лёгкий блик сверху
ctx.setFillColor(NSColor.white.withAlphaComponent(0.08).cgColor)
ctx.fillEllipse(in: CGRect(x: -100, y: 560, width: 1224, height: 700))
ctx.restoreGState()

func symbol(_ name: String, pointSize: CGFloat) -> NSImage {
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    return NSImage(systemSymbolName: name, accessibilityDescription: nil)!
        .withSymbolConfiguration(config)!
}

func draw(_ image: NSImage, centeredAt c: CGPoint) {
    let s = image.size
    image.draw(in: CGRect(x: c.x - s.width / 2, y: c.y - s.height / 2, width: s.width, height: s.height))
}

// Плёнка → стрелка → «MP4»
draw(symbol("film", pointSize: 330), centeredAt: CGPoint(x: 512, y: 610))

let text = "MP4" as NSString
let font = NSFont.systemFont(ofSize: 190, weight: .heavy)
let rounded = NSFont(descriptor: font.fontDescriptor.withDesign(.rounded) ?? font.fontDescriptor, size: 190) ?? font
let attrs: [NSAttributedString.Key: Any] = [.font: rounded, .foregroundColor: NSColor.white, .kern: 6]
let ts = text.size(withAttributes: attrs)
text.draw(at: CGPoint(x: 512 - ts.width / 2, y: 215), withAttributes: attrs)

NSGraphicsContext.restoreGraphicsState()
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("OK \(out)")
