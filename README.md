### Quickstart

  - Install Docker
  - Download a debian bookwork rootfs.tar.xz from your favorite Docker image source:
  - Here's mine:
```
[ ! -f rootfs.tar.xz ] && curl "https://raw.githubusercontent.com/jameswhite/rootfs/main/$(curl https://raw.githubusercontent.com/jameswhite/rootfs/main/rootfs.tar.xz)" > rootfs.tar.xz
```
  - build and run the docker image:
```
docker build -t iabr .
docker run -i -p8000:8000 -v $(pwd)/books:/var/www/html/books -t iabr /bin/bash -c "/usr/sbin/service nginx start && /bin/bash"
```
  - put your books ( .cbr, .cbz, .pdf) in ./books/ (it will be mapped into the container)
  - browse to http://127.0.0.1:8000/books

### Notes on security and implementation
  - Creating the indexes is slow and can take tens of seconds to first load a book, loading individual pages is much faster after that.
  - This code is not DRY, and is not path safe, so don't host it anywhere outside of a Docker container unless you want it to leak files
  - This code code is meant to be a proof-of-concept, and perl was just the fastest way for me to prove said concept.
  - There's a lot more wrong with this code than right.
  - The old version is [here](https://github.com/jameswhite/iabr/tree/9aa19ddcf9c75f47a00f782ebb29d1017aeb43b8)
