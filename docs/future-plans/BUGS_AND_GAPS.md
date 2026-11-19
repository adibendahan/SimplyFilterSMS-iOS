# Bugs and Gaps

Found along the way; each is fixed in its own change.

## Screenshots

- **iPad shots sometimes hang on an animation nobody can see.** About one run in ten, Subscribe from URL (shot 09) or Test Your Filters in Arabic (shot 07) stops reporting idle after text is typed: the screen is still, the app says an animation is running, and every later step waits 60 seconds until the shot times out. The retry on restarted simulators passes. The recordings show nothing moving but the cursor. Suspects: the URL field's loading spinner, removed with its row when the preview loads, or the iPad keyboard (both screens have typing; only one has a spinner). Next step: run the shot until it hangs and sample the app from the Mac during the hang.

## App Store

- **Make the screenshots look nice in the App Store.** Today they're plain captures; design store-ready images around them.

## Help

- **Update the FAQ.** Add questions and answers for the newer features (Siri & Shortcuts, Community Lists, Stay Reachable, and anything else missing). Move the whole question list off the Help screen into its own screen, opened from a single FAQ row, since Help is already full.

## What's New

- **Redesign the What's New screen.**
