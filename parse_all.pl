#!/usr/bin/perl5.40
use v5.40;

my $cities_file_path = './csv/cities.csv';
my @lines;
my @cities_slugs;
open my $fh, '<', $cities_file_path or die "Can not open cities file";
@lines = <$fh>;
map {
    my @parts = split /;/, $_;
    push @cities_slugs, $parts[1];
} @lines;
close $fh;

for my $year (2027 .. 2035){
    for my $city (@cities_slugs) {
        system "./parse.pl $city $year";
    }
}
