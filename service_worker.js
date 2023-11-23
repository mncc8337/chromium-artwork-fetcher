var port = chrome.runtime.connectNative('org.mncc.artwork_fetcher');
port.onDisconnect.addListener(function () {
    console.log('Disconnected');
});

function sendMessage(message) {
    port.postMessage(message);
    console.log("sent message: " + message.message);
};

sendMessage({message: "welcome to the web :)"});

function YoutubeArtworkURL(url) {
    const id = url.searchParams.get("v");
    if(id == null) return "NO_ARTWORK";
    return `https://i.ytimg.com/vi/${id}/hqdefault.jpg`;
}
function YoutubeURL(url) {
    switch(url.origin) {
        case "https://www.youtube.com":
            return true;
        default:
            return false;
    }
}
function fetchArtWork() {
    // get all tabs that are active and are playing audio
    chrome.tabs.query({active: true, audible: true}, tabs => {
        // get the first tab that can get artwork
        for(var i = 0; i < tabs.length; i++) {
            let url = new URL(tabs[i].url);

            let artwork = "";
            if(YoutubeURL(url))
                artwork = YoutubeArtworkURL(url);
            else
                artwork = "NO_ARTWORK";

            sendMessage({message: "artworkURL", url: artwork})

            if(artwork != "NO_ARTWORK") {
                console.log(url);
                break;
            }
        }
    });
}

// process requests
port.onMessage.addListener(function(msg) {
    switch(msg.type) {
        case "REQUEST":
            switch(msg.content) {
                case "ARTWORK":
                    console.log("requested artwork");
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