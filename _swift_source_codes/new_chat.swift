import Cocoa
import Foundation

struct promptInformation: Codable {
    var name: String
    var content: String
    var context: String
    var temperature: String
    var presence: String
    var frequency: String
}

struct promptExist: Codable {
    var name: String
    var content: String
    var context: String
    var temperature: String
    var presence: String
    var frequency: String
}

struct newChat: Codable {
    var role: String
    var content: String
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var titleField: NSTextField!
    var textView: NSTextView!
    var scrollView: NSScrollView!
    var eventTap: CFMachPort?
    var submitButton: NSButton!
    var inputName: NSTextField!
    var inputContext: NSPopUpButton!
    var inputTemperature: NSPopUpButton!
    var inputPresence: NSPopUpButton!
    var inputFrequency: NSPopUpButton!

    func createTitleField(withPrompt prompt: String) -> NSTextField {
            let titleField = NSTextField()
            titleField.stringValue = prompt
            titleField.isEditable = false
            titleField.isBordered = false
            titleField.backgroundColor = .clear
            titleField.font = .boldSystemFont(ofSize: 14)
            return titleField
        }
        
    func createInputField(placeholder: String) -> NSTextField {
            let inputField = NSTextField()
            inputField.placeholderString = placeholder
            inputField.isEditable = true
            inputField.isBordered = true
            inputField.font = .systemFont(ofSize: 12)
            inputField.alignment = .left
            return inputField
        }
        
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard CommandLine.arguments.count == 11,
        let x = Double(CommandLine.arguments[1]),
        let y = Double(CommandLine.arguments[2]),
        let width = Double(CommandLine.arguments[3]),
        let height = Double(CommandLine.arguments[4])
        else {
                fatalError("Invalid input arguments.")
        }
        let input_name = CommandLine.arguments[safe: 5].flatMap { $0 == "nil" ? "" : $0 }
        let input_prompt = CommandLine.arguments[safe: 6].flatMap { $0 == "nil" ? "" : $0 }
        let select_context = CommandLine.arguments[safe: 7].flatMap { $0 == "nil" ? "0" : $0 }
        let select_temperature = CommandLine.arguments[safe: 8].flatMap { $0 == "nil" ? "0.5" : $0 }
        let select_presence = CommandLine.arguments[safe: 9].flatMap { $0 == "nil" ? "0.0" : $0 }
        let select_frequency = CommandLine.arguments[safe: 10].flatMap { $0 == "nil" ? "0.0" : $0 }
        let frame = CGRect(x: x, y: y, width: width, height: height)
        window = NSWindow(contentRect: frame,
                    styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                    backing: .buffered,
                    defer: false)
        let fixedContentSize = NSSize(width: width, height: height)
        window.contentMinSize = fixedContentSize
        window.contentMaxSize = fixedContentSize
        
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .sidebar
        window.contentView = visualEffect
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.titlebarAppearsTransparent = true
        window.level = .floating

        let nameTitle = createTitleField(withPrompt: "Chat name:")
        inputName = createInputField(placeholder: "Input your chat name...")
        if let inputname = input_name{
            inputName.stringValue = inputname
        }
        else {
            inputName.stringValue = ""
        }
        let namestackView = NSStackView(views: [nameTitle, inputName])
        namestackView.orientation = .vertical
        namestackView.spacing = 4
        namestackView.alignment = .leading
        NSLayoutConstraint.activate([
            inputName.leadingAnchor.constraint(equalTo: namestackView.leadingAnchor, constant: 0),
            inputName.trailingAnchor.constraint(equalTo: namestackView.trailingAnchor, constant: 0)
        ])
        
        let promptTitle = createTitleField(withPrompt: "Prompt:")
        textView = NSTextView()
        if let inputprompt = input_prompt{
            textView.string = inputprompt
        }
        else {
            textView.string = ""
        }
        textView.isEditable = true
        textView.isSelectable = true
        textView.autoresizingMask = [.width, .height]
        textView.font = .systemFont(ofSize: 12)
        textView.textContainerInset = NSSize(width: 0, height: 5)
        scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.contentView.drawsBackground = false
        scrollView.borderType = .lineBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        let promptstackView = NSStackView(views: [promptTitle, scrollView])
        promptstackView.orientation = .vertical
        promptstackView.spacing = 4
        promptstackView.alignment = .leading
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: promptstackView.leadingAnchor, constant: 0),
            scrollView.trailingAnchor.constraint(equalTo: promptstackView.trailingAnchor, constant: 0)
        ])
        
        let contextTitle = createTitleField(withPrompt: "Context length:")
        inputContext = NSPopUpButton()
        for value in 0...20 {
            let title = String(format: "%d", value)
            inputContext.addItem(withTitle: title)
        }
        if let selectcontext = select_context{
            inputContext.selectItem(withTitle: selectcontext)
        }
        else {
            inputContext.selectItem(withTitle: "0")
        }
        let contextStackView = NSStackView(views: [contextTitle, inputContext])
            contextStackView.orientation = .horizontal
            contextStackView.spacing = 8
        
        
        let temperatureTitle = createTitleField(withPrompt: "Temperature:")
        inputTemperature = NSPopUpButton()
        for value in 0...10 {
            let title = String(format: "%.1f", Float(value) / 10.0)
            inputTemperature.addItem(withTitle: title)
        }
        if let selecttemperature = select_temperature{
            inputTemperature.selectItem(withTitle: selecttemperature)
        }
        else {
            inputTemperature.selectItem(withTitle: "0.5")
        }
        let temperatureStackView = NSStackView(views: [temperatureTitle, inputTemperature])
            temperatureStackView.orientation = .horizontal
            temperatureStackView.spacing = 8
        

        let presenceTitle = createTitleField(withPrompt: "Presence penalty:")
        inputPresence = NSPopUpButton()
        for value in 0...10 {
            let title = String(format: "%.1f", Float(value) / 10.0)
            inputPresence.addItem(withTitle: title)
        }
        if let selectpresence = select_presence{
            inputPresence.selectItem(withTitle: selectpresence)
        }
        else {
            inputPresence.selectItem(withTitle: "0.0")
        }
        let presenceStackView = NSStackView(views: [presenceTitle, inputPresence])
            presenceStackView.orientation = .horizontal
            presenceStackView.spacing = 8
            
        let frequencyTitle = createTitleField(withPrompt: "Frequency penalty:")
        inputFrequency = NSPopUpButton()
        for value in 0...10 {
            let title = String(format: "%.1f", Float(value) / 10.0)
            inputFrequency.addItem(withTitle: title)
        }
        if let selectfrequency = select_frequency{
            inputFrequency.selectItem(withTitle: selectfrequency)
        }
        else {
            inputFrequency.selectItem(withTitle: "0.0")
        }
        let frequencyStackView = NSStackView(views: [frequencyTitle, inputFrequency])
            frequencyStackView.orientation = .horizontal
            frequencyStackView.spacing = 8
            
        let popStackView_1 = NSStackView(views: [contextStackView, presenceStackView])
            popStackView_1.orientation = .horizontal
            popStackView_1.spacing = 50
            
        let popStackView_2 = NSStackView(views: [temperatureStackView, frequencyStackView])
            popStackView_2.orientation = .horizontal
            popStackView_2.spacing = 50

        
        submitButton = NSButton(title: "OK", target: self, action: #selector(submitButtonPressed))
        
        let stackView = NSStackView(views: [namestackView, promptstackView, popStackView_1, popStackView_2, submitButton])
        stackView.orientation = .vertical
        stackView.spacing = 12
        stackView.alignment = .leading
        
        window.contentView?.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            namestackView.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 20),
            namestackView.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 20),
            namestackView.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
            promptstackView.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 20),
            promptstackView.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
            popStackView_1.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 20),
            popStackView_1.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
            popStackView_2.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 20),
            popStackView_2.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
            submitButton.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 400),
            submitButton.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -20),
            submitButton.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor, constant: -10)
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
                }
                return nil
            }
            return event
        }
        
        window.makeKeyAndOrderFront(nil)
        enableEventTap()
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

func showAlert(message: String, informativeText: String, alertStyle: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
    
        if let mainWindow = NSApplication.shared.mainWindow {
            alert.beginSheetModal(for: mainWindow, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }
        
func savePromptToFile(_ prompt_Information: promptInformation) {
    do {
        var existingArray: [promptInformation] = []
        if let scriptPath = CommandLine.arguments.first {
            let scriptURL = URL(fileURLWithPath: scriptPath)
            let scriptDirectory = scriptURL.deletingLastPathComponent()
            let fileURL = scriptDirectory.appendingPathComponent("prompts.json")
            if let data = try? Data(contentsOf: fileURL),
            let decodedArray = try? JSONDecoder().decode([promptInformation].self, from: data) {
                existingArray = decodedArray
            }
        }
        
        existingArray.append(prompt_Information)
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        if let jsonData = try? jsonEncoder.encode(existingArray) {
            if let scriptPath = CommandLine.arguments.first {
                let scriptURL = URL(fileURLWithPath: scriptPath)
                let scriptDirectory = scriptURL.deletingLastPathComponent()
                let fileURL = scriptDirectory.appendingPathComponent("prompts.json")
                do {
                    try jsonData.write(to: fileURL)
                } catch {
                    print("Error writing JSON data to file: \(error)")
                }
            }
        }
    }
}
        
    @objc func submitButtonPressed() {
        let name = inputName.stringValue
        let content = textView.string
        let selectedContextItem = inputContext.selectedItem
        let context = selectedContextItem?.title ?? ""
        let selectedTemperatureItem = inputTemperature.selectedItem
        let temperature = selectedTemperatureItem?.title ?? ""
        let selectedPresenceItem = inputPresence.selectedItem
        let presence = selectedPresenceItem?.title ?? ""
        let selectedFrequencyItem = inputFrequency.selectedItem
        let frequency = selectedFrequencyItem?.title ?? ""
        
        let valuesToCheck = [name, content, context, temperature, presence, frequency]
        for value in valuesToCheck {
            if value.isEmpty {
                showAlert(message: "You haven't fill all\n你还没有全部输入完成", informativeText: "Please complete your chat information.\n请完成你的对话信息输入。", alertStyle: .informational)
                return
            }
        }
        
        let promptsFilePath = "prompts.json"
        let newpromptInformation = promptInformation(name: name, content: content, context:context, temperature: temperature, presence:presence, frequency:frequency)
        let jsonEncoder = JSONEncoder()
        let jsonDecoder = JSONDecoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let promptsData = try Data(contentsOf: URL(fileURLWithPath: promptsFilePath))
            let prompts = try jsonDecoder.decode([promptExist].self, from: promptsData)
            for prompt in prompts {
                let promptName = prompt.name
                if name == promptName{
                    showAlert(message: "Chat exist\n对话已存在", informativeText: "Please input new chat name.\n请输入新的对话名称。", alertStyle: .informational)
                    return
                }
            }
            let jsonData = try jsonEncoder.encode(newpromptInformation)
            var newChatFile: [newChat] = []
            let newChatPrompt = newChat(role: "system", content: content)
            newChatFile.append(newChatPrompt)
            let chatData = try jsonEncoder.encode(newChatFile)
            if let scriptPath = CommandLine.arguments.first {
                    let scriptURL = URL(fileURLWithPath: scriptPath)
                    let scriptDirectory = scriptURL.deletingLastPathComponent()
                    let fileURL = scriptDirectory.appendingPathComponent("selected_chat.json")
                    let chatFileURL = scriptDirectory.appendingPathComponent("prompt_history/" + name + ".json")
                    do {
                        try jsonData.write(to: fileURL)
                        try chatData.write(to: chatFileURL)
                        savePromptToFile(newpromptInformation)
                        } catch {
                            print("Error writing JSON data to file: \(error)")
                        }
            }
        } catch {
            print("Error encoding JSON: \(error)")
        }
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField {
            let userInput = textField.stringValue
            print("User input: \(userInput)")
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

let appDelegate = AppDelegate()
let app = NSApplication.shared
app.setActivationPolicy(.accessory)
NSApplication.shared.activate(ignoringOtherApps: true)
app.delegate = appDelegate
app.run()