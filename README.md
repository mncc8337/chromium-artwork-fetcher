# Archived repo
I started this project because chromium browser haven't support mpdris's artUrl. But now chromium browsers have suppport it so it is non-sense for me to continue on this.

# chromium artwork fetcher
save artwork of current playing media on browser into a file  
curently the following sites are supported
- [youtube](https://www.youtube.com)

# install
- install dependency `curl`
- clone the project `git clone https://github.com/mncc8337/chromium-artwork-fetcher.git && cd chromium-artwork-fetcher`
- edit values in `./native/config.py`
- open browser and go to `chrome://extensions`
- enable `Developer mode` and `load unpacked` `./extension`. copy the extension ID
- run `./install.py EXTENSION_ID` with `EXTENSION_ID` being the copied ID mentioned above
- reload the extension and then the browser
- ???

# TODO
- add support to other site:
  - [ ] soundcloud
  - [ ] bandcamp
  - ...
