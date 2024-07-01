unit module Data;

our @dst-times is export = 'csv/dst.csv'.IO.lines;
our @cities is export = 'csv/cities.csv'.IO.lines;
our @ekadashis is export = 'csv/ekadashis.csv'.IO.lines;

.say for @cities; 

sub get-navadvip-tithis($year) is export {
    return "csv/navadvip_$year.csv".IO.lines;
}

