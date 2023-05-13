#!/usr/bin/env raku
use JSON::Fast;

my %output;
my $year = 538;
my $year1 = 1485 + $year;
my $year2 = $year1 + 1;
my $subtitle = "{$year1}/{$year2} год ({$year} эры Гаурабда)";
my @cities-list = 'csv/cities.csv'.IO.lines;
my @ru-months = <Январь Февраль Март Апрель Май Июнь Июль Август Сентябрь Октябрь Ноябрь Декабрь>;
@cities-list.shift;
for @cities-list -> $line {
    my @fields = $line.split: ';';
    my $slug = @fields[1];
    my $path = "calendars/json/{$slug}_{$year}.json";
    my $city-name = @fields[3];
    my %calendar = from-json slurp($path);
    my $title = "Календарь Шри Чайтанья Сарасват Матха, {$city-name}";
    %output{$slug}{'city-title'} = $title;
    %output{$slug}{'city-subtitle'} = $subtitle;
    %output{$slug}{'city-name'} = $city-name;
    say $city-name;
    for %calendar.keys.sort -> $date {
        my $ru-date-info = %calendar{$date}{'ru-date-info'};
        my $ru-tithi-title = %calendar{$date}{'ru-tithi-title'};
        my $ru-line = %calendar{$date}{'ru-line'};
        my $ru-masa-title = %calendar{$date}{'ru-masa-title'};
        if $ru-line {
            my $item = sprintf("%s%s. %s", $ru-date-info, $ru-tithi-title, $ru-line);
            my $month-num = $date.substr(5..6).Int - 1;
            my $ru-month-name = @ru-months[$month-num]; 
            %output{$slug}{'entries'}{$date}{'month'} = $ru-month-name;
            %output{$slug}{'entries'}{$date}{'masa'} = $ru-masa-title;
            %output{$slug}{'entries'}{$date}{'item'} = $item
        }
    }
}

my $output-filename = "ru_json_{$year}.json";
$output-filename.IO.spurt: to-json %output, :sorted-keys;
'done.'.say;

