//! A winit app whose window the UI tests look for by its accessibility identifier.

use std::num::NonZeroU32;

use objc2::msg_send;
use objc2::runtime::AnyObject;
use objc2_foundation::NSString;
use raw_window_handle::{HasWindowHandle, RawWindowHandle};
use softbuffer::{Context, Surface};
use winit::application::ApplicationHandler;
use winit::event::WindowEvent;
use winit::event_loop::{ActiveEventLoop, EventLoop, OwnedDisplayHandle};
use winit::monitor::Fullscreen;
use winit::window::{Window, WindowAttributes, WindowId};

const FILL: u32 = 0x0020_80d0;

#[derive(Default)]
struct App {
    surface: Option<Surface<OwnedDisplayHandle, Box<dyn Window>>>,
}

impl ApplicationHandler for App {
    fn can_create_surfaces(&mut self, event_loop: &dyn ActiveEventLoop) {
        let mut attributes = WindowAttributes::default();
        // Set by the UI tests to ask for fullscreen on a named monitor.
        if std::env::args().any(|arg| arg == "--fullscreen") {
            let monitor = event_loop.primary_monitor();
            attributes = attributes.with_fullscreen(Some(Fullscreen::Borderless(monitor)));
        }
        let window = event_loop.create_window(attributes).unwrap();
        identify(&*window);
        let context = Context::new(event_loop.owned_display_handle()).unwrap();
        self.surface = Some(Surface::new(&context, window).unwrap());
    }

    fn window_event(&mut self, _: &dyn ActiveEventLoop, _: WindowId, event: WindowEvent) {
        let Some(surface) = self.surface.as_mut() else { return };
        match event {
            WindowEvent::SurfaceResized(size) => {
                eprintln!("resized {}x{}", size.width, size.height);
                if let (Some(width), Some(height)) =
                    (NonZeroU32::new(size.width), NonZeroU32::new(size.height))
                {
                    surface.resize(width, height).unwrap();
                }
                surface.window().request_redraw();
            },
            WindowEvent::RedrawRequested => {
                let mut buffer = surface.buffer_mut().unwrap();
                buffer.fill(FILL);
                buffer.present().unwrap();
            },
            _ => (),
        }
    }
}

/// Gives winit's view the accessibility identifier `ios/UITests/WindowTests.swift` looks for. The
/// view is only in the accessibility hierarchy while its window is on screen.
fn identify(window: &dyn Window) {
    let RawWindowHandle::UiKit(handle) = window.window_handle().unwrap().as_raw() else {
        unreachable!("winit's iOS windows are UIKit views");
    };
    let view: &AnyObject = unsafe { handle.ui_view.cast().as_ref() };
    let identifier = NSString::from_str("winit-window");
    unsafe {
        let _: () = msg_send![view, setIsAccessibilityElement: true];
        let _: () = msg_send![view, setAccessibilityIdentifier: &*identifier];
    }
}

/// Runs the app. Called from `main`; never returns.
#[unsafe(no_mangle)]
pub extern "C" fn winit_scene_integration_main() {
    EventLoop::new().unwrap().run_app(App::default()).unwrap();
}
