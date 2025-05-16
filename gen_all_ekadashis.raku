#!/usr/bin/env raku

my @list = 'csv/cities.csv'.IO.lines;
my @fields;
my $city;
my $command;
for @list -> $line {
   @fields = $line.split: ';';
   $city = @fields[1];
   say $city;
   for ['en', 'ru'] -> $locale {
        $command = "./gen_ekadashis.raku {$city} 540 {$locale}";
        shell $command;
    }
}
