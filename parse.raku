#!/usr/bin/env raku

use JSON::Tiny;

sub MAIN(Str $city, Int $year) {

    my Str $fmt = '24hour';
    my Str $delimeter = ';';
    my Str $cities = 'csv/cities.csv';
    my @list = 'uas.txt'.IO.lines;
    my Str $socks = '127.0.0.1:9050';
    my Str $proxy_ip;
    my @srss;
    my %data;
    my Str $ua; #User-Agent string
    my Str $date;
    my Str $sunrise;
    my Str $sunset;
    my Str $result;
    my Int @timeouts = [1, 2, 3];
    my Str $url;
    my Int constant $tries = 50;
    my Int $i;
    my Str ($geoname-id, $slug);
    my Bool $already;
    my Str ($filename, $line);
    my Str $new_year_string = "{$year}-01-01";
    my Str $last_line;
    my Str $server_restart = "/etc/init.d/tor restart";

    $filename = "srss/{$city}_{$year}.csv";
    if !($filename.IO ~~ :e) {
       open($filename, :w).close;
    }

    if $filename.IO.lines.elems && defined($filename.IO.lines[*-1].index: "12-31") {
        "$city $year already done.".say;
        exit;
    }

    my Str $base = "https://www.drikpanchang.com/dp-api/panchangam/dp-surya-siddhanta-panjika.php?key=FGHSDD-BENGALI-PANJIKA-778JKS";
    my @cities-array = $cities.IO.lines;

    $line = @cities-array.grep(*.contains($city))[0];
    say $city;
    say ('=' xx $city.chars).join('');
    $geoname-id = $line.split($delimeter)[4];

    shell $server_restart;

    repeat {
        $last_line = '';
        $last_line = $filename.IO.lines[* - 1] if $filename.IO.lines.elems;
        say $last_line.substr: 11 .. 20 if $last_line;
        my Date $d = $last_line ?? Date.new($last_line.substr: 11..20) !! Date.new($new_year_string);
        $d .= later(:1day) if $last_line;
        $date = $d.Str.split('-').reverse.join('/');
        $proxy_ip = $socks;
        $url = "$base&geoname-id=$geoname-id&date=$date&time-format=$fmt";

        repeat {

            $i = 0;
            repeat {
                $ua = @list.pick;
                $result = qqx/curl --user-agent "$ua" --socks5 $proxy_ip --max-time 60 "$url"/;
                sleep @timeouts.pick;
            } until $result || $i++ == $tries;

        } until $result;

        #die "Something wrong!" unless $result;

        %data = from-json $result;
        $sunrise = %data{'panchangam_data'}{'sunrise'}[0]{'element_value'};
        $sunset = %data{'panchangam_data'}{'sunset'}[0]{'element_value'};
        $filename.IO.spurt: ($date, "$d $sunrise", "$d $sunset").join($delimeter) ~ "\n", :append;
        say "\n";
        $already = defined($filename.IO.lines[* - 1].index: "12-31");
    } until $already;

    say 'done.';
}
