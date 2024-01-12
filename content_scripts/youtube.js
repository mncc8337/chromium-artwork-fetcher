function getArt() {
    const id = (new URL(location.href)).searchParams.get("v");
    if(id == null) return "NO_ARTWORK";
    return `https://i.ytimg.com/vi/${id}/hqdefault.jpg`;
}

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    switch(request) {
        case "ARTWORK":
            var url = getArt();
            if(url != "NO_ARTWORK")
                chrome.runtime.sendMessage({"message": "ARTWORK", "from": "youtube", "url": url});
            break;
        // default:
        //     alert("wth?");
    }
})