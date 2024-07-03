FROM scratch
ADD rootfs.tar.xz /
ADD config/etc/apt/sources.list /etc/apt/sources.list
ADD config/etc/policy.xml /etc/ImageMagick-6-policy.xml
COPY config/usr/local/bin /usr/local/bin
COPY config/var/cache/git/bookreader /etc/bookreader
RUN [ -f /etc/apt/sources.list.d/debian.sources ] && rm /etc/apt/sources.list.d/debian.sources || true \
 && apt-get update                                                               \
 && apt-get install -y apt-file file imagemagick jq ghostscript git less net-tools nodejs node-jquery node-jquery-ui npm perlmagick poppler-utils procps unzip vim wget nginx perl libarchive-extract-perl libcam-pdf-perl libnginx-mod-http-perl liburi-encode-perl liburi-escape-xs-perl \
 && apt-file update                                                              \
 && apt-get -y build-dep unrar-nonfree                                           \
 && (cd /var/tmp; apt-get source -b unrar-nonfree)                               \
 && (cd /var/tmp; dpkg -i unrar*.deb)                                            \
 && mkdir -p /var/cache/git                                                      \
 && mkdir -p /var/www/html/books                                                 \
 && mkdir -p /usr/share/nginx/perl/lib                                           \
 && (cd /var/cache/git; git clone https://github.com/internetarchive/bookreader) \
 && (cd /var/cache/git/bookreader; git checkout -b laboratory)                   \
 && ( cd /var/cache/git/bookreader                                               \
      yes 'y' | npx update-browserslist-db@latest                                \
      npm run build --yes || true                                                \
    )                                                                            \
 && cp -rp /var/cache/git/bookreader/BookReader /var/www/html/BookReader         \
 && mv /var/cache/git/bookreader/index.html /var/cache/git/bookreader/demo.html  \
 && mv /etc/ImageMagick-6-policy.xml /etc/ImageMagick-6/policy.xml || true       \
 && rm /var/www/html/index.nginx-debian.html                                     \
 && cp /etc/bookreader/BookReader/images/loading.gif /var/www/html/BookReader/images/loading.gif \
 && /usr/local/bin/book --uri "${FILE_URI}" || true
COPY config/ /
CMD ["bash"]
EXPOSE 8000
