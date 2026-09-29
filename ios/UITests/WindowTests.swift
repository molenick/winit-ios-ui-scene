import XCTest

final class WindowTests: XCTestCase {
    func testWindowIsShown() {
        assertWindowIsShown(arguments: [])
    }

    func testFullscreenWindowIsShown() {
        assertWindowIsShown(arguments: ["--fullscreen"])
    }

    private func assertWindowIsShown(arguments: [String]) {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        if app.descendants(matching: .any)["winit-window"].waitForExistence(timeout: 10) {
            return
        }
        XCTFail(app.state == .runningForeground ? "window not shown" : "crashed")
        print(app.debugDescription)
    }
}
