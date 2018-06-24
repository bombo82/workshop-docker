function init() {
    loadConfiguration(conf => document.body.innerHTML = `<h1>${conf.text}</h1>`)
}

function loadConfiguration(callback) {
    const xmlHttpRequest = new XMLHttpRequest();
    xmlHttpRequest.overrideMimeType("application/json")
    xmlHttpRequest.open('GET', 'conf.json', true)
    xmlHttpRequest.onreadystatechange = () => {
        if (xmlHttpRequest.readyState === 4 && xmlHttpRequest.status === 200) {
            console.log('Sucessfully load the configuration!')
            callback(JSON.parse(xmlHttpRequest.responseText));
        } else {
            console.log('Error loading configuration!')
            callback({"text": "Hello World!"})
        }
    };
    xmlHttpRequest.send(null);
}
