# the location to save fetched image
save_art_location = "$HOME/.config/awesome/artwork.png"

# the shell command to run when done fetching
shell_command = f'''awesome-client "awesome.emit_signal('music::set_cover', '{save_art_location}')"'''

# fallback art
fallback = "$HOME/.config/awesome/fallback.png"