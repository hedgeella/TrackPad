# TrackPad — Trackpad Drawing App for macOS

A native macOS drawing and note-taking application built with Swift and SwiftUI that transforms your MacBook trackpad into a pressure-sensitive drawing surface. Inspired by apps like Notability.

## Features

### Trackpad as Drawing Tablet
- **Force Touch pressure sensitivity** — line thickness responds to how hard you press on the trackpad (requires Force Touch trackpad, 2015+ MacBooks)
- **Smooth Bezier curve rendering** — strokes are smoothed using quadratic Bezier interpolation for natural-looking lines
- **Minimal latency** — point-distance filtering removes jitter while keeping drawing responsive

### Drawing Tools
- **Pen** — pressure-sensitive ink with adjustable width and full color selection
- **Highlighter** — semi-transparent strokes for marking up content
- **Eraser** — removes strokes that intersect with the eraser path
- **Lasso** — selection tool (planned)

### Canvas & Navigation
- **Pinch-to-zoom** — use trackpad gestures to zoom in/out (0.25x – 5x)
- **Two-finger scroll** — pan around the canvas
- **Cmd+scroll** — alternative zoom control
- **Cmd+0** — reset zoom to 100%

### Page Backgrounds
- Blank, Lined, Grid, and Dot Grid styles
- Red margin line on lined pages

### Multi-Page Notebooks
- Add, delete, and navigate between pages
- Page sidebar with thumbnail previews
- Stroke count indicators

### Export
- **PDF** — export single pages or entire multi-page notebooks
- **PNG** — export current page as a high-resolution image (2x scale)

### Document Management
- Auto-save to Application Support directory (JSON-based `.trackpad` format)
- Open/save dialogs
- Document listing with metadata

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| ⌘N | New notebook |
| ⌘O | Open notebook |
| ⌘S | Save notebook |
| ⌘E | Export as PDF |
| ⌘Z | Undo |
| ⇧⌘Z | Redo |
| ⌘0 | Reset zoom |
| ⌘1 | Pen tool |
| ⌘2 | Highlighter tool |
| ⌘3 | Eraser tool |
| ⌘4 | Lasso tool |

## Requirements

- **macOS 13.0** (Ventura) or later
- **Xcode 15.0** or later
- **Force Touch trackpad** recommended for pressure sensitivity (falls back to constant pressure on older trackpads)

## Building

### Using Xcode
1. Open `TrackPad.xcodeproj` in Xcode
2. Select the "TrackPad" scheme
3. Press ⌘R to build and run

### Using Swift Package Manager
```bash
swift build
swift run TrackPad
```

## Project Structure

```
TrackPad/
├── TrackPadApp.swift          # App entry point, menu commands
├── ContentView.swift          # Main window layout
├── Models/
│   ├── Stroke.swift           # Stroke data model with pressure points
│   ├── DrawingTool.swift      # Tool types and state
│   ├── Page.swift             # Page model with background styles
│   └── Document.swift         # Notebook document model
├── Views/
│   ├── CanvasView.swift       # Canvas container with status bar
│   ├── TrackpadDrawingView.swift  # Core NSView for trackpad drawing
│   ├── ToolbarView.swift      # Drawing toolbar
│   ├── ColorPicker.swift      # Color selection popover
│   ├── StrokeOptionsView.swift # Line width controls
│   ├── PageThumbnailView.swift # Page previews in sidebar
│   └── SidebarView.swift      # Page navigation sidebar
├── Drawing/
│   ├── DrawingEngine.swift    # Stroke rendering engine
│   └── TrackpadInputHandler.swift  # Trackpad event processing
└── Utilities/
    ├── ExportManager.swift    # PDF/PNG export
    └── DocumentManager.swift  # File save/load
```

## How Trackpad Drawing Works

The app uses macOS's native `NSEvent` pressure API, which provides force values from Force Touch trackpads:

1. **`TrackpadInputHandler`** captures `mouseDown`, `mouseDragged`, and `mouseUp` events
2. **`NSEvent.pressure`** returns a 0.0–1.0 force value from the Force Touch sensor
3. Each point is recorded as a `StrokePoint` with x, y, pressure, and timestamp
4. The **`DrawingEngine`** renders variable-width strokes using `NSBezierPath`, scaling line width by pressure
5. Points are filtered by minimum distance to reduce trackpad noise

On non-Force Touch trackpads, a constant 0.5 pressure fallback ensures the app remains usable.

## Architecture

- **SwiftUI** for the main window, toolbar, sidebar, popovers, and menus
- **AppKit (`NSView`)** for the core drawing canvas — necessary for direct access to `NSEvent` pressure data, `NSBezierPath` rendering, and low-level trackpad touch handling
- **`NSViewRepresentable`** bridges the AppKit drawing view into the SwiftUI layout

## License

MIT License
