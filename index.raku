#!/usr/bin/env raku

sub MAIN( Int $year, Str $locale) {
    my $year1 = 1485 + $year;
    my $year2 = $year1 + 1;
    my @list = 'csv/cities.csv'.IO.lines;
    my @fields;
    my (%en-cities, %ru-cities);
    my ($current-city, $slug, $en-name, $ru-name);

    my $title = $locale eq 'ru' ??
    "Календарь Шри Чайтанья Сарасват Матха" !! "Gaudiya
    Vaishnava calendar";


    @list.shift;

    for @list -> $line {
        @fields = $line.split: ';';
        $en-name = @fields[0];
        $ru-name = @fields[3];
        $slug = @fields[1];
        %ru-cities{$ru-name} = $slug;
        %en-cities{$en-name} = $slug;
    }
        
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
        <link rel="stylesheet" href="css/bootstrap.min.css">
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
                    <h1 class='mt-3 pt-3'>{$title}</h1>
";

my $en-activity = $locale eq 'ru' ?? '' !! 'active';
my $ru-activity = $locale eq 'ru' ?? 'active' !! '';
my $en-link = $locale eq 'ru' ?? '../' !! '#';
my $ru-link = $locale eq 'ru' ?? '#' !! '/ru';
my $russian = $locale eq 'ru' ?? 'Русский' !! 'Russian';
my $nav = qq|
<ul class="nav nav-pills flex-center m-3">
<li class="nav-iem">
<a class="nav-link {$en-activity}" href="{$en-link}">English</a>
</li>
<li class="nav-iem">
<a class="nav-link {$ru-activity}" href="{$ru-link}">{$russian}</a>
</li>
</ul>
</div>|;

    $out ~= $nav;
    $out ~= qq|<table class="table table-striped table-bordered table-sm">|;
    my %map = $locale eq 'ru' ?? %ru-cities !! %en-cities;
    for %map.keys.sort -> $current-city {
        $slug = %map{$current-city};
        $out ~= qq|
                    <tr>
                        <td class="align-middle pt-2 pb-2 ps-3">
                            <h4>{$current-city}</h4>
                        </td>
                        <td class="align-middle ps-3">
                            <a href="/{$slug}/$year/{$locale}">
                            {$year1}/{$year2}</a>
                        </td>
                    </tr>
                        |;
    }

    $out ~= "</table>";
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

my $path = $locale eq 'ru' ?? "ekadashis/html/ru".IO !! "ekadashis/html".IO;
mkdir $path if not $path ~~ :d;
($path.Str ~ '/index.html').IO.spurt: $out;
'done.'.say;

}
