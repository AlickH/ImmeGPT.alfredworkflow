import Cocoa
import Quartz

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var scrollView: NSScrollView!
    var textView: NSTextView!
    var eventTap: CFMachPort?
    var previewPanel: QLPreviewPanel?
    var content: String = ""
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
      
        guard CommandLine.arguments.count == 14,
              let x = Double(CommandLine.arguments[1]),
              let y = Double(CommandLine.arguments[2]),
              let width = Double(CommandLine.arguments[3]),
              let height = Double(CommandLine.arguments[4]),
              let message = CommandLine.arguments[5] as? String,
              let api = CommandLine.arguments[6] as? String,
              let key = CommandLine.arguments[7] as? String,
              let model = CommandLine.arguments[8] as? String,
              let history = CommandLine.arguments[9] as? String,
              let temperature = CommandLine.arguments[10] as? String,
              let presence = CommandLine.arguments[11] as? String,
              let frequency = CommandLine.arguments[12] as? String,
              let stream_type = CommandLine.arguments[13] as? String else {
            fatalError("Invalid input arguments.")
        }
        let frame = CGRect(x: x, y: y, width: width, height: height)
      
        window = NSWindow(contentRect: frame,
                          styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                          backing: .buffered,
                          defer: false)
        
        // Configure the visual effect view with the appropriate blending mode
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .sidebar
        window.contentView = visualEffect
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = .floating
        
        // Create and configure the text view
        textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = true
        textView.backgroundColor = .clear
        textView.font = .systemFont(ofSize: 14)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.autoresizingMask = [.width, .height]
        let fontSize: CGFloat = 14
        let font = NSFont.systemFont(ofSize: fontSize)
        textView.font = font
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .natural
        textView.defaultParagraphStyle = paragraphStyle
        textView.textContainerInset = NSSize(width: 5, height: 0)
        
        // Create and configure the scroll view
        scrollView = NSScrollView()
        scrollView.contentView.drawsBackground = false
        scrollView.documentView = textView
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        // Set up constraints
        window.contentView?.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor, constant: -35)
        ])
        
        let copyButton = NSButton(title: "Copy", target: self, action: #selector(copyButtonClicked))
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.bezelStyle = .inline
        window.contentView?.addSubview(copyButton)
        
        // Add constraints for the Copy Button
        NSLayoutConstraint.activate([
            copyButton.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
            copyButton.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor, constant: -10)
        ])
      
      let quicklookButton = NSButton(title: "MD Style", target: self, action: #selector(quicklookButtonClicked))
      quicklookButton.translatesAutoresizingMaskIntoConstraints = false
      quicklookButton.bezelStyle = .inline
      window.contentView?.addSubview(quicklookButton)
      
      NSLayoutConstraint.activate([
        quicklookButton.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -10),
        quicklookButton.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor, constant: -10)
      ])
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
          if event.modifierFlags.contains(.command) {
            if event.charactersIgnoringModifiers == "c" {
              appDelegate.textView.copy(nil)
            } else if event.charactersIgnoringModifiers == "v" {
              appDelegate.textView.paste(nil)
            } else if event.charactersIgnoringModifiers == "x" {
              appDelegate.textView.cut(nil)
            } else if event.charactersIgnoringModifiers == "a" {
              appDelegate.textView.selectAll(nil)
            } else if event.charactersIgnoringModifiers == "y" {
              quicklookButton.performClick(nil)
            }
            return nil
          }
          return event
        }
      
        window.makeKeyAndOrderFront(nil)
        
        // 启用事件处理
        enableEventTap()
        
        // 创建一个Process实例来启动外部python脚本
        let task = Process()
        task.launchPath = "/opt/homebrew/bin/python3" // 替换此路径为你的python解释器路径
        task.arguments = ["gpt_stream.py", message, api, key, model, history, temperature, presence, frequency, stream_type] // 替换此处为你的python脚本路径
        
        // 创建一个Pipe实例来捕获外部python脚本的输出
        let pipe = Pipe()
        task.standardOutput = pipe
        
        // 启动任务
        task.launch()
        
        // 创建一个DispatchQueue用于异步处理新数据
        let queue = DispatchQueue(label: "outputQueue")
        
        // 设置处理程序来处理每次有新数据可用时的情况
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if let output = String(data: data, encoding: .utf8) {
                // 在主队列上异步处理数据，并打印到Swift创建的窗口内
                queue.async {
                    self.handleInput(output)
                }
            }
        }
        
        // 等待任务完成
        task.waitUntilExit()
    }
    
    // ... AppDelegate的其他代码 ...
    
    func handleInput(_ input: String) {
      DispatchQueue.main.async {
        if !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          if input == "\n"{
                  self.content += "\n"
                } else {
                  self.content += input
                      }
          self.textView.string = self.content
          self.textView.scrollToEndOfDocument(nil)
        }
      }
    }
    
    @objc func copyButtonClicked() {
        let pasteboard = NSPasteboard.general
      
        if textView.selectedRange.length > 0 {
          // Copy selected text
          let selectedText = textView.string as NSString
          pasteboard.clearContents()
          pasteboard.setString(selectedText.substring(with: textView.selectedRange), forType: .string)
        } else {
          // Copy entire text
          pasteboard.clearContents()
          pasteboard.setString(textView.string, forType: .string)
        }
      }
    
    @objc func quicklookButtonClicked() {
          if let panel = previewPanel, panel.isVisible {
            // Close the QLPreviewPanel if it's already open
            panel.close()
          } else {
            // Open the QLPreviewPanel
            previewPanel = QLPreviewPanel.shared()
            previewPanel?.makeKeyAndOrderFront(self)
            previewPanel?.dataSource = self
          }
        }
  
    func enableEventTap() {
        DispatchQueue.global(qos: .userInitiated).async {
            // 创建事件tap
            self.eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue), callback: {proxy, type, event, refcon in
              
                // 检测Esc键，按ESC退出窗口停止运行 
                if event.getIntegerValueField(.keyboardEventKeycode) == 53 {
                    DispatchQueue.main.async {
                        NSApplication.shared.terminate(nil)
                    }
                  return nil
                }
              
                return Unmanaged.passRetained(event)
            }, userInfo: nil)
          
            if let tap = self.eventTap {
                // 启用事件回调
                let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
                CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                CGEvent.tapEnable(tap: tap, enable: true)
                CFRunLoopRun()
            } else {
                print("Failed to create event tap")
            }
        }
    }
  
  func applicationWillTerminate(_ aNotification: Notification) {
        // 禁用事件回调
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
    }
}

extension AppDelegate: QLPreviewPanelDataSource {
  func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
    return 1
  }
  
  func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
    if let currentDirectory = FileManager.default.currentDirectoryPath as NSString? {
      let filePath = currentDirectory.appendingPathComponent("/tmp/result.md")
      let fileURL = URL(fileURLWithPath: filePath)
      return fileURL as QLPreviewItem
    }
    return nil
  }
}

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("Error: Missing text argument")
    exit(0)
}

let appDelegate = AppDelegate()
NSApplication.shared.setActivationPolicy(.accessory)
NSApplication.shared.delegate = appDelegate
NSApplication.shared.run()
  