package iabr;

# use strict;
use CAM::PDF;
use Data::Dumper;
use nginx;
use URI::Encode qw( uri_encode );
use URI::Escape::XS qw( uri_unescape uri_escape );
use warnings;

sub handler {
    my $r = shift;
    return OK if $r->header_only;

    if ($r->filename =~ /\.pdf$/i){
      $r->iabr::pdf_handler;
    }elsif ($r->filename =~ /\.cbr$/i){
      $r->iabr::cbr_handler;
    }elsif ($r->filename =~ /\.cbz$/i){
      $r->iabr::cbz_handler;
    }else{
      $r->send_http_header("text/html");
      $r->print("How did you get here?");
    }
    
}

sub cbr_handler {
    my $r = shift;
    my $page="0";
    if($r->args =~ /page=(html|idx|json|js|\d+)$/){ $page=$1; }else{ $page=$r->args; $page=~s/^page=//;}

    # Define the input PDF file and the output PNG file
    my $book_dir = '/var/www/html/books';
    my $rar_file = "${book_dir}/Life_Cycle_of_a_Silver_Bullet.pdf"; # should be a .cbr


    if($r->filename=~/\/iabr\/(.*)/){
      $rel_file = "$1";
      $rar_file = "${book_dir}/${rel_file}";
    }

    if($page eq "json"){      # return the json index
      my $page_count=0;
      open(my $counter_fh, '-|', "unrar lb ". quotemeta(uri_unescape($rar_file)). " 2>/dev/null") or die "Cannot open index process: $!";
      while (my $line=<$counter_fh>){
        $page_count++;
      }
      close($counter_fh);
      my $line_count=0;
      $r->send_http_header("application/json");
      $r->print("{\n  \"ppi\": 200,\n  \"data\": [\n            [\n");
      open(my $index_fh, '-|', "unrar lb ". quotemeta(uri_unescape($rar_file)). " 2>/dev/null") or die "Cannot open index process: $!";
      #$index_fh->autoflush(1);
      while (my $raw_file=<$index_fh>){
        chomp($raw_file);
        $inner_file=quotemeta($raw_file);
        $uri_file=uri_escape($raw_file);
        my $outer_file=quotemeta(uri_unescape($rar_file));
        $line_count++;
        $r->print("              {");
        $r->print(`/usr/bin/unrar p -inul ${outer_file} ${inner_file}  | /usr/bin/convert - -print "\\"width\\": %w, \\"height\\": %h, " /dev/null`);
        $r->print("\"uri\": \"/iabr/${rel_file}?page=$uri_file\"}");
        if($line_count < $page_count){
          $r->print(",\n");
        }else{
          $r->print("\n");
        }
      }
      $r->print("            ]\n         ],\n");
      $r->print("   \"bookTitle\": \"BookShelf\",\n");
      $r->print("   \"bookUrl\": \"/\",\n");
      $r->print("   \"ui\": \"full\",\n");
      $r->print("   \"el\": \"#BookReader\"\n");
      $r->print("}");
      close($index_fh);
      return OK;
    }elsif($page eq "html"){  # return the html that calls the json
      open(my $in_fh, '<', "/var/cache/git/bookreader/_index.html") or die "Cannot open /var/cache/git/bookreader/_index.html for reading: $!";
      my $content = do { local $/; <$in_fh> };
      close($in_fh) or die "Cannot close $input_file: $!";
      my $js_uri=uri_encode("\/iabr\/$rel_file?page=js");
      $js_uri=~s/#/%23/g;
      $content =~ s/index.js/$js_uri/g;
      $r->send_http_header("text/html");
      $r->print($content);
    }elsif($page eq "js"){    # return the javascript template
      open(my $in_fh, '<', "/var/cache/git/bookreader/_index.js") or die "Cannot open /var/cache/git/bookreader/_index.js for reading: $!";
      my $content = do { local $/; <$in_fh> };
      close($in_fh) or die "Cannot close $input_file: $!";
      my $json_uri=uri_encode("\/iabr\/$rel_file?page=json");
      $json_uri=~s/#/%23/g;
      $content =~ s/index.json/$json_uri/g;
      $r->send_http_header("text/javascript");
      $r->print($content);
    }else{                    # it's a single page, return an image
      ####################
      ### Page Handler ###
      ####################
      my $outer_file=quotemeta(uri_unescape($rar_file));
      my $inner_file=quotemeta(uri_unescape($page));

      # need file type detection here
      my $mime_type=`/usr/bin/unrar p -inul ${outer_file} ${inner_file} | /usr/bin/file --mime-type - | /usr/bin/awk '{print \$NF}'`;
      chomp($mime_type);
      if("$mime_type" eq "image/jpeg"){
        $r->send_http_header("image/jpg");
      }else{
        $r->log_error(0,"\nmime type -=[ " . $mime_type . " ]=-\n");
        $r->send_http_header("$mime_type");
      }
      binmode STDOUT;
      $r->print(`/usr/bin/unrar p -inul ${outer_file} ${inner_file}`);
      ####################
      ### Page Handler ###
      ####################
    }
   return OK;
}

sub cbz_handler {
    my $r = shift;
    my $page="0";
    if($r->args =~ /page=(html|idx|json|js|\d+)$/){ $page=$1; }else{ $page=$r->args; $page=~s/^page=//;}

    # Define the input PDF file and the output PNG file
    my $book_dir = '/var/www/html/books';
    my $zip_file = "${book_dir}/Life_Cycle_of_a_Silver_Bullet.pdf"; # should be a .cbz


    if($r->filename=~/\/iabr\/(.*)/){
      $rel_file = "$1";
      $zip_file = "${book_dir}/${rel_file}";
    }

    if($page eq "json"){      # return the json index
      #####################
      ### Index Handler ###
      #####################
      my $page_count=0;
      open(my $counter_fh, '-|', "/usr/bin/unzip -jl ". quotemeta(uri_unescape($zip_file))); 
      $counter_fh->autoflush(1);
      while (my $line=<$counter_fh>){
	chomp($line);
        next unless($line =~/\s+(\d+)\s+\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}/);
        next if($1==0);
        next if($line=~/[Tt][Xx][Tt]$/);
        $line =~s/\s+(\d+)\s+\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}\s+//;
        $page_count++;
      }
      close($counter_fh);
      my $line_count=0;
      $r->send_http_header("application/json");
      $r->print("{\n  \"ppi\": 200,\n  \"data\": [\n            [\n");
      open(my $index_fh, '-|', "/usr/bin/unzip -jl ". quotemeta(uri_unescape($zip_file)));
      while (my $raw_file=<$index_fh>){
        chomp($raw_file);
        next unless($raw_file =~/\s+(\d+)\s+\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}/);
        next if($1==0);
        next if($raw_file=~/[Tt][Xx][Tt]$/);
        $raw_file =~s/\s+(\d+)\s+\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}\s+//;
        $inner_file=quotemeta($raw_file);
        $uri_file=uri_escape($raw_file);
        my $outer_file=quotemeta(uri_unescape($zip_file));
        $line_count++;
        $r->print("              {");
        $r->print(`/usr/bin/unzip -p ${outer_file} ${inner_file}  | /usr/bin/convert - -print "\\"width\\": %w, \\"height\\": %h, " /dev/null`);
        $r->print("\"uri\": \"/iabr/${rel_file}?page=$uri_file\"}");
        if($line_count < $page_count){
          $r->print(",\n");
        }else{
          $r->print("\n");
        }
      }
      close($index_fh);
      $r->print("            ]\n         ],\n");
      $r->print("   \"bookTitle\": \"BookShelf\",\n");
      $r->print("   \"bookUrl\": \"/\",\n");
      $r->print("   \"ui\": \"full\",\n");
      $r->print("   \"el\": \"#BookReader\"\n");
      $r->print("}");
      return OK;
      #####################
      ### Index Handler ###
      #####################
    }elsif($page eq "html"){  # return the html that calls the json
      open(my $in_fh, '<', "/var/cache/git/bookreader/_index.html") or die "Cannot open /var/cache/git/bookreader/_index.html for reading: $!";
      my $content = do { local $/; <$in_fh> };
      close($in_fh) or die "Cannot close $input_file: $!";
      my $js_uri=uri_encode("\/iabr\/$rel_file?page=js");
      $js_uri=~s/#/%23/g;
      $content =~ s/index.js/$js_uri/g;
      $r->send_http_header("text/html");
      $r->print($content);
    }elsif($page eq "js"){    # return the javascript template
      open(my $in_fh, '<', "/var/cache/git/bookreader/_index.js") or die "Cannot open /var/cache/git/bookreader/_index.js for reading: $!";
      my $content = do { local $/; <$in_fh> };
      close($in_fh) or die "Cannot close $input_file: $!";
      my $json_uri=uri_encode("\/iabr\/$rel_file?page=json");
      $json_uri=~s/#/%23/g;
      $content =~ s/index.json/$json_uri/g;
      $r->send_http_header("text/javascript");
      $r->print($content);
    }else{                    # it's a single page, return an image
      ####################
      ### Page Handler ###
      ####################
      my $outer_file=quotemeta(uri_unescape($zip_file));
      my $inner_file=quotemeta(uri_unescape($page));

      # need file type detection here
      my $mime_type=`/usr/bin/unzip -p ${outer_file} ${inner_file} | /usr/bin/file --mime-type - | /usr/bin/awk '{print \$NF}'`;
      chomp($mime_type);
      if("$mime_type" eq "image/jpeg"){
        $r->send_http_header("image/jpg");
      }else{
        $r->log_error(0,"$mime_type");
        $r->send_http_header("$mime_type");
      }
      binmode STDOUT;
      $r->print(`/usr/bin/unzip -p ${outer_file} ${inner_file}`);
    }
   return OK;
}

sub pdf_handler {
    my $r = shift;

    my $page="0";
    if($r->args =~ /page=(html|idx|json|js|\d+)$/){ $page=$1; }

    # Define the input PDF file and the output PNG file
    my $book_dir = '/var/www/html/books';
    my $pdf_file = "${book_dir}/Life_Cycle_of_a_Silver_Bullet.pdf";

    if($r->filename=~/\/iabr\/(.*)/){
      $rel_file = "$1";
      $pdf_file = "${book_dir}/${rel_file}";
    }

    if($page eq "json"){
      my $pdf = CAM::PDF->new($pdf_file);
      my $page_count = $pdf->numPages();
      $r->send_http_header("application/json");
      $r->print("{\n  \"ppi\": 200,\n  \"data\": [\n            [\n");
      # convert -density 200 Life_Cycle_of_a_Silver_Bullet.pdf[0] png:- | file - | sed -r 's/.*[[:space:]]([[:digit:]]+[[:space:]]x[[:space:]][[:digit:]]+).*/\1/'
      for my $page_number (0 .. $page_count-1) {
        my $current_page=$page_number;
	my $img_uri=uri_encode("/iabr/${rel_file}?page=${current_page}");
	$img_uri=~s/#/%23/g;
        open(my $index_fh, '-|', "/usr/bin/convert -density 200 ". quotemeta(uri_unescape($pdf_file)) . " png:- | file - ");
        while (my $raw_file=<$index_fh>){
          chomp($raw_file);
          my $width = 1275;
          my $height = 1650;
          if ($raw_file =~ /(\d+)\s*x\s*(\d+)/) {
            $width=$1;
            $height=$2;
          }else{
            $r->log_error(0,$raw_file);
          }
          $r->print("             {\"width\": ${width}, \"height\": ${height}, \"uri\": \"$img_uri\"}");
          if($current_page < $page_count - 1){
            $r->print(",\n");
          }else{
            $r->print("\n");
          }
        }
        close($index_fh);
      }
      $r->print("            ]\n         ],\n");
      $r->print("   \"bookTitle\": \"BookShelf\",\n");
      $r->print("   \"bookUrl\": \"/\",\n");
      $r->print("   \"ui\": \"full\",\n");
      $r->print("   \"el\": \"#BookReader\"\n");
      $r->print("}");
    }elsif($page eq "html"){
      open(my $in_fh, '<', "/var/cache/git/bookreader/_index.html") or die "Cannot open /var/cache/git/bookreader/_index.html for reading: $!";
      my $content = do { local $/; <$in_fh> };
      close($in_fh) or die "Cannot close $input_file: $!";
      my $js_uri=uri_encode("\/iabr\/$rel_file?page=js");
      $js_uri=~s/#/%23/g;
      $content =~ s/index.js/$js_uri/g;
      $r->send_http_header("text/html");
      $r->print($content);
    }elsif($page eq "js"){
      open(my $in_fh, '<', "/var/cache/git/bookreader/_index.js") or die "Cannot open /var/cache/git/bookreader/_index.js for reading: $!";
      my $content = do { local $/; <$in_fh> };
      close($in_fh) or die "Cannot close $input_file: $!";
      my $json_uri=uri_encode("\/iabr\/$rel_file?page=json");
      $json_uri=~s/#/%23/g;
      $content =~ s/index.json/$json_uri/g;
      $r->send_http_header("text/javascript");
      $r->print($content);
    }else{
    # Read the specific page from the PDF file
    # The native perlmagick stuff doesn't seem to be able to upscale, so using the shell
    open(my $convert_fh, '-|', "convert -density 200 ". quotemeta(uri_unescape($pdf_file)) ."\[$page\] png:- 2>/dev/null") 
      or die "Cannot open convert process: $!";
    $convert_fh->autoflush(1);
    $r->send_http_header("image/png");
    binmode STDOUT;
    $r->print(<$convert_fh>);
    close($convert_fh);
   }

   return OK;
}

1;
__END__

