unit module DateTimeUtils;
use Config;
use Data;
use Constants;
use Structures;

sub make-date(Str $date) is export {
    my @parts = $date.split('-');
    return Date.new(
        <day> => @parts[2],
        <month> => @parts[1],
        <year> => @parts[0]
    );
}

sub datetime-to-str(DateTime $dt) is export {
    return $dt.yyyy-mm-dd ~ ' ' ~ $dt.hh-mm-ss.chop(3);
}

sub datetime-from-str($str, $tz) {
    my ($y, $m, $d, $hh, $mm);
    ($y, $m, $d) = $str.words[0].split: '-';
    ($hh, $mm) = $str.words[1].split: ':';
    return make-datetime($y, $m, $d, $hh, $mm, $tz);
}

sub special-city($city --> Bool) {
    return $city eq $sukhum;
}

sub one-hour-back($datetime-str, $tz) is export {
    my DateTime $dt;
    $dt = datetime-from-str($datetime-str, $tz);
    $dt .= earlier: :1hour;
    return datetime-to-str($dt);
}

sub get-tomorrow(Str $date) is export {
    return Date.new($date).succ.Str;
}

sub get-yesterday(Str $date) is export {
    return Date.new($date).pred.Str;
}

sub get-arunoday(Str $datetime, Int $tz = $india-tz) is export {
    return '' unless $datetime;

    my Str ($srunoday-date, $srunoday-time);
    my DateTime $arunoday-dt;
    my Str ($y, $m, $d, $hh, $mm);

    ($srunoday-date, $srunoday-time) = $datetime.words;
    ($y, $m, $d) = $srunoday-date.split('-');
    ($hh, $mm) = $srunoday-time.split(':');
    $arunoday-dt = make-datetime($y, $m, $d, $hh, $mm, $tz);
    $arunoday-dt .= earlier(:96minutes);
    return $arunoday-dt.yyyy-mm-dd ~ ' ' ~ $arunoday-dt.hh-mm-ss.chop(3);
}

sub get-srss-line($city, $date) is export {
    my @result;
    my @source;
    my $year = $date.substr(0..3);

    @source = "./srss/{$city}_{$year}.csv".IO.lines;
    @result = @source.grep(*.contains($date));
    return @result[0];
}

sub get-city-sunrise($date, $city, %map) is export {
    my $tz = tz($city);
    my $sunrise = %map{$date}{'sunrise'} ?? %map{$date}{'sunrise'} !! '';
    if $sunrise && special-city($city) {
        $sunrise = one-hour-back($sunrise, $tz);
    }
    return $sunrise;
}

sub get-city-sunset($date, $city, %map) is export {
    my $tz = tz($city);
    my $sunset = %map{$date}{'sunset'} ?? %map{$date}{'sunset'} !! '';
    if $sunset && special-city($city)  {
        $sunset = one-hour-back($sunset, $tz);
    }
    return $sunset;
}

sub make-datetime($y, $m, $d, $hh, $mm, $tz) is export {
    return DateTime.new(
        year => $y,
        month => $m,
        day => $d,
        hour => $hh,
        minute => $mm,
        timezone => $tz
    );
}

sub get-dst-data($city, $year) is export {
    my $dst-times = "csv/dst.csv";
    my $line = $dst-times.IO.lines.grep(*.contains("$city;$year"))[0];
    my %data;
    my @parts = $line.split: $delimeter;
    %data{'dst1-start'} = @parts[2];
    %data{'dst1-end'} = @parts[3];
    %data{'dst2-start'} = @parts[4];
    %data{'dst2-end'} = @parts[5];
    return %data;
}

sub local-time-zone($datetime, $city, $year) is export {
    my Bool $dst-offset;
    my DateTime $dt;
    my $tz = tz($city);
    my %dst = get-dst-data($city, $year);
    my ($y, $m, $d) = $datetime.words[0].split: '-';
    my ($hh, $mm) = $datetime.words[1].split: ':';

    $dt = make-datetime($y, $m, $d, $hh, $mm, $india-tz);
    $dt .= in-timezone($tz) unless $tz == $india-tz;
# dst
    if (%dst{'dst1-start'}) {
        $dst-offset = %dst{'dst1-start'} le $dt.yyyy-mm-dd 
            le %dst{'dst1-end'} ||
            %dst{'dst2-start'} le $dt.yyyy-mm-dd le %dst{'dst2-end'};
        $dt .= later: :1hour if $dst-offset;
    }
    return $dt.yyyy-mm-dd ~ ' ' ~ $dt.hh-mm-ss.chop(3);
}

sub parse-tithi-line($line) is export {

############################################
# 0 -- masa                                #
# 1 -- tithi slug                          #
# 2 -- paksha one letter G of K            #
# 3 -- date in yyyy-mm-dd format           #
# 4 -- time of tithi end in H:mm format    #
# 5 -- sunrise time in H:mm format         #
# 6 -- sunset time in H:mm format          #
############################################

    my ($masa, $slug, $paksha, $date, $time, $sunrise-time, $sunset-time) = 
        $line.split: $delimeter;
    die ($masa, $slug, $paksha, $date, $time, $sunrise-time, $sunset-time) \
        unless $sunrise-time;

    my ($y, $m, $d) = $date.split: '-';
    my ($hh, $mm) = $time.split: ':';
    my ($sunrise-hh, $sunrise-mm) = $sunrise-time.split: ':';
    my ($sunset-hh, $sunset-mm) = $sunset-time.split: ':' if $sunset-time;

    my $tithi-end = sprintf('%s %02d:%02d', $date, $hh, $mm);
    my $sunrise = sprintf('%s %02d:%02d', $date, $sunrise-hh, $sunrise-mm);
    my $sunset = $sunset-time ?? 
        sprintf('%s %02d:%02d', $date, $sunset-hh, $sunset-mm) !! '';
    return ($masa, $slug, $paksha, $date, $tithi-end, $sunrise, $sunset);
}


sub get-city-srss-map($city, $year) is export {

    # Forming associative array for sunrises in other cities. Take two years -
    # Gregorian year of starting current Gaurabda year and next year

    my $year1 = $gaurabda-start-year + $year;
    my $year2 = $year1 - 1;
    my (@srss, @fields, %data, $date);

    # Merge data for two years in one list

    @srss = "srss/{$city}_{$year2}.csv".IO.lines;
    @srss.append: "srss/{$city}_{$year1}.csv".IO.lines;

#######################################################
# 0 -- date in mm/dd/yyyy format                      #
# 1 -- sunrise time in yyyy-mm-dd hh:mm format        #
# 2 -- sunset time in yyyy-mm-dd hh:mm format         #
#######################################################

    for @srss -> $line {
        @fields = $line.split: $delimeter;
        $date = @fields[1].words[0];
        %data{$date}<sunrise> = @fields[1];
        %data{$date}<sunset> = @fields[2];
    }
    return %data;
}

sub get-current-year($date, $year) is export {
    my $current-year = $date le %gaurabda-years{$year}{'end'} ?? 
        $year.Int !! $year.Int + 1; 
    return $current-year;
}

sub get-nakshatras-map($city, $year) is export {
    my @nakshatras = "csv/nakshatras_$year.csv".IO.lines;
    my ($masa, $tithi, %data, @fields, $start, $end, $name);
    @nakshatras.shift; # skip header
    for @nakshatras -> $line {
        @fields = $line.split: $delimeter;

#####################################################
# 0 -- masa                                         #
# 1 -- tithi                                        #
# 2 -- paksha                                       #
# 3 -- name                                         #
# 4 -- start time in yyyy-mm-dd hh:mm format        #
# 5 -- end time in yyyy-mm-dd hh:mm format          #
#####################################################

        $masa = @fields[0];
        $tithi = @fields[1];
        my $date = @fields[4].words[0];
        my $current-year = get-current-year($date, $year);
        $start = local-time-zone(@fields[4], $city, $year);
        $end = local-time-zone(@fields[5], $city, $year);
        $name = @fields[3];
        %data{$current-year}{$masa}{$tithi}{'start'} = $start;
        %data{$current-year}{$masa}{$tithi}{'end'} = $end;
        %data{$current-year}{$masa}{$tithi}{'name'} = $name;
    }
    return %data;
}

sub get-ekadashis-map() is export {
    my @list = "csv/ekadashis.csv".IO.lines;
    my %map;
    @list.shift; # skip header
    for @list -> $line {
        my ($masa, $paksha, $slug, $name, $ru) =  $line.split: $delimeter;
        %map{$masa}{$paksha}{'slug'} = $slug;
        %map{$masa}{$paksha}{'name'} = $name;
        %map{$masa}{$paksha}{'ru-name'} = $ru;
    }
    return %map;
}

sub get-events-map() is export {
    my %map;
    my @events = 'csv/events.csv'.IO.lines;
    @events.shift; #skip header
    for @events -> $line {
        my ($masa, $tithi, $paksha, $slug, $en, $ru) = 
            $line.split: $delimeter;
        %map{$masa}{$tithi}{$paksha} = (
            'slug' => $slug,
            'en' => $en,
            'ru' => $ru
        );
    }
    return %map;
}

sub get-mahadvadashis-map() is export {
    my %map;
    my @list = 'csv/mahadvadashis.csv'.IO.lines;
    @list.shift; # skip header
    for @list -> $line {
        my ($slug, $en, $ru) = $line.split: $delimeter;
        %map{$slug}{'en'} = $en; 
        %map{$slug}{'ru'} = $ru; 
    }
    return %map;
}

sub get-tithi-names-map() is export {
    my %map;
    my @tithi-names = 'csv/tithis.csv'.IO.lines;
    @tithi-names.shift;
    for @tithi-names -> $line {
        my ($tithi, $paksha, $en, $ru) = $line.split: $delimeter;
        %map{$paksha}.push: $tithi;
    }
    return %map;
}

sub calculate-tithi-date($tithi-start-str, $tithi-end-str,
    $tithi-start-sunrise-str, $next-day-sunrise-str, 
    $end-sunrise, $is-ekadashi) is export {
    my ($date, $type, $purity, $arunoday, $next-day-date);

    $date = $tithi-start-str ?? $tithi-start-str.words[0]
        !! $tithi-end-str.words[0];
    $next-day-date = get-tomorrow($date);
    $type = $shuddha;
    $purity = $shuddha;

    if ($tithi-start-str gt $tithi-start-sunrise-str 
        && $tithi-end-str ge $next-day-sunrise-str) {
        $date = $next-day-date;
    }

    if ($tithi-start-str && ($tithi-start-str le $tithi-start-sunrise-str)) {
        $date = $tithi-start-str.words[0];
    }


    if ($tithi-start-str && $tithi-start-str gt $tithi-start-sunrise-str &&
        $tithi-end-str lt $next-day-sunrise-str) {
        $type = $kshaya;
        say 'Kshaya tithi. Data: ';
        say 'Tithi start: ' ~ $tithi-start-str;
        say 'Tithi end: ' ~ $tithi-end-str;
        say 'Tithi sunrise: ' ~ $tithi-start-sunrise-str;
        say 'Tithi next day sunrise: ' ~ $next-day-sunrise-str;
        $purity = $viddha;
        $date = $next-day-date;
    }

    if ($next-day-sunrise-str && ($tithi-end-str ge $next-day-sunrise-str &&
        $tithi-start-str le $tithi-start-sunrise-str)) {
        $type = $sampurna;
        {$date = $next-day-date;$purity = $shuddha} if $is-ekadashi;
    }

    if ($end-sunrise && $next-day-sunrise-str && 
        $end-sunrise gt $next-day-sunrise-str && 
        $tithi-end-str ge $end-sunrise) {
        $type = $sampurna;
        $date = $is-ekadashi ?? $end-sunrise.words[0] !! $next-day-date;
        $purity = $shuddha if $is-ekadashi;
        }

        my $sunrise-for-arunoday = $tithi-start-str.contains($date) ?? 
            $tithi-start-sunrise-str !! $next-day-sunrise-str;
        $arunoday = get-arunoday($sunrise-for-arunoday);
        $purity = $viddha if $arunoday lt $tithi-start-str;

    return ($date, $type, $purity, $arunoday);
}

sub get-duration($start, $end, $tz) is export {
    my DateTime ($dt-start, $dt-end);
    $dt-start = datetime-from-str($start, $tz);
    $dt-end = datetime-from-str($end, $tz);
    return Int($dt-end - $dt-start);
}

sub duration-to-human-format($duration) is export {
   my Int ($hours, $minutes, $seconds, $rest); 
   $hours = floor($duration / 3600);
   $rest = $duration % 3600;
   $minutes = floor($rest / 60); 
   $seconds = $rest % 60;
   return sprintf "%d h. %d m. %d s.", $hours, $minutes, $seconds;
}

sub get-quarter($start, $end, $tz) is export {
    my DateTime ($start-dt, $end-dt);
    $start-dt = datetime-from-str($start, $tz);
    $end-dt = datetime-from-str($end, $tz);
    my $duration = floor(1/4 * ($end-dt - $start-dt));
    say 'Quarter: ' ~ datetime-to-str($start-dt + Duration.new: $duration);
    return datetime-to-str($start-dt + Duration.new: $duration);
}

sub get-forenoon($sunrise, $sunset, $tz) is export {
    my DateTime ($sunrise-dt, $sunset-dt);
    $sunrise-dt = datetime-from-str($sunrise, $tz);
    $sunset-dt = datetime-from-str($sunset, $tz);
    my $duration = floor(1/3 * ($sunset-dt - $sunrise-dt));
    say 'Forenoon: ' ~ datetime-to-str($sunrise-dt + Duration.new: $duration);
    return datetime-to-str($sunrise-dt + Duration.new: $duration);
}

sub get-date-info($date, $locale) is export {
    my Date $dt;
    $dt = Date.new: $date;
    return sprintf('<b>%s</b>. %s ', $dt.day, 
        %weekdays{$dt.day-of-week}{$locale}); 
}

sub get-masa-titles-map() is export {
    my @list = 'csv/masas.csv'.IO.lines;
    my %map;
    @list.shift; # skip header
    for @list -> $line {
        my ($masa, $en, $ru) = $line.split: $delimeter;
        %map{$masa}{'en'} = $en;
        %map{$masa}{'ru'} = $ru;
    }
    return %map;
}

sub tz(Str $city) is export {
    my @grep = @cities.grep(*.contains($city));
    my @fields = @grep[0].split: $delimeter;
    return (@fields[5].Real * 3600).Int; 
}

sub get-shuddha-paran($dvadashi-sunrise, $dvadashi-sunset,
    $dvadashi-start, $dvadashi-end, $city) is export {
    my ($paran-start, $paran-end);
    my $tz = tz($city);
    my $forenoon = get-forenoon($dvadashi-sunrise, $dvadashi-sunset, $tz);
    my $quarter = get-quarter($dvadashi-start, $dvadashi-end, $tz);
    $paran-start = $quarter ge $dvadashi-sunrise ?? $quarter
        !! $dvadashi-sunrise;
    $paran-end = $dvadashi-end gt $forenoon ?? $forenoon !! $dvadashi-end;
    if $quarter ge $forenoon {
        $paran-start = $quarter;
        $paran-end = $dvadashi-sunset;
    }
    if $quarter ge $dvadashi-sunset {
        $paran-start = $dvadashi-sunrise;
        $paran-end = $dvadashi-sunset;
    }
    return ($paran-start, $paran-end);
}

sub get-viddha-paran($trayodashi-sunrise, $trayodashi-sunset,
    $dvadashi-end, $trayodashi-end, $city) is export {
    my ($paran-start, $paran-end);
    my $tz = tz($city);
    my $forenoon = get-forenoon($trayodashi-sunrise, $trayodashi-sunset, 
        $tz);
    $paran-start = $dvadashi-end gt $trayodashi-sunrise ?? $dvadashi-end
        !! $trayodashi-sunrise;
    $paran-end = $trayodashi-end lt $forenoon ?? $trayodashi-end
        !! $forenoon;
    if $dvadashi-end ge $forenoon {
        $paran-start = $dvadashi-end;
        $paran-end = $trayodashi-sunset;
    }
    if $trayodashi-end le $trayodashi-sunrise {
        $paran-start = $trayodashi-sunrise;
        $paran-end = $forenoon;
    }
    return ($paran-start, $paran-end);
}

sub get-vyanjuli-paran($sunrise, $sunset, $dvadashi-start, $dvadashi-end, 
    $city) is export {
    my ($paran-start, $paran-end);
    my $tz = tz($city);
    my $forenoon = get-forenoon($sunrise, $sunset, $tz);
    $paran-start = $sunrise;
    $paran-end = $dvadashi-end lt $forenoon ?? $dvadashi-end !! $forenoon;
    return ($paran-start, $paran-end);
}

sub get-nakshatra-yoga-paran($sunrise, $sunset, $dvadashi-end, $nakshatra-end, 
    $nakshatra-name, $city) is export {
    my ($paran-start, $paran-end);
    my $tz = tz($city);
    my $forenoon = get-forenoon($sunrise, $sunset, $tz);
    if $dvadashi-end gt $sunrise && $nakshatra-end gt $dvadashi-end {
        $paran-start = $sunrise;
        $paran-end = $dvadashi-end gt $forenoon ?? $forenoon !!
            $dvadashi-end;
    }
    elsif $dvadashi-end gt $sunrise && $nakshatra-end ge $sunrise && 
        $nakshatra-end le $dvadashi-end {
        $paran-start = $nakshatra-end;
        $paran-end = $dvadashi-end gt $forenoon ?? $forenoon !!
            $dvadashi-end;
    }
    elsif $dvadashi-end lt $sunrise && $nakshatra-end gt $sunrise {
        if $nakshatra-name ∈ [$rohini, $shravana] {
            $paran-start = $sunrise;
            $paran-end = $nakshatra-end lt $forenoon ?? $nakshatra-end !!
                $forenoon;
        }
        else {
            $paran-start = $nakshatra-end;
            $paran-end = $nakshatra-end le $forenoon ?? $forenoon !! $sunset;
        }
    }
    elsif $dvadashi-end ge $sunrise && $nakshatra-end le $sunrise {
        $paran-start = $dvadashi-end;
        $paran-end = $dvadashi-end le $forenoon ?? $forenoon !! $sunset;
    }
    else {
        $paran-start = $sunrise;
        $paran-end = $forenoon;
    }
    return ($paran-start, $paran-end);
}

sub get-vishnu-shrinkhala-yoga-paran($sunrise, $sunset, $dvadashi-end, 
    $nakshatra-end, $trayodashi-end, $yoga-type, $city) is export {
    my ($paran-start, $paran-end);
    my $tz = tz($city);
    my $forenoon = get-forenoon($sunrise, $sunset, $tz);

    if $yoga-type == 1 {
        if $dvadashi-end gt $sunrise && $nakshatra-end gt $sunrise {
            if $dvadashi-end gt $nakshatra-end {
                $paran-start = $nakshatra-end;
                $paran-end = $dvadashi-end le $forenoon ?? $dvadashi-end !!
                    $forenoon;
                if $nakshatra-end ge $forenoon {
                    if $nakshatra-end ge $sunset { 
                        $paran-start = $sunrise;
                        $paran-end = $forenoon
                    }
                    else {
                        $paran-start = $nakshatra-end;
                        $paran-end = $dvadashi-end le $sunset ?? 
                            $dvadashi-end !! $sunset;
                    }
                }
            }
            else {
                $paran-start = $sunrise;
                $paran-end = $dvadashi-end le $forenoon ?? $dvadashi-end !!
                    $forenoon;
            }
        }
        elsif $dvadashi-end gt $sunrise {
            $paran-start = $sunrise;
            $paran-end = $dvadashi-end le $forenoon ?? $dvadashi-end !!
                $forenoon;
        }
        else {
            $paran-start = $sunrise;
            $paran-end = $forenoon;
        }
    }
    else #`( $yoga-type == 2) {
        $paran-start = $sunrise;
        $paran-end = $trayodashi-end lt $forenoon ?? $trayodashi-end !!
            $forenoon;
    }
    return($paran-start, $paran-end);
}

sub add-parikrama-day($date, %map, $dataline, $locale) is export {
    my $key = "{$locale}-line";
    my $line = $dataline.lines.join: ' ';
    if not %map{$date}{$key} {
        %map{$date}{$key} = $line
    } 
    else {
        %map{$date}{$key} = $line ~ ' ' ~ %map{$date}{$key};
    }
}

sub add-dates(%map, $year) is export {
    my @list = 'csv/dates.csv'.IO.lines;
    @list.shift; # skip header
    for @list -> $line {
        my ($y, $slug, $date, $en, $ru) = $line.split: $delimeter;
        next unless $y.Int == $year.Int;
        if not %map{$date} {
            %map{$date}{'en-line'} = $en;
            %map{$date}{'ru-line'} = $ru;
        }
        else {
            if $slug ne $punar-yatra {
                %map{$date}{'en-line'} = $en ~ ' ' ~ %map{$date}{'en-line'};
                %map{$date}{'ru-line'} = $ru ~ ' ' ~ %map{$date}{'ru-line'};
            }
            else {
                %map{$date}{'en-line'} = %map{$date}{'en-line'} ~ ' ' ~ $en;
                %map{$date}{'ru-line'} = %map{$date}{'ru-line'} ~ ' ' ~ $ru;
            }
        }
    }
}

sub add-event-line($date, %calendar, $en-event, $ru-event) is export {
    if not %calendar{$date} {
        %calendar{$date}{'en-line'} = $en-event;
        %calendar{$date}{'ru-line'} = $ru-event;
    }
    else {
        %calendar{$date}{'en-line'} = $en-event ~ ' ' ~ 
            %calendar{$date}{'en-line'};
        %calendar{$date}{'ru-line'} = $ru-event ~ ' ' ~ 
            %calendar{$date}{'ru-line'};
    }
}

sub get-appearance-year($sunrise, $birth-year) is export {
    my $year = $sunrise.substr(0..3).Int;
    return $year - $birth-year + 1;
}
