# chromium artwork fetcher
save artwork of current playing media on browser into a file  
curently the following sites are supported
- [youtube](https://www.youtube.com)

# install
- clone the project `git clone https://github.com/mncc8337/chromium-artwork-fetcher.git && cd chromium-artwork-fetcher`
- edit `save_art_location` and `shell_command` value in `./config.py`
- open browser and go to `chrome://extensions`
- enable `Developer mode` and `load unpacked` the root of this repo. copy the extension ID
- run `./install.py EXTENSION_ID` with `EXTENSION_ID` being the copied ID mentioned above
- ???

# TODO
- add mpris:artUrl property to browser's sent metadata
- add support to soundcloud, ...
