Convert comic books (.cbr), zipped comics (.cbz), or portable document formatted (.pdf) files into a format useable by the Internet archive book reader.


  - Modifications to bookreader:
    - [`index.html`](/bookreader/index.html) has been replaced with a simplified BookReaderDemo that calls `laboratory.js`.
    - [`laboratory.js`](/bookreader/laboratory.js) has had the inline book index removed and instead imports `laboratory.json` to describe the book.
    - I also replaced the loading spinner with a 1x1 pixel gif, because sometimes it'd just never stop "loading", which I found annoying.

  - Scripts in [`bin/`](/bin)

  - [`book`](/bin/book)
    - will download, unpack, and index a file from a uri
    - `Usage: ./book --uri https://raw.githubusercontent.com/jameswhite/iabr/main/doc/Life_Cycle_of_a_Silver_Bullet.pdf`

  - [`indexer`](/bin/indexer)
    - will create the index `laboratory.json` consumed by the javascript
    - `Usage: ./indexer --file <filename>.pdf`

  - [`unpacker`](/bin/unpacker)
    - will unpack the files into images the bookreader can display in the root directory of the bookreader repository
    - `Usage: ./unpacker --file <filename>.pdf`


  - The [`rebuild`](/rebuild) script
    - creates a docker container, downloads the bookreader repository, and calls scripts to download, unpack, and index, the book
    - ` Usage: ./rebuild --uri https://raw.githubusercontent.com/jameswhite/iabr/main/doc/Life_Cycle_of_a_Silver_Bullet.pdf`
    - This will start a [docker container listening on port 8000](https://127.0.0.1:8000)
