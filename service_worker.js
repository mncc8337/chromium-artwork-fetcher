var port = chrome.runtime.connectNative('org.mncc.artwork_fetcher');
port.onDisconnect.addListener(function () {
    console.log('Disconnected');
});

function sendMessage(message) {
    port.postMessage(message);
    console.log("sent message: ", message);
};

sendMessage({message: "welcome to the web :)"});

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
    // get all tabs that are playing audio
    chrome.tabs.query({audible: true}, tabs => {
        var found = false;
        // get the first tab that can get artwork
        for(var i = 0; i < tabs.length; i++) {
            let url = new URL(tabs[i].url);

            if(supportedURL(url)) {
                chrome.tabs.sendMessage(tabs[i].id, "ARTWORK");
                found = true;
                break;
            }
        }
        if(!found) {
            // try fetching current opened tab
            chrome.tabs.query({active: true, lastFocusedWindow: true}, tabs => {
                let url = new URL(tabs[0].url);
                if(supportedURL(url))
                    chrome.tabs.sendMessage(tabs[0].id, "ARTWORK");
            });
        }
    });
}

// process requests
port.onMessage.addListener(function(msg) {
    switch(msg.type) {
        case "REQUEST":
            switch(msg.content) {
                case "ARTWORK":
                    console.log("app requested artwork");
                    fetchArtWork();
                    break;
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

// when click on the extension icon
chrome.action.onClicked.addListener(tab => {
    fetchArtWork();
});

chrome.runtime.onMessage.addListener(function(message, callback) {
    switch(message["message"]) {
        case "ARTWORK":
            sendMessage({message: "artworkURL", url: message["url"]});
            console.log(`received a artwork url from a ${message["from"]} tab`);
            break;
    }
});    