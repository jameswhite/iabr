Convert comic books (.cbr), zipped comics (.cbz), or portable document formatted (.pdf) files into a format useable by the Internet archive book reader.


  - Modifications to bookreader:
    - [`config/etc/index.html`](/config/etc/bookreader/index.html) has been replaced with a simplified BookReaderDemo that calls `laboratory.js`.
    - [`config/etc/laboratory.js`](/config/etc/bookreader/laboratory.js) has had the inline book index removed and instead imports `laboratory.json` to describe the book.
    - I also replaced the loading spinner with a 1x1 pixel gif, because sometimes it'd just never stop "loading", which I found annoying.

  - Scripts in [`config/usr/local/bin/`](/config/usr/local/bin)

  - [`config/usr/local/bin/book`](/config/usr/local/bin/book)
    - will download, unpack, and index a file from a uri
    - `Usage: ./book --uri https://raw.githubusercontent.com/jameswhite/iabr/main/doc/Life_Cycle_of_a_Silver_Bullet.pdf`

  - [`config/usr/local/indexer`](/config/usr/local/bin/indexer)
    - will create the index `laboratory.json` consumed by the javascript
    - `Usage: ./indexer --file <filename>.pdf`

  - [`config/usr/local/unpacker`](/config/usr/local/bin/unpacker)
    - will unpack the files into images the bookreader can display in the root directory of the bookreader repository
    - `Usage: ./unpacker --file <filename>.pdf`


  - The [`rebuild`](/rebuild) script
    - creates a docker container, downloads the bookreader repository, and calls scripts to download, unpack, and index, the book (the docker container is unnecessary if you're just looking to host stuff where you've already installed [`bookreader`](https://github.com/internetarchive/bookreader), you'll just want the stuff in [`bin/`](/bin))
    - ` Usage: ./rebuild --uri https://raw.githubusercontent.com/jameswhite/iabr/main/doc/Life_Cycle_of_a_Silver_Bullet.pdf`
    - This will start a [`docker container listening on port 8000`](https://127.0.0.1:8000)
