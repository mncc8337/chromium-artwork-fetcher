var port = chrome.runtime.connectNative('org.mncc.artwork_fetcher');
port.onDisconnect.addListener(function () {
    console.log('Disconnected');
});

function sendMessage(message) {
    port.postMessage(message);
    console.log("sent message: ", message);
};

function supportedURL(url) {
    switch(url.origin) {
        case "https://www.youtube.com":
            if(url.pathname == "/watch")
                return true;
            else
                return false;
        default:
            return false;
    }
}
function fetchArtWork() {
    var found = false;
    // get all tabs that are playing audio
    chrome.tabs.query({audible: true}, tabs => {
        // get the first tab that can get artwork
        for(var i = 0; i < tabs.length; i++) {
            let url = new URL(tabs[i].url);

            if(supportedURL(url)) {
                chrome.tabs.sendMessage(tabs[i].id, "ARTWORK");
                found = true;
                return;
            }
        }
    });
    if(!found) {
        // try fetching current opened tab
        chrome.tabs.query({active: true, lastFocusedWindow: true}, tabs => {
            // idk why it occur
            // so just ignore it
            if(tabs[0] == null) return;
    
            let url = new URL(tabs[0].url);
            if(supportedURL(url)) {
                chrome.tabs.sendMessage(tabs[0].id, "ARTWORK");
                found = true;
                return;
            }
        });
    }
    if(!found)
        sendMessage({message: "artworkURL", url: "NO_ARTWORK"});
}

// process app message
port.onMessage.addListener(function(msg) {
    switch(msg.type) {
        case "REQUEST":
            if(msg.content == "ARTWORK") {
                console.log("app requested artwork");
                fetchArtWork();
            }
            break;
        case "MESSAGE":
            console.log("received message: " + msg.content);
            break;
        case "ERROR":
            switch(msg.content) {
                case "ART_DIR_INVALID":
                    throw "art directory is invalid or not existed: " + msg.dir;
                case "RECEIVING_MESSAGE":
                    throw "app receiving message error: " + msg.error;
                default:
                    throw "app error: " + msg.content;
            }
    }
});

// process content script message
chrome.runtime.onMessage.addListener(function(message, callback) {
    switch(message["message"]) {
        case "ARTWORK":
            sendMessage({message: "artworkURL", url: message["url"]});
            console.log(`received a artwork url from a ${message["from"]} tab`);
            break;
        }
    });
    
// when click on the extension icon
chrome.action.onClicked.addListener(function() {
    fetchArtWork();
});

// make service worker active on startup
chrome.runtime.onStartup.addListener(function() {
    console.log("onstartup");
});

sendMessage({message: "welcome to the web :)"});