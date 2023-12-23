#! /usr/bin/env raku
my @list = <kaluga petrozavodsk vrindavan>;
for @list -> $city {
    for 2023..2043 -> $year {
        shell "./parse.raku {$city} {$year}"
    }
}
