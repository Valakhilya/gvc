#!/usr/bin/env raku

use JSON::Fast;
use lib 'lib';
use Structures;
use DateTimeUtils;
use Constants;
use Data;
use Config;

sub check_city($city) {
    my @lines = './csv/cities.csv'.IO.lines;
    my @cities;
    for @lines -> $line {
        my @parts = $line.split: $delimeter;
        push @cities, @parts[1];
    }

    unless $city ∈ @cities {
        say "No such city in the base: $city";
        exit 0;
    }
}

sub MAIN(Str $city, Int $year) {
    #  city is city slug in csv/cities.csv file
    #  and year is Gaurabda year number
    check_city($city);

    my (%tithi-map-navadvip, %tithi-map-city, %tithi-srss, %tithi-by-date, 
        %calendar); 
    my $city-name = get-city-name($city);
    my $acc = get-accusative($city);

    # Initialize basic structures

    my $city-tz = tz($city); #timezone of the city
    # information about tithis from the csv/navadvip_$year.csv file
    my @tithis = get-navadvip-tithis($year); 
    my %dst = get-dst-data($city, $year);

    # information about sunrises and sunsets
    my %city-srss = get-city-srss-map($city, $year);
    my %navadvip-srss = get-city-srss-map($navadvip, $year);
    my %ekadashis-map = get-ekadashis-map();
    my %events = get-events-map($city);
    # titles of the tithis
    my %tithi-names = get-tithi-names-map();

    # We keep in tithi file data for three Gaurabda years:
    # current year, Govinda masa of previous year and Vishnu masa
    # of the next year
    # variable current-masa is the title for masa on the current loop
    # iteration

    my $current-masa = '';
    my @masas-list;

    loop ( my $i = 0; $i < @tithis.elems; $i++ ) { #main cycle

    my $line = @tithis[$i];
    my ($masa, $tithi, $paksha, $current-date, $end-tithi-navadvip,
        $end-sunrise-navadvip, $end-sunset-navadvip) =
        parse-tithi-line($line);

    # current year is year of Gaurabda or maybe next or previous year
    
    my $current-year = get-current-year($current-date, $year);

    # end of current tithi for the city

    my $end-tithi-city = local-time-zone($end-tithi-navadvip, $city, 
        $year, %dst);

    # if masa from line in the file differ from current-masa, then we put it
    # in the list

    { 
        @masas-list.push: $masa; 
        $current-masa = $masa
    } unless $masa eq $current-masa; # for testing masas; if purushottam there.

    say '';
    say 'Current year: ' ~ $current-year;
    say 'Current date: ' ~ $current-date;
    say 'Masa: ' ~ $masa;
    say 'Tithi: ' ~ $tithi;
    say 'Paksha: ' ~ $paksha;

    # calculating start date and time for the tithi
    # end of previous tithi is start for current 

    my $start-line;
    if ($i > 0) {
        $start-line = @tithis[$i - 1];
    }
    else { # get tithis from the file for previous year
        my @prev-year-tithis = get-navadvip-tithis($year - 1);
        my $m = $tithi eq $pratipad && $paksha eq 'K' ?? get-prev-masa($masa)
                                                     !! $masa;
        my $t = get-prev-tithi($tithi, $paksha);
        my $p = get-prev-paksha($tithi, $paksha);
        my @grep = @prev-year-tithis.grep(*.contains(
            [$m, $t, $p].join: $delimeter));
            $start-line = @grep[* - 1];
    }

    my ($start-masa-navadvip,
        $start-tithiname-navadvip, 
        $start-paksha-navadvip, 
        $start-date-navadvip, 
        $start-tithi-navadvip,
        $start-sunrise-navadvip,
        $start-sunset-navadvip) =
        parse-tithi-line($start-line);
    my $start-tithi-city = local-time-zone($start-tithi-navadvip, $city,
        $year, %dst);

    say 'Start date in Navadwip: ' ~ $start-date-navadvip;
    say 'Start sunrise in Nabadwip: ' ~ $start-sunrise-navadvip;
    say 'Start sunset in Nabadwip: ' ~ $start-sunset-navadvip;
    say "Tithi start in $city: " ~ $start-tithi-city;
    say 'Tithi start in Navadwip: ' ~ $start-tithi-navadvip;
    say "Tithi end in $city: " ~ $end-tithi-city;
    say 'Tithi end in Nabadwip: ' ~ $end-tithi-navadvip;

# calculating two sunrises times - it is quite enough

    my $start-date-city = $start-tithi-city.words[0];

    say 'Tithi start sunrise date: ' ~ $start-date-city;
    say 'Tithi start sunrise date in Nabadwip: ' ~ $start-date-navadvip;

# Note that date of the next day and date of the end of tithi may not be same

    my $next-date-city = get-tomorrow($start-date-city);
    my $next-date-navadvip = get-tomorrow($start-date-navadvip);

    say "Tithi next sunrise date in $city: " ~ $next-date-city;
    say 'Tithi next sunrise date in Nabadwip: ' ~ $next-date-navadvip;

    my $start-sunrise-city;
    if $city eq $navadvip {
        $start-sunrise-city = $start-sunrise-navadvip
    }
    if not $start-sunrise-city {
        $start-sunrise-city = 
            get-city-sunrise($start-date-city, $city, %city-srss);
    }
    { say $start-date-city; die 'No sunrise' } \
        unless $start-sunrise-city.Str.trim;

    say "Tithi start sunrise in $city: " ~ $start-sunrise-city;
    say 'Tithi start sunrise in Nabadwip: '~$start-sunrise-navadvip;

# next day sunrise

    my $next-day-sunrise-city;
    my ($next-masa-navadvip, $next-tithi-navadvip, $next-paksha-navadvip, 
        $next-day-end-navadvip, $next-day-sunrise-navadvip, 
        $next-day-sunset-navadvip);

    if (0 <= $i < @tithis.elems - 1) {
        if $next-date-navadvip eq $current-date {
            $next-day-sunrise-navadvip = $end-sunrise-navadvip
        }
        else {
            my $next-line = @tithis[$i + 1];
            if $next-line.contains($next-date-navadvip) {
                ($next-masa-navadvip,
                $next-tithi-navadvip,
                $next-paksha-navadvip,
                $next-date-navadvip, 
                $next-day-end-navadvip,
                $next-day-sunrise-navadvip, 
                $next-day-sunset-navadvip) = parse-tithi-line($next-line);
            }
        }
    }
    if not $next-day-sunrise-navadvip {
        $next-day-sunrise-navadvip = get-city-sunrise($next-date-navadvip,
            $navadvip, %navadvip-srss);
    }
    $next-day-sunrise-city = $city eq $navadvip ?? $next-day-sunrise-navadvip 
            !! get-city-sunrise($next-date-city, $city, %city-srss);

    say 'Tithi next day sunrise in Nabadwip: '~ $next-day-sunrise-navadvip;
    say "Tithi next day sunrise in $city: " ~ $next-day-sunrise-city;

    my $end-date-city = $end-tithi-city.words[0];
    my $end-sunrise-city = $city eq $navadvip ?? $end-sunrise-navadvip
        !! get-city-sunrise($end-date-city, $city, %city-srss);

    say "End date in $city: " ~ $end-date-city;
    say "End sunrise in $city: " ~ $end-sunrise-city;

# sunsets

    my $end-date-navadvip = $end-tithi-navadvip.words[0];
    if not $end-sunset-navadvip {
        $end-sunset-navadvip = get-city-sunset($end-date-navadvip, $navadvip, 
            %navadvip-srss);
    }
    my $end-sunset-city = $city eq $navadvip ?? $end-sunset-navadvip 
        !! get-city-sunset($end-date-city, $city, %city-srss);

    say "End sunset in Nabadwip: " ~ $end-sunset-navadvip;
    say "End sunset in $city: " ~ $end-sunset-city;

# calculating date of tithi in Gregorian

    my ($date-city, $type-city, $purity-city, $arunoday-city) = 
        calculate-tithi-date(
            $start-tithi-city, 
            $end-tithi-city,
            $start-sunrise-city,
            $next-day-sunrise-city,
            $end-sunrise-city, 
            @tithis[$i].contains($ekadashi));

    my ($date-navadvip, $type-navadvip, $purity-navadvip, $arunoday-navadvip) =
        calculate-tithi-date(
            $start-tithi-navadvip,
            $end-tithi-navadvip, 
            $start-sunrise-navadvip,
            $next-day-sunrise-navadvip, 
            $end-sunrise-navadvip, $line.contains($ekadashi));
        
    say "Tithi date in $city: " ~ $date-city;
    say "Tithi type in $city: " ~ $type-city;
    say "Tithi purity in $city: " ~ $purity-city;
    say "Arunoday in $city: " ~ $arunoday-city;
    say 'Tithi date in Navadwip: ' ~ $date-navadvip;
    say 'Tithi type in Navadwip: ' ~ $type-navadvip;
    say 'Tithi purity in Nabadwip: ' ~ $purity-navadvip;
    say 'Arunoday in Nabadwip: ' ~ $arunoday-navadvip;

# putting to maps
    
    my %h1 = (
        'start' => $start-tithi-navadvip,
        'end' => $end-tithi-navadvip,
        'start-sunrise' => $start-sunrise-navadvip,
        'next-day-sunrise' => $next-day-sunrise-navadvip,
        'end-sunrise' => $end-sunrise-navadvip,
        'end-sunset' => $end-sunset-navadvip,
        'date' => $date-navadvip,
        'arunoday' => $arunoday-navadvip,
        'type' => $type-navadvip,
        'purity' => $purity-navadvip,
        'year' => $current-year,
        'masa' => $masa,
        'tithi' => $tithi,
        'paksha' => $paksha
    );
    %tithi-map-navadvip{$current-year}{$masa}{$tithi}{$paksha} = %h1;

    my %h2 = (
        'start' => $start-tithi-city,
        'end' => $end-tithi-city,
        'start-sunrise' => $start-sunrise-city,
        'next-day-sunrise' => $next-day-sunrise-city,
        'end-sunrise' => $end-sunrise-city,
        'end-sunset' => $end-sunset-city,
        'date' => $date-city,
        'arunoday' => $arunoday-city,
        'type' => $type-city,
        'purity' => $purity-city,
        'year' => $current-year,
        'masa' => $masa,
        'tithi' => $tithi,
        'paksha' => $paksha
    );
    %tithi-map-city{$current-year}{$masa}{$tithi}{$paksha} = %h2;

    if $type-navadvip eq $kshaya {
        %tithi-by-date{$date-navadvip}{$kshaya} = %h1;
    }
    else {
        %tithi-by-date{$date-navadvip}{$shuddha} = %h1;
    }

    # double the tithi in sampurna case, in order that date of next or 
    # previous day in sampurna also point to this tithi

    if $type-navadvip eq $sampurna {
        if $tithi eq $ekadashi {
            my $yesterday = get-yesterday($date-navadvip);
            %h1{'date'} = $yesterday;
            %tithi-by-date{$yesterday}{$shuddha} = %h1;
        }
        else {
            my $tomorrow = get-tomorrow($date-navadvip);
            %tithi-by-date{$tomorrow}{$shuddha} = %h1;
        }
    } 

    my %h3 = (
        'sunrise' => $end-sunrise-navadvip,
        'sunset' => $end-sunset-navadvip
    );

    %tithi-srss{$current-date} = %h3;

    } # end of main cycle

# calculating ekadashis

    say '';
    say 'Calculating ekadashis: ';
    for [$year - 1, $year, $year + 1] -> $y {
        for @masas -> $masa {
            for ['K', 'G'] -> $paksha {
                next unless %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha};
                say '=' x 20;
                say 'Year: ' ~ $y;
                say 'Masa: ' ~ $masa;
                say 'Paksha: ' ~ $paksha;

                my %map = %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha};
                my %e = %ekadashis-map{$masa}{$paksha};
                my $date = %map{'date'};
                my $slug = %e{'slug'};
                my $start = %map{'start'};
                my $end = %map{'end'};
                my $ekadashi-type = %map{'type'};
                my $arunoday = %map{'arunoday'};
                my $purity = %map{'purity'};
                my $first-sunrise = $start.contains($date) ?? 
                    %map{'start-sunrise'} !! %map{'end-sunrise'};
                my $next-date = get-tomorrow($date);

                my $second-sunrise;
                if $city eq $navadvip {
                    $second-sunrise = %tithi-srss{$next-date}{'sunrise'};
                };
                if not $second-sunrise {
                    $second-sunrise = get-city-sunrise($next-date,
                    $city, %city-srss);
                };
                my $ekadashi-name = %e{'name'};
                my %d = %tithi-map-city{$y}{$masa}{$dvadashi}{$paksha};
                my $dvadashi-start = %d{'start'};
                my $dvadashi-end = %d{'end'};
                my $dvadashi-type = %d{'type'};
                my $dvadashi-date = %d{'date'};
                my $dvadashi-sunrise = %d{'start'}.contains($dvadashi-date) ?? 
                    %d{'start-sunrise'} !! %d{'end-sunrise'};
                my $dvadashi-sunset;
                if $city eq $navadvip {
                    $dvadashi-sunset = %tithi-srss{$dvadashi-date}{'sunset'}; 
                }
                if not $dvadashi-sunset {
                    $dvadashi-sunset = get-city-sunset($dvadashi-date, $city, 
                    %city-srss);
                }
                my $trayodashi-end = 
                    %tithi-map-city{$y}{$masa}{$trayodashi}{$paksha}{'end'};
                
                say 'Ekadashi start: ' ~ $start;
                say 'Ekadashi end: ' ~ $end;
                say 'Ekadashi date: ' ~ $date;
                say 'Ekadashi sunrise ' ~ $first-sunrise;
                say 'Ekadashi next sunrise ' ~ $second-sunrise;
                say 'Ekadashi type: ' ~ $ekadashi-type;
                say 'Arunoday: ' ~ $arunoday;
                say 'Dvadashi start: ' ~ $dvadashi-start;
                say 'Dvadashi end: ' ~ $dvadashi-end;
                say 'Dvadashi date: ' ~ $dvadashi-date;
                say 'Dvadashi sunrise ' ~ $dvadashi-sunrise;
                say 'Dvadashi sunset ' ~ $dvadashi-sunset;

                my %nakshatras = get-nakshatras-map($city, $year, %dst);
                my @nakshatras-list = %nakshatras{$y}{$masa}.values;

# Nakshatra yoga test

                say 'Nakshatra yoga test:';
                my Bool $nakshatra-yoga = False;
                my $nakshatra-name;
                my $nakshatra-start;
                my $nakshatra-end;
                my Bool $nakshatra-touches-dvadashi;
                my Bool $dvadashi-ends-after-sunset;
                my Bool $dvadashi-is-longer-than38;
                for @nakshatras-list -> %nksh {
                    $nakshatra-name = %nksh{'name'};
                    $nakshatra-start = %nksh{'start'};
                    $nakshatra-end = %nksh{'end'};
                    say 'Nakshatra name: ' ~ $nakshatra-name;
                    say 'Nakshatra start: ' ~ $nakshatra-start;
                    say 'Nakshatra end: ' ~ $nakshatra-end;
                    $nakshatra-touches-dvadashi = 
                        ($nakshatra-start le $dvadashi-end) &&
                            ($nakshatra-end ge $dvadashi-start);
                    say 'Nakshatra touches dvadashi: ' ~
                        $nakshatra-touches-dvadashi;
                    my $nakshatra-duration = get-duration($nakshatra-start, 
                        $nakshatra-end, $city-tz);
                    say 'Nakshatra duration: ' ~ 
                    duration-to-human-format($nakshatra-duration);
                    my Bool $is-longer-than24hours = 
                        ($nakshatra-duration > 24 * 3600);
                    say 'Nakshatra is longer than 24 hours: ' ~
                        $is-longer-than24hours;
                    my Bool $starts-exactly-at-sunrise = 
                        $dvadashi-sunrise eq $nakshatra-start;
                    say 'Starts exactly on sunrise: ' ~ 
                        $starts-exactly-at-sunrise;
                    my Bool $starts-before-sunrise = $nakshatra-start lt 
                        $dvadashi-sunrise; 
                    say 'Starts before sunrise: ' ~ $starts-before-sunrise;
                    $dvadashi-ends-after-sunset = 
                        $dvadashi-end gt $dvadashi-sunset;
                    say 'Dvadashi ends after sunset: ' ~ 
                        $dvadashi-ends-after-sunset;
                    my $dvadashi-duration = get-duration($dvadashi-start, 
                        $dvadashi-end, $city-tz);
                    say 'Dvadashi duration: ' ~ 
                    duration-to-human-format($dvadashi-duration);
                    my $light-day-duration = get-duration($dvadashi-sunrise, 
                        $dvadashi-sunset, $city-tz);
                    say 'Light day duration: ' ~ 
                    duration-to-human-format($light-day-duration);
                    my $from-sunrise-to-end=get-duration($dvadashi-sunrise, 
                        $dvadashi-end, $city-tz);
                    say 'From sunrise to end of dvadashi: ' ~
                    duration-to-human-format($from-sunrise-to-end);
                    $dvadashi-is-longer-than38 = 
                        $from-sunrise-to-end > 
                        Int(3/8 * $light-day-duration);
                    say 'Dvadashi is longer than 38 of the day: ' ~
                        $dvadashi-is-longer-than38;
                    if ($nakshatra-name ∈ <rohini punarvasu pushya>) {
                        $nakshatra-yoga = 
                            $nakshatra-touches-dvadashi &&
                            $starts-exactly-at-sunrise &&
                            $dvadashi-ends-after-sunset;
                        last if $nakshatra-yoga;
                        $nakshatra-yoga =
                            $nakshatra-touches-dvadashi &&
                            $starts-before-sunrise &&
                            $dvadashi-ends-after-sunset && 
                            $is-longer-than24hours;
                        last if $nakshatra-yoga;
                    }
                    else {
                        $nakshatra-yoga = 
                            $nakshatra-touches-dvadashi &&
                            $starts-exactly-at-sunrise &&
                            $dvadashi-is-longer-than38;
                        last if $nakshatra-yoga;
                        $nakshatra-yoga = 
                            $nakshatra-touches-dvadashi &&
                            $starts-before-sunrise && 
                            $dvadashi-is-longer-than38 && 
                            $is-longer-than24hours;
                        last if $nakshatra-yoga;
                    }
                }
                say 'No nakshatras' unless @nakshatras-list;
                say 'Nakshatra yoga: ' ~ $nakshatra-yoga;

# Tithi test

                my Bool $ekadashi-is-pure = $purity eq $shuddha;
                my $pakshavarddhini-tithi = $paksha eq 'K' ?? $amavasya 
                    !! $purnima;
                my Bool $pakshavarddhini-test;
                my %h = %tithi-map-city{$y}{$masa};
                if (%h{$pakshavarddhini-tithi}.defined) {
                    my %p = %h{$pakshavarddhini-tithi}{$paksha};
                    say 'Pakshavarddhini tithi: ' ~ $pakshavarddhini-tithi;
                    say 'Pakshavarddhini tithi start: ' ~ %p{'start'};    
                    say 'Pakshavarddhini tithi end: ' ~ %p{'end'};    
                    say 'Pakshavarddhini tithi type: ' ~ %p{'type'};    
                    $pakshavarddhini-test = $ekadashi-is-pure &&
                        %p{'type'} eq $sampurna;
                }
                else {
                    $pakshavarddhini-test = False;
                }
                say 'Pakshavarddhini tithi test: ' ~ 
                    $pakshavarddhini-test; 
                my Bool $unmilani-test = $ekadashi-is-pure
                    && $ekadashi-type eq $sampurna
                    && $dvadashi-type eq $kshaya;
                say 'Unmilani test: ' ~ $unmilani-test;
                my Bool $trisprisha-test = $ekadashi-is-pure 
                    && $dvadashi-type eq $kshaya;
                say 'Trisprisha test: ' ~ $trisprisha-test;
                my Bool $vyanjuli-test = $ekadashi-is-pure 
                    && $dvadashi-type eq $sampurna;
                say 'Vyanjuli test: ' ~ $vyanjuli-test;

                my ($fast-date, $fast-type, $mahadvadashi-name);
                $mahadvadashi-name = '';
                if $nakshatra-yoga {
                    $fast-type = $nakshatra-type;
                    $fast-date = $next-date;
                }
                elsif $pakshavarddhini-test {
                    $fast-type = $mahadvadashi;
                    $mahadvadashi-name = $pakshavarddhini;
                    $fast-date = $next-date;
                }
                elsif $unmilani-test {
                    $fast-type = $mahadvadashi;
                    $mahadvadashi-name = $unmilani;
                    $fast-date = $next-date;
                }
                elsif $trisprisha-test {
                    $fast-type = $mahadvadashi;
                    $mahadvadashi-name = $trisprisha;
                    $fast-date = $date;
                }
                elsif $vyanjuli-test {
                    $fast-type = $mahadvadashi;
                    $mahadvadashi-name = $vyanjuli;
                    $fast-date = $next-date;
                }
                elsif $ekadashi-type eq $kshaya {
                    $fast-type = $viddha;
                    $fast-date = $date;
                }
                elsif $ekadashi-is-pure && $ekadashi-type eq $sampurna {
                    $fast-date = $date;
                    $fast-type = $shuddha;
                }
                elsif $purity eq $viddha {
                    $fast-date = $next-date;
                    $fast-type = $viddha;
                }
                elsif $ekadashi-is-pure {
                    $fast-date = $date;
                    $fast-type = $shuddha;                
                }
                else {
                    $fast-date = $next-date;
                    $fast-type = $viddha;
                }

                if $fast-type eq $nakshatra-type {
                    $mahadvadashi-name = %nakshatra-yogas{$nakshatra-name};
                    $fast-type = $mahadvadashi;
                }

                my Bool $vishnu-shrinkhala-yoga-test = False;
                if $paksha eq 'G' && $masa eq $hrishikesh {
                    
# Vishnu shrinkhala yoga test
                    
                    say 'Vishnu shrinkhala yoga test:';
                    my Bool $shravana-touches-day = 
                        $nakshatra-name eq $shravana &&
                        $nakshatra-start le $second-sunrise &&
                        $nakshatra-end ge $first-sunrise;
                    say 'Shravana touches day of ekadashi: ' ~
                        $shravana-touches-day;
                    my Bool $dvadashi-touches-day = 
                        $dvadashi-start le $second-sunrise &&
                        $dvadashi-end ge $first-sunrise;
                    say 'Dvadashi touches day of ekadashi: ' ~
                        $dvadashi-touches-day;
                    my Bool $shrvava-touches-dvadashi-and-day = 
                        $nakshatra-touches-dvadashi &&
                        $shravana-touches-day &&
                        $dvadashi-touches-day;
                    say 'Shravana touches dvadashi and day of ekadashi: ' ~
                        $shrvava-touches-dvadashi-and-day;
                    my Bool $shravana-ends-after-sunset =
                        $nakshatra-end gt $dvadashi-sunset;
                    say 'Shravana ends after sunset: ' ~ 
                        $shravana-ends-after-sunset;
                    say 'Dvadashi ends after sunset: ' ~ 
                        $dvadashi-ends-after-sunset;
                    my Bool $shravana-rules-dvadashi = 
                        $nakshatra-name eq $shravana &&
                        $nakshatra-start le $dvadashi-sunrise &&
                        $nakshatra-end ge $dvadashi-sunrise;
                    say 'Shravana rules dvadashi: ' ~ $shravana-rules-dvadashi;
                    $vishnu-shrinkhala-yoga-test = 
                        $ekadashi-is-pure &&
                        $shrvava-touches-dvadashi-and-day;
                    say 'Vishnu shrinkhala yoga test: ' ~
                        $vishnu-shrinkhala-yoga-test;
                    if $vishnu-shrinkhala-yoga-test {
                        if $shravana-ends-after-sunset &&
                            $dvadashi-ends-after-sunset &&
                            $shravana-rules-dvadashi {
                            $fast-date = $next-date;
                        }
                        else {
                            $fast-date = $date;
                        }
                        $fast-type = $vsy-type;
                        say 'Vishnu shrinkhala yoga fast date: ' ~ $fast-date; 
                    }
                }

# Gurudev's disappearance

                if $fast-type ∈ [$mahadvadashi, $viddha] && $masa eq $vishnu 
                    && $paksha eq 'G' {
                        $fast-date = get-yesterday($fast-date);
                }

                say 'Ekadashi name: ' ~ $ekadashi-name;
                say 'Ekadashi purity: ' ~ $purity;
                say 'Ekadashi starts: ' ~ $start;
                say 'Ekadashi ends: ' ~ $end;
                say 'Ekadashi date: ' ~ $date;
                say 'Ekadashi type: ' ~ $ekadashi-type;
                say 'Dvadashi type: ' ~ $dvadashi-type;
                say 'Fast type: '  ~ $fast-type;
                say 'Fast date: ' ~ $fast-date;
                say 'Mahadvadashi name: ' ~ $mahadvadashi-name \ 
                    if $fast-type eq $mahadvadashi; 

# Parans

                my $paran-date = get-tomorrow($fast-date);
                my ($paran-start, $paran-end);
                say 'Paran date: ' ~ $paran-date;
                my $paran-day-sunrise;
                if $city eq $navadvip {
                    $paran-day-sunrise = 
                        %tithi-srss{$paran-date}{'sunrise'};
                }
                if not $paran-day-sunrise {
                    $paran-day-sunrise = 
                        get-city-sunrise($paran-date, $city, %city-srss);
                }
                say 'Paran day sunrise: ' ~ $paran-day-sunrise;
                my $paran-day-sunset;
                if $city eq $navadvip {
                    $paran-day-sunset = %tithi-srss{$paran-date}{'sunset'}
                }
                if not $paran-day-sunset {
                    $paran-day-sunset = get-city-sunset($paran-date, $city, 
                        %city-srss)
                }
                say 'Paran day sunset: ' ~ $paran-day-sunset;

                if $ekadashi-is-pure && $fast-type eq $shuddha && 
                    $fast-date eq $date {
                    ($paran-start, $paran-end) = get-shuddha-paran(
                        $paran-day-sunrise, $paran-day-sunset,
                        $dvadashi-start, $dvadashi-end, $city);
                } 
                elsif $fast-type eq $viddha || $fast-type eq $mahadvadashi &&
                    $mahadvadashi-name ∈ 
                        [$unmilani, $pakshavarddhini, $trisprisha] {
                    say %tithi-by-date{$paran-date};
                    say 'Dvadashi end: ' ~ $dvadashi-end;
                    say 'Trayodashi end: ' ~ $trayodashi-end;
                    ($paran-start, $paran-end) = get-viddha-paran(
                        $paran-day-sunrise, $paran-day-sunset,
                        $dvadashi-end, $trayodashi-end, $city);
               }
               elsif $fast-type eq $mahadvadashi && 
                    $mahadvadashi-name eq $vyanjuli {
                    ($paran-start, $paran-end) = get-vyanjuli-paran(
                        $paran-day-sunrise, $paran-day-sunset, 
                        $dvadashi-start, $dvadashi-end, $city);
               }
               elsif $fast-type eq $mahadvadashi && 
                    $nakshatra-yoga {
                    say 'Dvadashi end: ' ~ $dvadashi-end;
                    say 'Nakshatra end: ' ~ $nakshatra-end;
                    say 'Nakshatra name: ' ~ $nakshatra-name;
                    say 'Trayodashi end: ' ~ $trayodashi-end;
                    ($paran-start, $paran-end) = get-nakshatra-yoga-paran(
                        $paran-day-sunrise, $paran-day-sunset,
                        $dvadashi-end, $nakshatra-end, $nakshatra-name, 
                        $city);
               }
               elsif $fast-type eq $vsy-type {
                    say 'Dvadashi start: ' ~ $dvadashi-start;
                    say 'Dvadashi end: ' ~ $dvadashi-end;
                    say 'Nakshatra end: ' ~ $nakshatra-end;
                    say 'Trayodashi end: ' ~ $trayodashi-end;
                    my $yoga-type = $dvadashi-type eq $kshaya ?? 2 !! 1;
                    say 'Vishnu-shrinkhala-yoga type: ' ~ $yoga-type;
                    ($paran-start, $paran-end) = 
                        get-vishnu-shrinkhala-yoga-paran($paran-day-sunrise, 
                        $paran-day-sunset, $dvadashi-end, $nakshatra-end, 
                        $trayodashi-end, $yoga-type, $city);
               }
               say 'Paran start: ' ~ $paran-start;
               say 'Paran end: ' ~ $paran-end;

                # putting everything about ekadashi into map

                %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha}{'fast-date'} = 
                    $fast-date;
                %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha}{'fast-type'} = 
                    $fast-type;
                %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha}{'paran-date'} = 
                    $paran-date;
        %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha}{'mahadvadashi-name'} = 
                    $mahadvadashi-name;
                %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha}{'is-vsy'}= 
                    $vishnu-shrinkhala-yoga-test;
                %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha}{'paran-start'} =
                    $paran-start;
                %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha}{'paran-end'} =
                    $paran-end;
                %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha}{'name'} =
                    $slug;
                say 'Ekadashi info:';
                say %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha};
            }
        }
    }

# Puting masas titles in dates structure

    my %masa-titles-map = get-masa-titles-map();

# detecting purushottam

    my $purushottam-index = 0;
    my Bool $purushottam-founded = False;
    while $purushottam-index < @masas-list.elems && not $purushottam-founded {
        my $masa-name = @masas-list[$purushottam-index];
        $purushottam-founded = $masa-name eq $purushottam;
        $purushottam-index++ if not $purushottam-founded;
    }

    say 'Index of Purushottam: ' ~ $purushottam-index if $purushottam-founded;
    my $masa-before-purushottam = $purushottam-founded ?? 
        @masas-list[$purushottam-index - 1] !! '';


    my $y = $year-1;
    my (@pakshas, @tithi-list);

    loop ($i = 0; $i < @masas-list.elems; $i++) {

    # makikg masas list

        my $masa = @masas-list[$i];
        $y++ if $masa eq $vishnu;
        if $purushottam-founded && $masa eq $masa-before-purushottam
            && $i < $purushottam-index {
            @tithi-list = %tithi-names{'K'}.List;
            @pakshas = ['K'];
        }
        elsif $purushottam-founded && $masa eq $masa-before-purushottam
            && $i > $purushottam-index {
                @tithi-list = %tithi-names{'G'}.List;
                @pakshas = ['G'];
        }
        elsif $purushottam-founded && $masa eq $purushottam {
            @tithi-list = (%tithi-names{'G'}.List,
                %tithi-names{'K'}.List).flat;
            @pakshas = ['G', 'K'];
        }
        else {
            @tithi-list = (%tithi-names{'K'}.List,
                %tithi-names{'G'}.List).flat;
            @pakshas = ['K', 'G'];
        }

    say 'Putting events';

    # putting events

        loop (my $j = 0; $j < @pakshas.elems; $j++) {
            my $paksha = @pakshas[$j];
            my @indexes = $j == 0 ?? [0..14].List !! [15..29].List;
            for @indexes -> $index {
               my $tithi = @tithi-list[$index];
                if %events{$masa}{$tithi}{$paksha} {
                    my %e = %events{$masa}{$tithi}{$paksha};
                        next if not \
                        %tithi-map-navadvip{$y}{$masa}{$tithi}{$paksha}:exists;
                    my %t = %tithi-map-navadvip{$y}{$masa}{$tithi}{$paksha};
                    say '';

# forming line

                    my $slug = %e{'slug'};
                    my $ru-event = %e{'ru'};
                    my $en-event = %e{'en'};
                    my ($sunrise, $sunset, $forenoon);
                    my %m = %tithi-map-city{$y};

                    if $slug eq $gaura-purnima {
                        $ru-event = sprintf($ru-event, $y);
                        $en-event = sprintf($en-event, $y);
                    }
                    elsif $slug eq $gaura-purnima-paran {
                        $sunrise = %m{$vishnu}{$pratipad}{'K'}{'end-sunrise'};
                        $sunset = %m{$vishnu}{$pratipad}{'K'}{'end-sunset'};
                        $forenoon = get-forenoon($sunrise, $sunset, $city-tz);
                        $ru-event = sprintf($ru-event, $sunrise.words[1],
                            $forenoon.words[1], $acc, $y);
                        $en-event = sprintf($en-event, $sunrise.words[1],
                            $forenoon.words[1], $city-name, $y);
                    }
                    elsif $slug eq $nrisimha-chaturdashi-paran {
                        $sunrise =
                            %m{$madhusudan}{$purnima}{'G'}{'end-sunrise'};
                        $sunset =
                            %m{$madhusudan}{$purnima}{'G'}{'end-sunset'};
                        $forenoon = get-forenoon($sunrise, $sunset, $city-tz);
                        $ru-event = sprintf($ru-event, $sunrise.words[1], 
                            $forenoon.words[1], $acc);
                        $en-event = sprintf($en-event, $sunrise.words[1],
                            $forenoon.words[1], $city-name);
                    }
                    elsif $slug eq $janmashtami-paran {
                        $sunrise=%m{$hrishikesh}{$navami}{'K'}{'end-sunrise'};
                        $sunset = %m{$hrishikesh}{$navami}{'K'}{'end-sunset'};
                        $forenoon = get-forenoon($sunrise, $sunset, $city-tz);
                        $ru-event = sprintf($ru-event, $sunrise.words[1], 
                            $forenoon.words[1], $acc);
                        $en-event = sprintf($en-event, $sunrise.words[1],
                            $forenoon.words[1], $city-name);
                    }
                    elsif $slug eq $shridhar-maharaj-appearance {
                        $sunrise = %m{$damodar}{$navami}{'K'}{'end-sunrise'};
                        my $a = get-appearance-year($sunrise, 
                            $shridhar-maharaj-birth-year);
                        $ru-event = sprintf($ru-event, $a);
                        $en-event = sprintf($en-event, $a);
                    }
                    elsif $slug eq $govardhana-puja {
                        my $end = %m{$damodar}{$pratipad}{'G'}{'end'};
                        $ru-event = sprintf($ru-event, $end.words[1]);
                        $en-event = sprintf($en-event, $end.words[1]);
                    }
                    elsif $slug eq $gurudev-appearance {
                        $sunrise = %m{$narayan}{$dvitiya}{'K'}{'end-sunrise'};
                        my $a = get-appearance-year($sunrise, 
                            $gurudev-birth-year);
                        $ru-event = sprintf($ru-event, $a);
                        $en-event = sprintf($en-event, $a);
                    }
                    elsif $slug eq $sarasvati-thakur-appearance {
                        $sunrise =
                            %m{$govinda}{$panchami}{'K'}{'end-sunrise'};
                        my $a = get-appearance-year($sunrise, 
                            $sarasvati-thakur-birth-year);
                        $ru-event = sprintf($ru-event, $a);
                        $en-event = sprintf($en-event, $a);
                    }

                    say 'Rus line: ' ~ $ru-event;
                    say 'Eng line: ' ~ $en-event;
                    say 'Year: ' ~ $y;
                    my $date = %t{'date'};
                    my $type = %t{'type'};
                    my $purity = %t{'purity'};
                    say 'Date: ' ~ $date;
                    say 'Type: ' ~ $type;
                    say 'Purity: ' ~ $purity;

                    if $type eq $kshaya {
                        $ru-event = $ru-event.chop ~ sprintf($ru-kshaya, 
                            %tithi-titles{$tithi}{'ru'}.lc);
                        $en-event = $en-event ~ sprintf($en-kshaya,
                            $tithi);

                        if $tithi eq $navami { #special case
                            my $prev-date = get-yesterday($date);
                            add-event($prev-date, %calendar, $en-event,
                                $ru-event);
                        }
                    }
                    add-event($date, %calendar, $en-event, $ru-event);

                    if $type eq $kshaya {
                        my %h = %tithi-by-date{$date}{$shuddha};
                        $masa = %h{'masa'};
                        $paksha = %h{'paksha'};
                        $tithi = %h{'tithi'};
                    }
                    my $ru-tithi-title = %tithi-titles{$tithi}{'ru'};
                    my $en-tithi-title = %tithi-titles{$tithi}{'en'};
                    if $tithi ne $purnima && $tithi ne $amavasya {
                        $en-tithi-title = %pakshas{$paksha}{'en'} ~ ' ' ~
                            $en-tithi-title;
                        $ru-tithi-title = %pakshas{$paksha}{'ru'} ~ ' ' ~
                            $ru-tithi-title;
                    }
                    %calendar{$date}{'ru-tithi-title'} = $ru-tithi-title;
                    %calendar{$date}{'en-tithi-title'} = $en-tithi-title;
                    %calendar{$date}{'ru-date-info'} = 
                        get-date-info($date, 'ru');
                    %calendar{$date}{'en-date-info'} = 
                        get-date-info($date, 'en');

                }
            }
        }
    }


# adding parikrama dates

    for [$year - 1, $year] -> $y {
        my $gaura-purnima-date = %gaurabda-years{$y}{'end'};
        my Str $adhivas-date = 
        Str(Date.new($gaura-purnima-date).earlier: :5days);
        my $first-day = get-tomorrow($adhivas-date);
        my $second-day = get-tomorrow($first-day);
        my $third-day = get-tomorrow($second-day);
        my $fourth-day = get-tomorrow($third-day);
add-parikrama-day($adhivas-date, %calendar, $parikrama-adhivas, 'en');
add-parikrama-day($adhivas-date, %calendar, $parikrama-adhivas-ru, 'ru');
add-parikrama-day($first-day, %calendar, $parikrama-first-day, 'en');
add-parikrama-day($first-day, %calendar, $parikrama-first-day-ru, 'ru');
add-parikrama-day($second-day, %calendar, $parikrama-second-day, 'en');
add-parikrama-day($second-day, %calendar, $parikrama-second-day-ru, 'ru');
add-parikrama-day($third-day, %calendar, $parikrama-third-day, 'en');
add-parikrama-day($third-day, %calendar, $parikrama-third-day-ru, 'ru');
add-parikrama-day($fourth-day, %calendar, $parikrama-fourth-day, 'en');
add-parikrama-day($fourth-day, %calendar, $parikrama-fourth-day-ru, 'ru');
    }

# Ratha Yatra, New Year etc.

    add-dates(%calendar, $year);

# adding ekadashis titles, names and parans info

    my %maha-map = get-mahadvadashis-map();
    for [$year - 1, $year, $year + 1] -> $y {
        for @masas-list.unique -> $masa {
            for <K G> -> $paksha {
                next if not %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha};
                say '';
                say 'Adding ekadashis info:';
                say $y;
                say $masa;
                say $paksha;

                my %t = %tithi-map-city{$y}{$masa}{$ekadashi}{$paksha};
                say "Ekadashi tithi map:";
                say %t;

                my $date = %t{'date'};
                my $name = %t{'name'};
                my $en-name = %ekadashis-map{$masa}{$paksha}{'name'} ~ '.';
                my $ru-name = %ekadashis-map{$masa}{$paksha}{'ru-name'} ~ '.';
                my $type = %t{'type'};
                my $purity = %t{'purity'};
                my $fast-type = %t{'fast-type'};
                my $fast-date = %t{'fast-date'};
                my $paran-date = %t{'paran-date'};
                my $paran-start = %t{'paran-start'};
                my $paran-end = %t{'paran-end'};
                my Bool $is-vsy = %t{'is-vsy'};
                my ($mahadvadashi-name, $en-maha, $ru-maha);
                my $it-is-fast-en-str = sprintf($it-is-fast-en, $city-name);
                my $it-is-fast-ru-str = sprintf($it-is-fast-ru, $acc);
                my $paran-str-en = sprintf($en-paran, $paran-start.words[1], 
                    $paran-end.words[1], $city-name);
                my $paran-str-ru = sprintf($ru-paran, $paran-start.words[1], 
                    $paran-end.words[1], $acc);
                my $is-varaha-dvadashi = $masa eq $madhava && $paksha eq 'G';
                my $is-vamana-dvadashi = $masa eq $hrishikesh && $paksha eq 'G';

                if $purity eq $viddha && $type ne $kshaya &&
                    $fast-type ne $mahadvadashi {
                    add-fast-info($date, %calendar, $no-fast-en, $no-fast-ru);
                    add-fast-info($fast-date, %calendar, 
                    "$en-name $it-is-fast-en-str", "$ru-name $it-is-fast-ru-str");
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }
                elsif $type eq $kshaya && $fast-type ne $mahadvadashi {
                    my $it-is-kshaya-fast-en-str = 
                        sprintf($it-is-kshaya-fast-en,
                    $city-name);
                    my $it-is-kshaya-fast-ru-str = 
                        sprintf($it-is-kshaya-fast-ru,
                    $acc);
                    add-fast-info($fast-date, %calendar, 
                    "$en-name $it-is-kshaya-fast-en-str",
                    "$ru-name $it-is-kshaya-fast-ru-str");
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }
                elsif $fast-type eq $mahadvadashi && $fast-date ne $date
                    && not $is-vsy {
                    $mahadvadashi-name = %t{'mahadvadashi-name'};
                    $en-maha = %maha-map{$mahadvadashi-name}{'en'} ~ '.';
                    $ru-maha = %maha-map{$mahadvadashi-name}{'ru'} ~ '.';
                    if $name eq $nirjala {
                        $en-maha = $en-name ~ ' ' ~ $en-maha;
                        $ru-maha = $ru-name ~ ' ' ~ $ru-maha;
                    }
                    if $mahadvadashi-name ne $trisprisha {
                    add-fast-info($date, %calendar, $no-fast-dvadashi-en, 
                        $no-fast-dvadashi-ru);
                    }
                    add-fast-info($fast-date, %calendar, 
                    "$en-maha $it-is-fast-en-str", "$ru-maha
                    $it-is-fast-ru-str");
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }
                elsif $fast-type eq $mahadvadashi && $fast-date eq $date &&
                    not $is-vsy {
                    $mahadvadashi-name = %t{'mahadvadashi-name'};
                    $en-maha = %maha-map{$mahadvadashi-name}{'en'} ~ '.';
                    $ru-maha = %maha-map{$mahadvadashi-name}{'ru'} ~ '.';
                    if $name eq $nirjala {
                        $en-maha = $en-name ~ ' ' ~ $en-maha;
                        $ru-maha = $ru-name ~ ' ' ~ $ru-maha;
                    }
                    add-fast-info($date, %calendar, 
                    "$en-maha $it-is-fast-en-str", "$ru-maha
                    $it-is-fast-ru-str");
                    if $is-varaha-dvadashi {
                        $paran-str-en = sprintf($en-varaha-paran, 
                        $paran-start.words[1], $paran-end.words[1], 
                        $city-name);
                        $paran-str-ru = sprintf($ru-varaha-paran,
                        $paran-start.words[1], $paran-end.words[1], $acc);
                    }
                    elsif $is-vamana-dvadashi {
                        $paran-str-en = sprintf($en-vamana-paran, 
                        $paran-start.words[1], $paran-end.words[1], 
                        $city-name);
                        $paran-str-ru = sprintf($ru-vamana-paran,
                        $paran-start.words[1], $paran-end.words[1], $acc);
                    }
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }
                elsif $is-vsy && $date eq $fast-date && 
                    $fast-type ne $mahadvadashi {
                    my $en-vsy1-str = sprintf($en-vsy1, $city-name);
                    my $ru-vsy1-str = sprintf($ru-vsy1, $acc);
                    $paran-str-en = sprintf($en-vamana-paran, 
                    $paran-start.words[1], $paran-end.words[1], 
                    $city-name);
                    $paran-str-ru = sprintf($ru-vamana-paran,
                    $paran-start.words[1], $paran-end.words[1], $acc);
                    add-fast-info($date, %calendar, $en-vsy1-str,
                        $ru-vsy1-str);
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }
                elsif $is-vsy && $date eq $fast-date && 
                    $fast-type eq $mahadvadashi {
                    $mahadvadashi-name = %t{'mahadvadashi-name'};
                    $en-maha = %maha-map{$mahadvadashi-name}{'en'} ~ '.';
                    $ru-maha = %maha-map{$mahadvadashi-name}{'ru'} ~ '.';
                    my $en-vsy2-str = sprintf($en-vsy2, $en-maha,
                        $city-name);
                    my $ru-vsy2-str = sprintf($ru-vsy2, $ru-maha, $acc);
                    add-fast-info($date, %calendar, $en-vsy2-str,
                        $ru-vsy2-str);
                    $paran-str-en = sprintf($en-vamana-paran, 
                    $paran-start.words[1], $paran-end.words[1], 
                    $city-name);
                    $paran-str-ru = sprintf($ru-vamana-paran,
                    $paran-start.words[1], $paran-end.words[1], $acc);
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                } 
                elsif $is-vsy && $date ne $fast-date && 
                    $fast-type ne $mahadvadashi {
                    add-fast-info($date, %calendar, $no-fast-vsy-en, 
                        $no-fast-vsy-ru);
                    my $en-vsy3-str = sprintf($en-vsy3, $city-name);
                    my $ru-vsy3-str = sprintf($ru-vsy3, $acc);
                    add-fast-info($fast-date, %calendar, $en-vsy3-str,
                        $ru-vsy3-str);
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }
                elsif $is-vsy && $date ne $fast-date &&
                    $fast-type eq $mahadvadashi {
                    $mahadvadashi-name = %t{'mahadvadashi-name'};
                    $en-maha = %maha-map{$mahadvadashi-name}{'en'} ~ '.';
                    $ru-maha = %maha-map{$mahadvadashi-name}{'ru'} ~ '';
                    my $en-vsy4-str = sprintf($en-vsy4, $en-maha, $city-name);
                    my $ru-vsy4-str = sprintf($ru-vsy4, $ru-maha, $acc);
                    add-fast-info($date, %calendar, $no-fast-vsy-en, 
                        $no-fast-vsy-ru);
                    add-fast-info($fast-date, %calendar, $en-vsy4-str,
                        $ru-vsy4-str);
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }
                elsif $purity eq $shuddha && $date eq $fast-date {
                    add-fast-info($date, %calendar, 
                    "$en-name $it-is-fast-en-str", "$ru-name
                    $it-is-fast-ru-str");
                    if $is-varaha-dvadashi {
                        $paran-str-en = sprintf($en-varaha-paran, 
                        $paran-start.words[1], $paran-end.words[1], 
                        $city-name);
                        $paran-str-ru = sprintf($ru-varaha-paran,
                        $paran-start.words[1], $paran-end.words[1], $acc);
                    }
                    elsif $is-vamana-dvadashi {
                        $paran-str-en = sprintf($en-vamana-paran, 
                        $paran-start.words[1], $paran-end.words[1], 
                        $city-name);
                        $paran-str-ru = sprintf($ru-vamana-paran,
                        $paran-start.words[1], $paran-end.words[1], $acc);
                    }
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }
                else {
                    add-fast-info($fast-date, %calendar, 
                    "$en-name $it-is-fast-en-str", "$ru-name
                    $it-is-fast-ru-str");
                    if $is-varaha-dvadashi {
                        $paran-str-en = sprintf($en-varaha-paran, 
                        $paran-start.words[1], $paran-end.words[1], 
                        $city-name);
                        $paran-str-ru = sprintf($ru-varaha-paran,
                        $paran-start.words[1], $paran-end.words[1], $acc);
                    }
                    elsif $is-vamana-dvadashi {
                        $paran-str-en = sprintf($en-vamana-paran, 
                        $paran-start.words[1], $paran-end.words[1], 
                        $city-name);
                        $paran-str-ru = sprintf($ru-vamana-paran,
                        $paran-start.words[1], $paran-end.words[1], $acc);
                    }
                    add-fast-info($paran-date, %calendar, $paran-str-en, 
                        $paran-str-ru);
                }

                if $city ne $navadvip {
                    add-ekadashi-info($date, $paksha, $y, %calendar,
                        %tithi-map-city, %tithi-titles);
                    add-ekadashi-info($fast-date, $paksha, $y, %calendar,
                        %tithi-map-city, %tithi-titles);
                    add-ekadashi-info($paran-date, $paksha, $y, %calendar,
                        %tithi-map-city, %tithi-titles);
                }
            }
        }
    }

    # adding tithi titles and date infos

    for %calendar.keys.sort -> $date {
        my $y = $date le %gaurabda-years{$year} ?? $year !! $year + 1;
        if %tithi-by-date{$date}{'shuddha'}.defined {
            my %h = %tithi-by-date{$date}{'shuddha'};
            my $masa = %h{'masa'};
            my $paksha = %h{'paksha'};
            my $tithi = %h{'tithi'};
            my $ru-masa-title = %masa-titles-map{$masa}{'ru'};
            my $en-masa-title = %masa-titles-map{$masa}{'en'};
            my ($en-tithi-title, $ru-tithi-title);
            if $purushottam-founded && 
                $masa eq $masa-before-purushottam && $paksha eq 'K' {
                $ru-masa-title ~= $first-half-ru;
                $en-masa-title ~= $first-half-en;
            }
            elsif $purushottam-founded && 
                $masa eq $masa-before-purushottam && $paksha eq 'G' {
                $ru-masa-title ~= $second-half-ru;
                $en-masa-title ~= $second-half-en;
            }

            %calendar{$date}{'ru-masa-title'} = $ru-masa-title;
            %calendar{$date}{'en-masa-title'} = $en-masa-title;

            if not %calendar{$date}{'en-tithi-title'} {
                $en-tithi-title = %tithi-titles{$tithi}{'en'};
                $ru-tithi-title = %tithi-titles{$tithi}{'ru'};
                if $tithi ne $amavasya && $tithi ne $purnima {
                    $en-tithi-title = %pakshas{$paksha}{'en'} ~ ' ' ~ 
                        $en-tithi-title;
                    $ru-tithi-title = %pakshas{$paksha}{'ru'} ~ ' ' ~ 
                        $ru-tithi-title;
                }
                %calendar{$date}{'en-tithi-title'} = $en-tithi-title;
                %calendar{$date}{'ru-tithi-title'} = $ru-tithi-title;
            }
            if not %calendar{$date}{'en-date-info'} {
                %calendar{$date}{'en-date-info'} = get-date-info($date, 'en');            
                %calendar{$date}{'ru-date-info'} = get-date-info($date, 'ru');            
            }
        }
    }

    for %calendar.keys.sort -> $date {
        say '';
        say $date;
        say %calendar{$date};
    }

# putting to file

"calendars/json/{$city}_$year.json".IO.spurt: to-json %calendar, :sorted-keys;
    "result saved in calendars/json/{$city}_$year.json".say;

    exit 0;
}
