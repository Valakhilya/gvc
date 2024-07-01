#!/usr/bin/env raku
use JSON::Fast;
use UUID::V4;

sub MAIN($city, $year, $locale) {
    my $i = $locale eq 'en' ?? 0 !! 3;
    my @list = 'csv/cities.csv'.IO.lines.grep(*.contains($city));
    my @fields = @list[0].Str.split: ';';
    my $city-name = @fields[$i];   
    my $title = $locale eq 'ru' ??
    "Календарь Шри Чайтанья Сарасват Матха, {$city-name}" !! "Gaudiya
    Vaishnava calendar for {$city-name}";
    my $year1 = 1485 + $year;
    my $year2 = $year1 + 1;
    my ($path, $htmlpage);
    my $subtitle = $locale eq 'ru' ?? 
    "{$year1}/{$year2} год ({$year} эры Гаурабда)" 
    !! "{$year1}/{$year2} year ($year year of Gaurabda era)";
    my %calendar = from-json "calendars/json/{$city}_{$year}.json".IO.slurp;
    my $eol = "\r\n";
    my $ical = "BEGIN:VCALENDAR{$eol}"
    ~ "METHOD:PUBLISH{$eol}"
    ~ "VERSION:2.0{$eol}"
    ~ "X-WR-CALNAME: {$subtitle}{$eol}"
    ~ "PRODID:-//Raku{$eol}"
    ~ "CALSCALE:GREGORIAN{$eol}";
    for %calendar.keys.sort -> $date {
        my $line = %calendar{$date}{"{$locale}-line"};
        if $line {
            my $uuid = uuid-v4();
            my $dtstart = $date.Str.split('-').join('');
            my ($y, $m, $d) = $date.split('-');
            my $dtstamp = DateTime.new($y, $m, $d, 0, 0, 0)
            .Str.subst('-', :g).subst(':', :g);
            my $tomorrow = Date.new($date).succ;
            my $dtend = $tomorrow.Str.split('-').join('');
            $line .= subst(/ '<a' .+? '>' /, :g);
            $line .= subst('</a>', :g);
            $line .= subst('<b>', :g);
            $line .= subst('</b>', :g);
            $line .= subst('<em>', :g);
            $line .= subst('</em>', :g);
            $ical ~= "BEGIN:VEVENT{$eol}";
            $ical ~= "UID:{$uuid}{$eol}";
            $ical ~= "DTSTAMP:{$dtstamp}{$eol}";
            $ical ~= "DTEND;VALUE=DATE:{$dtend}{$eol}";
            $ical ~= "DTSTART;VALUE=DATE:{$dtstart}{$eol}";
            $ical ~= "SUMMARY:" ~ $line ~ $eol;
            $ical ~= "BEGIN:VALARM{$eol}";
            $ical ~= "TRIGGER:-PT3H{$eol}";
            $ical ~= "ACTION:DISPLAY{$eol}";
            $ical ~= "DESCRIPTION:" ~ $line ~ $eol;
            $ical ~= "END:VALARM{$eol}";
            $ical ~= "END:VEVENT{$eol}";
        }
    }
    $ical ~= "END:VCALENDAR";
    $ical .= trim;
    $path = "ekadashis/html/ics".IO;
    mkdir $path if not $path ~~ :d;
    ($path.Str ~ "/{$city}_{$year}_{$locale}.ics").IO.spurt: $ical;
    ($path.Str ~ "/{$city}_{$year}_{$locale}.txt").IO.spurt: $ical;
    'done.'.say;
}
