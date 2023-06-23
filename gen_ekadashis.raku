#!/usr/bin/env raku
use JSON::Fast;

sub MAIN(Str $city, Int $year, Str $locale) {
    my $year1 = 1485 + $year;
    my $year2 = $year1 + 1;
    my @list = 'csv/cities.csv'.IO.lines.grep(*.contains($city));
    my @fields = @list[0].split: ';';
    my $city-name = $locale eq 'ru' ?? @fields[3] !! @fields[0];
    my @ru-months = <Январь Февраль Март Апрель Май Июнь Июль Август Сентябрь
    Октябрь Ноябрь Декабрь>;
    my @en-monts = <January February March April May June July August September
    October November December>;
    my $title = $locale eq 'ru' ??
    "Календарь Шри Чайтанья Сарасват Матха,<br /> {$city-name}" !! "Gaudiya
    Vaishnava calendar for {$city-name}";
    my $subtitle = $locale eq 'ru' ?? "{$year1}/{$year2} год ({$year} эры
    Гаурабда)" !! "{$year1}/{$year2} year ($year year of Gaurabda era)";
    my %calendar = from-json "calendars/json/{$city}_{$year}.json".IO.slurp;
        
    my $out = Q[
<!doctype html>
<html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">] ~ 
        "
        <title>{$title}</title>

        " ~
        Q[<link href="https://fonts.googleapis.com/css?family=Nunito:200,600" rel="stylesheet" type="text/css">
        <link rel="stylesheet" href="../../../css/bootstrap.min.css">
        <style>
            html, body {
                background-color: #fff;
                font-family: 'Nunito', sans-serif;
                font-weight: 200;
                height: 100vh;
                margin: 0;
            }

            .full-height {
                height: 100vh;
            }

            .flex-center {
                align-items: center;
                display: flex;
                justify-content: center;
            }

            .position-ref {
                position: relative;
            }

            .top-right {
                position: absolute;
                right: 10px;
                top: 18px;
            }

            .content {
                text-align: center;
            }

            .title {
                font-size: 84px;
            }

            .links > a {
                color: #636b6f;
                padding: 0 25px;
                font-size: 13px;
                font-weight: 600;
                letter-spacing: .1rem;
                text-decoration: none;
                text-transform: uppercase;
            }

            .m-b-md {
                margin-bottom: 30px;
            }
            b, strong {
                font-weight: 900 !important
            }
        </style>
    </head>] ~ 
    Q[
    <body>
        <div class="container">
            <div class="row">
                <div class="col-1"></div>
                <div class="col-10">
                    <div class="content">] ~ 
"
                    <h1 class='m-3 p-3'>{$title}</h1>
                    <h2 class='display-6'>{$subtitle}</h2>
";

    my $to-home = $locale eq 'ru' ?? 'Домой' !! 'Home';
    my $en-activity = $locale eq 'ru' ?? '' !! 'active';
    my $ru-activity = $locale eq 'ru' ?? 'active' !! '';
    my $en-link = $locale eq 'ru' ?? '../en' !! '#';
    my $ru-link = $locale eq 'ru' ?? '#' !! '../ru';
    my $russian = $locale eq 'ru' ?? 'Русский' !! 'Russian';
    my $home-link = $locale eq 'ru' ?? '/ru' !! '/';
    my $ics-link = "../../../ics/{$city}_{$year}_{$locale}.ics";
    my $ics-feed-link = "../../../ics/{$city}_{$year}_{$locale}.txt";
    my $nav = qq|
    <ul class="nav nav-pills flex-center m-3">
    <li class="nav-item">
    <a class="nav-link" href="{$home-link}">{$to-home}</a>
    </li>
    <li class="nav-iem">
    <a class="nav-link {$en-activity}" href="{$en-link}">English</a>
    </li>
    <li class="nav-iem">
    <a class="nav-link {$ru-activity}" href="{$ru-link}">{$russian}</a>
    </li>
    <li class="nav-item">
    <a class="nav-link" href="{$ics-link}">ical</a>
    </li>
    <li class=nav-iem">
    <a class="nav-link" href="{$ics-feed-link}">ical link</a>
    </li>
    </ul>
    </div>|;

    $out ~= $nav;

    if $locale eq 'en' && $city ne 'navadvip' {
        my $intro = 
        qq|<div class="m-4 p-5 rounded">
            <p class="fs-2">Please, refer to our <a href="http://scsmath.com/events/calendar/index.html">main calendar for dates of festivals and other holydays, as they are same for all our world-wide mission.</a></p>
            </div>|;

        $out ~= $intro;
    }

    my ($head-month, $sun-month, $month-num, $calendar-masa, $current-masa);
    $head-month = '';
    $calendar-masa = '';

    for %calendar.keys.sort -> $date {
        $month-num = Date.new($date).month;
        my $calendar-year = $date.substr: 0..3;
        $sun-month = $locale eq 'ru' ?? @ru-months[$month-num - 1]  !! @en-monts[$month-num - 1];
        if $sun-month ne $head-month {
            $out ~= "
            <h2 class='text-center'><u>{$sun-month} {$calendar-year}</u></h2>
            ";
            $head-month = $sun-month;
        }

        $current-masa = $locale eq 'ru' ?? %calendar{$date}{'ru-masa-title'} !! %calendar{$date}{'en-masa-title'};


        if (not $calendar-masa) || ($current-masa ne $calendar-masa) {
            $calendar-masa = $current-masa;
            $out ~= "
                <h3 class='text-start text-uppercase'>{$calendar-masa}</h3>
            ";
        }

        if %calendar{$date}{"{$locale}-line"} {
            if $locale eq 'ru' || $city eq 'navadvip' {
                $out ~= "<p class='m3 text-start fs-5'>";
                $out ~= %calendar{$date}{"{$locale}-date-info"};
                $out ~= %calendar{$date}{"{$locale}-tithi-title"} ~ '. ';
                $out ~= %calendar{$date}{"{$locale}-line"};
                $out ~= "</p>";
            }
            else {
                my $cline = %calendar{$date}{"en-line"};
                if $cline.contains('<b>Fast</b>') {
                    $out ~= "<p class='m3 text-start fs-5'>";
                    $out ~= %calendar{$date}{"en-date-info"};
                    $out ~= %calendar{$date}{"en-tithi-title"} ~ '. ';
                    $cline .= subst(/ '<b>Fast</b>.'(.*)$ /, '<b>Fast</b>.');
                    $out ~= $cline;
                    $out ~= "</p>";
                }
                if $cline.contains('Paran') {
                    $out ~= "<p class='m3 text-start fs-5'>";
                    $out ~= %calendar{$date}{"en-date-info"};
                    $out ~= %calendar{$date}{"en-tithi-title"} ~ '. ';
                    my $ind = $cline.index('.');
                    $out ~= $cline.substr(0, $ind);
                    $out ~= "</p>";
                }
            }
        };
        # $out ~= " 
        # <p class='m3 text-start fs-5'>
        # " ~ 
        # %calendar{$date}{"{$locale}-date-info"} ~ %calendar{$date}{"{$locale}-tithi-title"} ~ '. ' ~ %calendar{$date}{"{$locale}-line"} ~ 
        # "
        # </p>
        # ";
        }
$out ~= $nav;

$out ~=
Q[
                    </div>
                </div>
                <div class="col-1"></div>
            </div>
        </div>
    </body>
</html>
    ];

my $path = "ekadashis/html/{$city}/{$year}/{$locale}".IO;
mkdir $path if not $path ~~ :d;
($path.Str ~ '/index.html').IO.spurt: $out;
'done.'.say;

}
