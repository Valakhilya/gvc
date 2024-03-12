#!/usr/bin/env raku

use lib 'lib';
use Structures;

sub MAIN(Str $filename) {
=begin pod
    Parsing google sheets panjika csv file to usable format
=end pod

    my @lines = $filename.IO.lines;
    my (@result, @parts, @output);
    my ($masa, $tithi, $paksha, $time, $date, $delimeter, $output-dir, 
        $sunrise, $sunset, $cnt);

    $delimeter = ";";
    $output-dir = 'output';
    $cnt = 0;
    $paksha = 'K';
    $masa = 'vishnu';
    
    while $cnt < @lines.elems {
        {$cnt++; next} unless ($cnt >= (@lines.elems - 1) || 
            defined @lines[$cnt].index("K{$delimeter}Pratipad"));
        say @lines[$cnt] if defined @lines[$cnt].index("K{$delimeter}Pratipad");
        last if ($cnt >= @lines.elems - 1);
        {
            printf("%4d: %s\n", $cnt, @lines[$cnt]);
            @result.push(@lines[$cnt]);
            $cnt++; 
        } for ^30;
    };

    say @result;

    for @result -> $line {
        @parts = split($delimeter, $line);
        $masa = %months-names{@parts[0]}.Str if @parts[0];
        $paksha = @parts[1] if @parts[1];
        $tithi = %tithi-names{@parts[2]}.Str;
        $time = @parts[4];
        $date = @parts[7] ~ '-' ~ %months-numbers{@parts[6]}.Str ~ 
            '-' ~ sprintf('%02s', @parts[5]);
        $sunrise = @parts[10];
        $sunset = @parts[11];
        say ($masa, $tithi, $paksha, $date, $time, 
        $sunrise, $sunset).join($delimeter);

        @output.push: ($masa, $tithi, $paksha, $date, $time, 
        $sunrise, $sunset).join($delimeter);
    };
    say @output;

    "$output-dir/$filename".IO.spurt: @output.join("\n");
    'done'.say;
}
