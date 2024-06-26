package hello;

# use strict;
use CAM::PDF;
use Data::Dumper;
use Image::Magick::Q16;
use nginx;
use warnings;

sub handler {
    my $r = shift;

    return OK if $r->header_only;

    my $page="0";
    $r->log_error(0, $r->args);
    if($r->args =~ /page=(idx|\d+)/){ $page=$1; }

    # Define the input PDF file and the output PNG file
    my $pdf_file = "${book_dir}/Dragon/Drmg062.pdf";
    my $book_dir = '/var/www/html/books';
    $r->log_error(0, Data::Dumper->Dump([$r->filename]));
    if($r->filename=~/\/iabr\/(.*)/){
      $rel_file = "$1";
      $pdf_file = "${book_dir}/${rel_file}";
    }
    $r->log_error(0, Data::Dumper->Dump([$pdf_file]));

    # Create a new Image::Magick object
    my $image = Image::Magick::Q16->new;


    if($page eq "idx"){
      my $pdf = CAM::PDF->new($pdf_file);
      my $page_count = $pdf->numPages();
      $r->log_error(0, "Page count is: $page_count\n");
      $r->send_http_header("application/json");
      $r->print("{\n  \"ppi\": 200,\n  \"data\": [\n");
      my $status = $image->Read("pdf:${pdf_file}");
      for my $page_number (0 .. $page_count-1) {
          my $current_page=$page_number + 1;
          $r->print("    {\"width\": 1275, \"height\": 1650, \"uri\": \"/iabr/${rel_file}?page=${current_page}\"}");
          if($current_page < $page_count){
            $r->print(",\n");
          }else{
            $r->print("\n");
          }

      }
      $r->print("  ]\n");
      $r->print("}");
   
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

