package hello;

# use strict;
use CAM::PDF;
use Data::Dumper;
use nginx;
use warnings;

sub handler {
    my $r = shift;

    return OK if $r->header_only;

    my $page="0";
    if($r->args =~ /page=(html|idx|json|js|\d+)$/){ $page=$1; }

    # Define the input PDF file and the output PNG file
    my $book_dir = '/var/www/html/books';
    my $pdf_file = "${book_dir}/Dragon/Drmg062.pdf";

    if($r->filename=~/\/iabr\/(.*)/){
      $rel_file = "$1";
      $pdf_file = "${book_dir}/${rel_file}";
    }

    if($page eq "json"){
      my $pdf = CAM::PDF->new($pdf_file);
      my $page_count = $pdf->numPages();
      $r->send_http_header("application/json");
      $r->print("{\n  \"ppi\": 200,\n  \"data\": [\n            [\n");
      for my $page_number (0 .. $page_count-1) {
          my $current_page=$page_number;
          $r->print("              {\"width\": 1275, \"height\": 1650, \"uri\": \"/iabr/${rel_file}?page=${current_page}\"}");
          if($current_page < $page_count - 1){
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
    }elsif($page eq "html"){
      open(my $in_fh, '<', "/var/cache/git/bookreader/_index.html") or die "Cannot open /var/cache/git/bookreader/_index.html for reading: $!";
      my $content = do { local $/; <$in_fh> };
      close($in_fh) or die "Cannot close $input_file: $!";
      $content =~ s/index.js/\/iabr\/$rel_file?page=js/g;
      $r->send_http_header("text/html");
      $r->print($content);
    }elsif($page eq "js"){
      open(my $in_fh, '<', "/var/cache/git/bookreader/_index.js") or die "Cannot open /var/cache/git/bookreader/_index.js for reading: $!";
      my $content = do { local $/; <$in_fh> };
      close($in_fh) or die "Cannot close $input_file: $!";
      $content =~ s/index.json/\/iabr\/$rel_file?page=json/g;
      $r->send_http_header("text/javascript");
      $r->print($content);
    }else{
    # Read the specific page from the PDF file
    # The native perlmagick stuff doesn't seem to be able to upscale, so using the shell
    open(my $convert_fh, '-|', "convert -density 200 $pdf_file\[$page\] png:-") 
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

