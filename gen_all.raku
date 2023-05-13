#!/usr/bin/env raku

my @list = 'csv/cities.csv'.IO.lines;
my @fields;
my $city;
my $command;
@list.shift;
for @list -> $line {
   @fields = $line.split: ';';
   $city = @fields[1];
   say $city;
   for ['en', 'ru'] -> $locale {
        $command = "./gen.raku {$city} 538 {$locale}";
        shell $command;
    }
}
