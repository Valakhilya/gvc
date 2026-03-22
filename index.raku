#!/usr/bin/env raku

sub MAIN(Int $year, Str $locale) {
    my $year1 = 1485 + $year;
    my $year2 = $year1 + 1;
    my @list = 'csv/cities.csv'.IO.lines;
    my @fields;
    my (%en-cities, %ru-cities);
    my ($current-city, $slug, $en-name, $ru-name);

    my $title = $locale eq 'ru'
        ?? 'Календарь Шри Чайтанья Сарасват Матха'
        !! 'Gaudiya Vaishnava Calendar';

    my $subtitle = $locale eq 'ru'
        ?? "Города и календарный год {$year1}/{$year2}"
        !! "Cities and calendar year {$year1}/{$year2}";

    @list.shift;

    for @list -> $line {
        @fields = $line.split(';');
        $en-name = @fields[0];
        $ru-name = @fields[3];
        $slug = @fields[1];
        %ru-cities{$ru-name} = $slug;
        %en-cities{$en-name} = $slug;
    }

    my $en-active = $locale eq 'ru' ?? '' !! 'active';
    my $ru-active = $locale eq 'ru' ?? 'active' !! '';
    my $en-link = $locale eq 'ru' ?? '../' !! '#';
    my $ru-link = $locale eq 'ru' ?? '#' !! '/ru';
    my $russian = $locale eq 'ru' ?? 'Русский' !! 'Russian';

    my $nav = qq:to/NAV/;
<nav class="language-switch">
    <ul class="nav nav-pills justify-content-center">
        <li class="nav-item">
            <a class="nav-link {$en-active}" href="{$en-link}">English</a>
        </li>
        <li class="nav-item">
            <a class="nav-link {$ru-active}" href="{$ru-link}">{$russian}</a>
        </li>
    </ul>
</nav>
NAV

    my %map = $locale eq 'ru' ?? %ru-cities !! %en-cities;
    my $rows = '';

    for %map.keys.sort -> $current-city {
        $slug = %map{$current-city};
        $rows ~= qq:to/ROW/;
<tr>
    <td class="city-name-cell">
        <a class="city-link" href="/{$slug}/{$year}/{$locale}">{$current-city}</a>
    </td>
    <td class="year-link-cell">
        <a class="year-link" href="/{$slug}/{$year}/{$locale}">{$year1}/{$year2}</a>
    </td>
</tr>
ROW
    }

    my $card-title = $locale eq 'ru' ?? 'Выберите город' !! 'Choose a City';
    my $card-note  = $locale eq 'ru'
        ?? 'Откройте календарь для вашего города и текущего года.'
        !! 'Open the calendar for your city and the current year.';

    my $template = q:to/HTML/;
<!doctype html>
<html lang="__LOCALE__">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>__TITLE__</title>
    <link rel="stylesheet" href="/css/bootstrap.min.css">
    <link rel="stylesheet" href="/css/fonts.css">
    <style>
        :root {
            --accent: #b08d57;
            --accent-dark: #8a6a3d;
            --accent-soft: #f5ecdf;
            --paper: #fffdf9;
            --surface: #ffffff;
            --ink: #2f2a24;
            --muted: #6f6a63;
            --line: #e9dfd0;
            --shadow: rgba(80, 60, 30, 0.06);
        }

        html, body {
            background-color: var(--paper);
            color: var(--ink);
            font-family: 'Inter', sans-serif;
            font-weight: 400;
            line-height: 1.65;
            margin: 0;
        }

        body {
            min-height: 100vh;
        }

        a {
            color: var(--accent-dark);
            text-decoration: none;
        }

        a:hover {
            color: #6d512d;
            text-decoration: underline;
        }

        b, strong {
            font-weight: 700 !important;
        }

        .page-wrap {
            max-width: 980px;
            margin: 0 auto;
            padding: 2rem 1rem 3rem;
        }

        .hero {
            text-align: center;
            margin-bottom: 1.5rem;
        }

        .hero h1 {
            font-family: 'Cormorant Garamond', serif;
            font-size: clamp(2.5rem, 4.5vw, 4.4rem);
            font-weight: 600;
            line-height: 1.08;
            letter-spacing: 0.01em;
            color: #2a2118;
            margin: 0.5rem 0 0.6rem;
        }

        .subtitle {
            color: var(--muted);
            font-size: 1rem;
            font-weight: 500;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            margin-bottom: 1.25rem;
        }

        .language-switch {
            margin: 1rem 0 1.75rem;
        }

        .language-switch .nav {
            gap: .4rem;
        }

        .language-switch .nav-link {
            color: #5c4a34;
            border-radius: 999px;
            padding: .55rem 1rem;
            font-weight: 500;
            transition: all .2s ease;
        }

        .language-switch .nav-link:hover {
            background: var(--accent-soft);
            color: #3f3121;
            text-decoration: none;
        }

        .language-switch .nav-link.active {
            background: var(--accent);
            color: #fff;
            box-shadow: 0 6px 18px rgba(176, 141, 87, 0.22);
        }

        .cities-card {
            background: var(--surface);
            border: 1px solid var(--line);
            border-radius: 22px;
            box-shadow: 0 14px 40px var(--shadow);
            overflow: hidden;
        }

        .cities-card-header {
            padding: 1.15rem 1.35rem;
            border-bottom: 1px solid var(--line);
            background: linear-gradient(to bottom, #fffdfa, #fffaf2);
        }

        .cities-card-title {
            font-family: 'Cormorant Garamond', serif;
            font-size: 2rem;
            font-weight: 600;
            color: #2a2118;
            margin: 0;
        }

        .cities-card-note {
            color: var(--muted);
            font-size: .98rem;
            margin: .2rem 0 0;
        }

        .cities-table {
            width: 100%;
            border-collapse: collapse;
        }

        .cities-table tr {
            transition: background-color .18s ease;
        }

        .cities-table tr:nth-child(odd) {
            background-color: #fffdf9;
        }

        .cities-table tr:hover {
            background-color: #fcf6ea;
        }

        .cities-table td {
            padding: 1rem 1.35rem;
            border-bottom: 1px solid #eee4d5;
            vertical-align: middle;
        }

        .cities-table tr:last-child td {
            border-bottom: none;
        }

        .city-name-cell {
            width: 72%;
        }

        .city-link {
            display: inline-block;
            font-family: 'Cormorant Garamond', serif;
            font-size: 1.5rem;
            font-weight: 600;
            color: #2e2419;
            line-height: 1.15;
        }

        .city-link:hover {
            color: var(--accent-dark);
            text-decoration: none;
        }

        .year-link-cell {
            text-align: right;
            white-space: nowrap;
        }

        .year-link {
            display: inline-block;
            padding: .45rem .8rem;
            border-radius: 999px;
            background: #f7efe1;
            color: var(--accent-dark);
            font-size: .95rem;
            font-weight: 600;
            letter-spacing: .03em;
        }

        .year-link:hover {
            background: #efdfbf;
            color: #6d512d;
            text-decoration: none;
        }

        .footer-nav {
            margin-top: 1.5rem;
        }

        @media (max-width: 768px) {
            .page-wrap {
                padding: 1.25rem .75rem 2rem;
            }

            .cities-card-header,
            .cities-table td {
                padding-left: 1rem;
                padding-right: 1rem;
            }

            .city-link {
                font-size: 1.25rem;
            }

            .year-link {
                font-size: .9rem;
            }
        }
    </style>
</head>
<body>
    <div class="page-wrap">
        <header class="hero">
            <h1>__TITLE__</h1>
            <div class="subtitle">__SUBTITLE__</div>
            __NAV__
        </header>

        <section class="cities-card">
            <div class="cities-card-header">
                <h2 class="cities-card-title">__CARD_TITLE__</h2>
                <p class="cities-card-note">__CARD_NOTE__</p>
            </div>

            <table class="cities-table">
                __ROWS__
            </table>
        </section>

        <div class="footer-nav">
            __NAV__
        </div>
    </div>
</body>
</html>
HTML

    my $out = $template;
    $out ~~ s:g/__LOCALE__/$locale/;
    $out ~~ s:g/__TITLE__/$title/;
    $out ~~ s:g/__SUBTITLE__/$subtitle/;
    $out ~~ s:g/__NAV__/$nav/;
    $out ~~ s:g/__CARD_TITLE__/$card-title/;
    $out ~~ s:g/__CARD_NOTE__/$card-note/;
    $out ~~ s:g/__ROWS__/$rows/;

    my $path = $locale eq 'ru' ?? 'ekadashis/html/ru'.IO !! 'ekadashis/html'.IO;
    mkdir $path if not $path ~~ :d;
    ($path.Str ~ '/index.html').IO.spurt($out);
    say "Result saved to {$path}";
    'done.'.say;
}
