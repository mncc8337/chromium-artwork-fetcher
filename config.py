# the location to save the downloaded art
save_art_location = "~/.config/awesome/artwork.png"
# the shell command to run when done fetching (optional, leave blank to ignore)
shell_command = 'awesome-client "awesome.emit_signal(\\"music::set_cover\\", awesome_dir..\\"artwork.png\\")"'

# replace '~' with $HOME
if '~' in save_art_location:
    import os
    save_art_location = save_art_location.replace('~', os.environ.get("HOME"))