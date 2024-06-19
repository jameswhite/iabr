const url = 'index.json';

// Create the BookReader object
function instantiateBookReader(selector, extraOptions) {
  selector = selector || '#BookReader';
  extraOptions = extraOptions || {};

  // Fetch the JSON file and parse it into a JavaScript object
  var options = {};
  fetch(url, { method: 'GET' })
    .then(function(response) { return response.json(); })
    .then( function(json) {
       options = json;
       console.log(options);
       $.extend(options, extraOptions);
       var br = new BookReader(options);
       br.init(); });
}
