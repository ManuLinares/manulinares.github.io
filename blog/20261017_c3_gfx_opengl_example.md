---
title: "Opengl example using the C3 standard library gfx module"
date: 2026-10-21
authors:
  - Manuel Linares
slug: c3-gfx-opengl-example
---

```c3
/*
	needs opengl bindings: `c3c vendor-fetch opengl`
*/
module app;
import std, opengl;

fn int main()
{
	// Initialize the platform windowing subsystem
	if (catch err = gfx::init("OpenGLApp", { .init_opengl }))
	{
		return 1; // opengl failed to initialize, maybe fallback to software rendering or something
	}
	defer gfx::finalize();

	// Create a window with an OpenGL context, centered on screen
	GfxWindow* win = gfx::create_window("Static UI", 0, 0, 800, 600, { .open_gl, .center })!!;
	defer win.destroy();
	win.set_exit_key(ESCAPE);

	// Make the OpenGL context current on the calling thread
	gfx::set_current_opengl_window(win);

	// Load OpenGL function pointers via the gfx proc address resolver
	opengl::init((GLLoadFn)&gfx::get_opengl_proc)!!;

	// Set clear color once
	gl::clearColor(red: 0.2f, green: 0.3f, blue: 0.3f, alpha: 1.0f);

	// Initial render
	GfxPoint px = win.get_size_in_pixels();
	gl::viewport(0, 0, px.x, px.y);
	gl::clear(gl::GL_COLOR_BUFFER_BIT);
	win.swap_opengl_buffers();

	// Mode A: Event-driven loop (Static UI / apps: sleeps until input arrives)
	while (!win.should_close())
	{
		// 1. Block thread until at least one event arrives
		if (try event = gfx::wait(gfx::WAIT_FOREVER))
		{
			handle_event(win, event);

			// 2. Drain all remaining queued events without blocking
			while (try queued = gfx::peep(win))
			{
				handle_event(win, queued);
			}
		}

		// 3. Redraw once for the entire batch of events
		gl::clear(gl::GL_COLOR_BUFFER_BIT);
		win.swap_opengl_buffers();
	}

	// Mode B: Continuous loop (Games / animations: non-blocking poll with V-Sync pacing)
	/*
	win.set_opengl_swap_interval(1); // Enable V-Sync to cap frame rate

	while (!win.should_close())
	{
		// 1. Poll and drain all pending events without blocking
		while (try event = gfx::poll(win))
		{
			handle_event(win, event);
		}

		// 2. Update and render continuously
		gl::clear(gl::GL_COLOR_BUFFER_BIT);
		win.swap_opengl_buffers(); // Blocks until next display refresh
	}
	*/
	return 0;
}

// Dispatch input and window state events
fn void handle_event(GfxWindow* win, GfxEvent event)
{
	switch (event.type)
	{
		case WINDOW_RESIZED:
		case SCALE_UPDATED:
			GfxPoint cur_px = win.get_size_in_pixels();
			gl::viewport(0, 0, cur_px.x, cur_px.y);

		default:
			break;
	}

	// Debug printout (comment out this block to disable):
	switch (event.type)
	{
		case KEY_PRESSED:
			io::printfn("Key pressed: %c (%d)", (char)event.key.value, event.key.value);
		case KEY_RELEASED:
			io::printfn("Key released: %c (%d)", (char)event.key.value, event.key.value);
		case MOUSE_BUTTON_PRESSED:
			io::printfn("Mouse down: %s", event.button.value);
		case MOUSE_BUTTON_RELEASED:
			io::printfn("Mouse up: %s", event.button.value);
		case MOUSE_MOTION:
			io::printfn("Mouse pos: %s", event.mouse.pos);
		case MOUSE_SCROLL:
			io::printfn("Mouse scroll: %s", event.delta.vector);
		default:
			break;
	}
}
```
