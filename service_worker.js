var port = chrome.runtime.connectNative('org.mncc.mpris2');
port.onDisconnect.addListener(function () {
    console.log('Disconnected');
});

function sendMessage(message) {
    port.postMessage(message);
    console.log("sent message `" + message.message + '`');
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
    chrome.tabs.query({active: true, lastFocusedWindow: true}, tabs => {
        let url = new URL(tabs[0].url);
        console.log(url);
        let artwork = "";

        if(YoutubeURL(url))
            artwork = YoutubeArtworkURL(url);
        else
            artwork = "NO_ARTWORK";

        sendMessage({message: "artworkURL", url: artwork})
    });
}

// process requests
port.onMessage.addListener(function (msg) {
    console.log('received message `' + msg + '`');
    switch(msg) {
        case "REQUEST_ARTWORK":
            fetchArtWork();
            break;
    }
});

// when click on the extension icon
chrome.action.onClicked.addListener(tab => {
    fetchArtWork();
});