#!/usr/bin/raku

use JSON::Tiny;

sub MAIN(Str $city, Int $year) {

    my Str $fmt = '24hour';
    my @parts;
    my @srss;
    my %data;
    my Date $d;
    my $ua; #User-Agent string
    my Str $date;
    my Str $sunrise;
    my Str $sunset;
    my Str $result;
    my Int @timeouts = [1, 2, 3];
    my Int @years = [2021, 2022];
    my Str $url;
    my Str $socks = '127.0.0.1:9050';
    my Str $proxy_ip;
    my Int constant $tries = 50;
    my Int $i;
    my Str ($geoname-id, $slug);
    my $cities = '../csv/cities.csv';
    my Bool $already;
    my ($filename, $line);
    my Str $new_year_string = "{$year}-01-01";
    my Int constant $timeout = 360;
    my Str $last_line;
    my Str $server_restart = "/etc/init.d/tor restart";

    $filename = "{$city}_{$year}.csv";
    if !($filename.IO ~~ :e) {
       open($filename, :w).close;
    }

    if $filename.IO ~~ :e && $filename.IO.lines.elems == 365 {
        "$city $year already done.".say;
        exit;
    }

    my Str $list = '../uas.txt';
    my Str $base = "https://www.drikpanchang.com/dp-api/panchangam/dp-surya-siddhanta-panjika.php?key=FGHSDD-BENGALI-PANJIKA-778JKS";
    $line = $cities.IO.lines.grep(*.contains($city))[0];
    say ($city, $line);
    @parts = $line.split(';');
    $geoname-id = @parts[4];
    say $geoname-id;
    $d = Date.new("$year-01-01");

    say $city;
    say ('=' xx $city.chars).join('');
    shell $server_restart;

    repeat {
        $last_line = '';
        $last_line = $filename.IO.lines[* - 1] if $filename.IO.lines.elems;
        say $last_line.substr: 11 .. 20 if $last_line;
        $d = $last_line ?? Date.new($last_line.substr: 11..20) !! Date.new($new_year_string);
        $d .= later(:1day) if $last_line;
        $date = $d.Str.split('-').reverse.join('/');
        $proxy_ip = $socks;
        $url = "$base&geoname-id=$geoname-id&date=$date&time-format=$fmt";

        repeat {

            $i = 0;
            repeat {
                $ua = $list.IO.lines.pick;
                $result = qqx/curl --user-agent "$ua" --socks5 $proxy_ip --max-time 60 "$url"/;
                #$result = qq:x/curl --user-agent "$ua" --max-time 60 "$url"/;
                sleep @timeouts.pick;
            } until $result || $i++ == $tries;

            sleep $timeout unless $result;

        } until $result;

        #die "Something wrong!" unless $result;

        %data = from-json $result;
        $sunrise = %data{'panchangam_data'}{'sunrise'}[0]{'element_value'};
        $sunset = %data{'panchangam_data'}{'sunset'}[0]{'element_value'};
        $filename.IO.spurt: ($date, "$d $sunrise", "$d $sunset").join(';') ~ "\n", :append;
        say "\n";
        $already = $filename.IO.lines.elems == 365;
    } until $already;

    say 'done.';
}
