#!/usr/bin/env raku

my @list = 'csv/cities.csv'.IO.lines;
my @fields;
my $city;
@list.shift;
for @list -> $line {
   @fields = $line.split: ';';
   $city = @fields[1];
   say $city;
   my $command = "./calc.raku {$city} 538 > logs/{$city}_538.log";
   shell $command;
}
