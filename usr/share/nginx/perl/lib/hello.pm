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
    my $pdf_file = '/var/cache/git/bookreader/Drmg062/Drmg062.pdf';

    # Create a new Image::Magick object
    my $image = Image::Magick::Q16->new;

    if($page eq "idx"){
      my $pdf = CAM::PDF->new($pdf_file);
      my $page_count = $pdf->numPages();
      $r->log_error(0, "Page count is: $page_count\n");
      $r->send_http_header("application/json");
      $r->print('{');
      $r->print("\"pages\":$page_count");
      my $status = $image->Read("pdf:${pdf_file}");
      for my $page_number (0 .. $page_count-1) {
          $image->Set(index => $page_number);
          my ($width, $height) = $image->Get('width', 'height');
          my $current_page=$page_number + 1;
          $r->print("$current_page $width x $height\n");
      }
      $r->print('}');
   
    }else{
    # Read the specific page from the PDF file
    my $status = $image->Read("pdf:${pdf_file}[${page}]");
    die "Error reading PDF file: $status" if $status;

    # Write the image to a PNG file
    $image->Set(alpha => 'On');
    $image->Transparent(color => 'white');
    $image->Set(colorspace => 'RGB');     
    $image->Set(magick => 'png');
    $image->Set(density => '200x200');     
    $image->Resize(width => 1275, height => 1650);

    # Response
    $r->send_http_header("image/png");
    binmode STDOUT;
    $r->print($image->ImageToBlob());
   }



#    $r->print("hello!\n<br/>");
#    $r->print( Data::Dumper->Dump([$r->args]) );

#    if (-f $r->filename or -d _) {
#        $r->print($r->uri, " exists!\n");
#    }

    return OK;
}

1;
__END__

