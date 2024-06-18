Convert comic books (.cbr), zipped comics (.cbz), or portable document formatted (.pdf) files into a format useable by the Internet archive book reader.


  - Modifications to bookreader:
    - index.html has been replaced with a simplified BookReaderDemo that calls `laboratory.js`.
    - laboratory.js has had the inline book index removed and instead imports `laboratory.json` to describe the book.


  - Scripts in [`bin/`](/jameswhite/iabr/tree/main/bin)

  - book
    - will download, unpack, and index a file from a uri

  - indexer
    - will create the index `laboratory.json` consumed by the javascript

  - unpacker
    - will unpack the files into images the bookreader can display in the root directory of the bookreader repository


  - The `rebuild` script
    - creates a docker container, downloads the bookreader repository, and calls scripts to download, unpack, and index, the book
```
Usage: ./rebuild --uri `https://raw.githubusercontent.com/jameswhite/iabr/main/doc/Life_Cycle_of_a_Silver_Bullet.pdf`
```
