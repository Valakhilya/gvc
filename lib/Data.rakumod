unit module Data;

our @cities is export = 'csv/cities.csv'.IO.lines;
our @ekadashis is export = 'csv/ekadashis.csv'.IO.lines;

sub get-navadvip-tithis($year) is export {
    return "csv/nabadwip/nabadwip_$year.csv".IO.lines;
}
