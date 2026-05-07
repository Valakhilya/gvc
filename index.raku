#!/usr/bin/env raku

sub sort-key(Str $s --> Str) {
    $s.trans(
        'ã' => 'a',
        'á' => 'a',
        'é' => 'e',
        'ö' => 'o',
        'ó' => 'o',
        'ä' => 'a',
        'ü' => 'u',
        'ł' => 'l',
        'ñ' => 'n',
        'ç' => 'c',
        'Ã' => 'A',
        'Á' => 'A',
        'É' => 'E',
        'Ö' => 'O',
        'Ó' => 'O',
        'Ä' => 'A',
        'Ü' => 'U',
        'Ł' => 'L',
        'Ñ' => 'N',
        'Ç' => 'C'
    ).lc
}

sub search_html(Str $locale --> Str) {
    my $label       = $locale eq 'ru' ?? 'Искать город' !! 'Search by city';
    my $placeholder = $locale eq 'ru'
        ?? 'Начните вводить название города...'
        !! 'Start typing a city name...';

    return '<div class="city-search-wrap">'
        ~ '<label for="city-search" class="city-search-label">' ~ $label ~ '</label>'
        ~ '<input type="text" id="city-search" class="city-search-input" placeholder="' ~ $placeholder ~ '" autocomplete="off">'
        ~ '</div>';
}

sub search_empty_html(Str $locale --> Str) {
    my $text = $locale eq 'ru' ?? 'Ничего не найдено.' !! 'No cities found.';

    return '<div id="city-search-empty" class="city-search-empty">' ~ $text ~ '</div>';
}

sub search_script_html(--> Str) {
    return q:to/HTML/;
<script>
document.addEventListener('DOMContentLoaded', () => {
    const input = document.getElementById('city-search');
    const rows = Array.from(document.querySelectorAll('.cities-table tr'));
    const empty = document.getElementById('city-search-empty');

    if (!input || !rows.length) return;

    const normalize = (s) =>
        s.toLowerCase()
         .normalize('NFD')
         .replace(/[\u0300-\u036f]/g, '');

    input.addEventListener('input', () => {
        const query = normalize(input.value.trim());
        let visibleCount = 0;

        rows.forEach((row) => {
            const cityLink = row.querySelector('.city-link');
            const text = cityLink ? normalize(cityLink.textContent) : '';
            const show = !query || text.includes(query);

            row.style.display = show ? '' : 'none';
            if (show) visibleCount++;
        });

        if (empty) {
            empty.style.display = visibleCount === 0 ? 'block' : 'none';
        }
    });
});
</script>
HTML
}

sub footer_html(Str $locale --> Str) {
    my $en-class = $locale eq 'en' ?? 'current' !! '';
    my $ru-class = $locale eq 'ru' ?? 'current' !! '';

    my $title = $locale eq 'ru'
        ?? 'Гаудия-вайшнавский календарь'
        !! 'Gaudiya Vaishnava Calendar';

    my $ru-label = $locale eq 'ru'
        ?? 'Русский'
        !! 'Russian';

    return
        '<footer class="page-footer">' ~
            '<p class="footer-title">' ~ $title ~ '</p>' ~
            '<p class="footer-links">' ~
                '<a class="' ~ $en-class ~ '" href="/">English</a>' ~
                '<span>·</span>' ~
                '<a class="' ~ $ru-class ~ '" href="/ru">' ~ $ru-label ~ '</a>' ~
            '</p>' ~
        '</footer>';
}

sub MAIN(Int $year, Str $locale) {
    my $year1 = 1485 + $year;
    my $year2 = $year1 + 1;
    my @list = 'csv/cities.csv'.IO.lines;
    my @cities;

    my $title = $locale eq 'ru'
        ?? 'Календарь Шри Чайтанья Сарасват Матха'
        !! 'Gaudiya Vaishnava Calendar';

    my $subtitle = $locale eq 'ru'
        ?? "Города и календарный год {$year1}/{$year2}"
        !! "Cities and calendar year {$year1}/{$year2}";


    for @list -> $line {
        next unless $line.trim.chars;

        my @fields = $line.split(';');
        next unless @fields.elems >= 2;

        my $en-name = @fields[0].trim;
        my $slug    = @fields[1].trim;
        my $ru-name = @fields.elems >= 4 ?? @fields[3].trim !! $en-name;

        next unless $en-name.chars && $slug.chars;

        my $display = $locale eq 'ru' ?? $ru-name !! $en-name;

        @cities.push({
            display => $display,
            slug    => $slug,
            sort    => sort-key($display),
        });
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

    my $rows = '';

    for @cities.sort(*<sort>) -> %city {
        my $current-city = %city<display>;
        my $slug = %city<slug>;

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

        .city-search-wrap {
            padding: 1rem 1.35rem 0;
            background: linear-gradient(to bottom, #fffdfa, #fffaf2);
        }

        .city-search-label {
            display: block;
            margin: 0 0 0.45rem 0;
            color: var(--muted);
            font-size: 0.95rem;
            font-weight: 500;
        }

        .city-search-input {
            width: 100%;
            padding: 0.75rem 0.95rem;
            border: 1px solid #e7dac8;
            border-radius: 12px;
            background: #fff;
            color: var(--ink);
            font-family: 'Inter', sans-serif;
            font-size: 16px;
            outline: none;
            transition: border-color .18s ease, box-shadow .18s ease;
        }

        .city-search-input:focus {
            border-color: #d2b487;
            box-shadow: 0 0 0 4px rgba(176, 141, 87, 0.12);
        }

        .city-search-empty {
            display: none;
            padding: 1rem 1.35rem 1.2rem;
            color: var(--muted);
            font-size: 0.96rem;
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

        .page-footer {
            margin-top: 2.5rem;
            padding-top: 1.1rem;
            border-top: 1px solid var(--line);
            text-align: center;
        }

        .footer-title {
            margin: 0 0 0.35rem 0;
            color: var(--muted);
            font-size: 0.98rem;
            font-weight: 500;
        }

        .footer-links {
            margin: 0;
            font-size: 0.95rem;
            color: var(--muted);
        }

        .footer-links span {
            margin: 0 0.35rem;
            color: #bca98a;
        }

        .footer-links a {
            color: var(--accent-dark);
            text-decoration: none;
        }

        .footer-links a:hover {
            color: #6d512d;
            text-decoration: underline;
        }

        .footer-links a.current {
            color: var(--ink);
            font-weight: 600;
            pointer-events: none;
            cursor: default;
            text-decoration: none;
        }


        @media (max-width: 768px) {
            .page-wrap {
                padding: 1.25rem .75rem 2rem;
            }

            .cities-card-header {
                padding-left: 1rem;
                padding-right: 1rem;
            }

            .cities-table,
            .cities-table tbody,
            .cities-table tr,
            .cities-table td {
                display: block;
                width: 100%;
            }

            .cities-table tr {
                padding: 0.95rem 1rem;
                border-bottom: 1px solid #eee4d5;
                background: transparent !important;
            }

            .cities-table tr:last-child {
                border-bottom: none;
            }

            .cities-table td {
                padding: 0;
                border: 0;
            }

            .city-name-cell {
                width: 100%;
                margin-bottom: 0.55rem;
            }

            .year-link-cell {
                width: 100%;
                text-align: left;
                white-space: normal;
            }

            .city-link {
                font-size: 1.25rem;
                line-height: 1.2;
            }

            .year-link {
                font-size: .9rem;
                padding: 0.5rem 0.85rem;
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

            __SEARCH__

            <table class="cities-table">
                __ROWS__
            </table>

            __SEARCH_EMPTY__
        </section>

            __FOOTER__
    </div>
    __SEARCH_SCRIPT__
</body>
</html>
HTML

    my $out = $template;
    my $search_html = search_html($locale);
    my $search_empty_html = search_empty_html($locale);
    my $search_script_html = search_script_html();
    my $footer_html = footer_html($locale);
    $out ~~ s:g/__LOCALE__/$locale/;
    $out ~~ s:g/__TITLE__/$title/;
    $out ~~ s:g/__SUBTITLE__/$subtitle/;
    $out ~~ s:g/__NAV__/$nav/;
    $out ~~ s:g/__CARD_TITLE__/$card-title/;
    $out ~~ s:g/__CARD_NOTE__/$card-note/;
    $out ~~ s:g/__SEARCH__/$search_html/;
    $out ~~ s:g/__SEARCH_EMPTY__/$search_empty_html/;
    $out ~~ s:g/__SEARCH_SCRIPT__/$search_script_html/;
    $out ~~ s:g/__ROWS__/$rows/;
    $out ~~ s:g/__FOOTER__/$footer_html/;

    my $path = $locale eq 'ru' ?? 'ekadashis/html/ru'.IO !! 'ekadashis/html'.IO;
    mkdir $path if not $path ~~ :d;
    ($path.Str ~ '/index.html').IO.spurt($out);
    say "Result saved to {$path}";
    'done.'.say;
}
