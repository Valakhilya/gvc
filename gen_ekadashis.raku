#!/usr/bin/env raku
use JSON::Fast;

sub masa-title-html($masa, Str $locale --> Str) {
    my $title = $masa // '';

    return $title ~ q{, <a target=_blank href="https://scsmath.com/docs/articles/PurusottamExtraMonth.html" style="color: #b08d57; font-weight: 700; text-decoration: none;">the extra month</a>}
        if $locale eq 'en' && $title eq 'Purushottam';

    return $title;
}

sub page-style(--> Str) {
    return q:to/STYLE/;
<style>
    :root {
        --accent: #b08d57;
        --accent-strong: #8a6a3d;
        --accent-soft: #f4ecdf;
        --ink: #2f2a24;
        --muted: #6f6a63;
        --line: #e9dfd0;
        --paper: #fffdf9;
        --card: #ffffff;
    }

    html, body {
        background-color: var(--paper);
        color: #2f2a24;
        font-family: 'Inter', sans-serif;
        font-weight: 400;
        line-height: 1.65;
        margin: 0;
    }

    h1, h2, h3, h4,
    .month-title,
    .masa-title,
    .notice-card h2 {
        font-family: 'Cormorant Garamond', serif;
    }

    .page-shell {
        max-width: 980px;
        margin: 0 auto;
        padding: 1.25rem 1rem 3rem;
    }

    .content {
        text-align: center;
    }

    h1, h2, h3, h4 {
        color: #2a2118;
        letter-spacing: 0.01em;
    }

    .page-title {
        font-size: clamp(2.3rem, 4vw, 4.2rem);
        font-weight: 600;
        line-height: 1.08;
        margin: 1rem 0 0.75rem;
    }

    .page-subtitle {
        font-family: 'Inter', sans-serif;
        font-size: 1.02rem;
        font-weight: 500;
        color: var(--muted);
        letter-spacing: 0.04em;
        text-transform: uppercase;
        margin-bottom: 1.5rem;
    }

    .nav-wrap {
        display: flex;
        justify-content: center;
        margin: 1.25rem 0 1.75rem;
    }

    .nav-pills {
        gap: .4rem;
        padding: .4rem;
        background: rgba(255,255,255,.6);
        border: 1px solid var(--line);
        border-radius: 999px;
        box-shadow: 0 8px 24px rgba(80, 60, 30, 0.04);
    }

    .nav-pills .nav-link {
        color: #5c4a34;
        border-radius: 999px;
        padding: .55rem 1rem;
        font-size: .95rem;
        font-weight: 500;
        transition: all .2s ease;
    }

    .nav-pills .nav-link:hover {
        background: var(--accent-soft);
        color: #3f3121;
    }

    .nav-pills .nav-link.active {
        background: var(--accent);
        color: #fff;
        box-shadow: 0 6px 18px rgba(176, 141, 87, 0.22);
    }

    .notice-card {
        margin: 2rem 0;
        padding: 1.5rem 1.75rem;
        background: var(--card);
        border: 1px solid var(--line);
        border-left: 4px solid var(--accent);
        border-radius: 18px;
        box-shadow: 0 10px 30px rgba(80, 60, 30, 0.06);
        text-align: left;
    }

    .notice-card h2 {
        font-size: 2rem;
        font-weight: 600;
        margin-bottom: .65rem;
    }

    .notice-card p {
        font-size: 1.05rem;
        margin-bottom: .8rem;
        color: #3d352c;
    }

    .notice-card p:last-child {
        margin-bottom: 0;
        color: var(--muted);
    }

    .month-title {
        font-size: 2.25rem;
        font-weight: 600;
        line-height: 1.15;
        margin-top: 2.35rem;
        margin-bottom: .5rem;
        text-align: center;
        border-bottom: 1px solid var(--line);
        padding-bottom: .35rem;
    }

    .masa-title {
        font-size: 1.6rem;
        font-weight: 600;
        text-align: left;
        color: #6a512f;
        margin-top: 1.2rem;
        margin-bottom: .85rem;
        text-transform: none;
    }

    .day-line {
        text-align: left;
        font-size: 1.04rem;
        margin-bottom: .8rem;
        color: var(--ink);
    }

    a {
        color: var(--accent-strong);
        text-decoration: none;
    }

    a:hover {
        color: #6d512d;
        text-decoration: underline;
    }

    b, strong {
        font-weight: 700 !important;
    }

    @media (max-width: 768px) {
        .page-shell {
            padding: 1rem .8rem 2.25rem;
        }

        .page-title {
            margin-top: .5rem;
        }

        .notice-card {
            padding: 1.15rem 1.2rem;
        }

        .month-title {
            font-size: 1.9rem;
        }

        .masa-title {
            font-size: 1.35rem;
        }

        .day-line {
            font-size: 1rem;
        }
    }
</style>
STYLE
}

sub nav-html(Str $locale, Str $city, Int $year --> Str) {
    my $to-home       = $locale eq 'ru' ?? 'Домой' !! 'Home';
    my $en-activity   = $locale eq 'ru' ?? '' !! 'active';
    my $ru-activity   = $locale eq 'ru' ?? 'active' !! '';
    my $en-link       = $locale eq 'ru' ?? '../en' !! '#';
    my $ru-link       = $locale eq 'ru' ?? '#' !! '../ru';
    my $russian       = $locale eq 'ru' ?? 'Русский' !! 'Russian';
    my $home-link     = $locale eq 'ru' ?? '/ru' !! '/';
    my $ics-link      = "../../../ics/{$city}_{$year}_{$locale}.ics";
    my $ics-feed-link = "../../../ics/{$city}_{$year}_{$locale}.txt";

    return qq:to/NAV/;
<div class="nav-wrap">
    <ul class="nav nav-pills">
        <li class="nav-item"><a class="nav-link" href="{$home-link}">{$to-home}</a></li>
        <li class="nav-item"><a class="nav-link {$en-activity}" href="{$en-link}">English</a></li>
        <li class="nav-item"><a class="nav-link {$ru-activity}" href="{$ru-link}">{$russian}</a></li>
        <li class="nav-item"><a class="nav-link" href="{$ics-link}">iCal</a></li>
        <li class="nav-item"><a class="nav-link" href="{$ics-feed-link}">iCal link</a></li>
    </ul>
</div>
NAV
}

sub intro-html(--> Str) {
    return q:to/INTRO/;
<div class="notice-card">
    <h2>Important Notice</h2>
    <p>
        Please refer to our
        <a href="http://scsmath.com/events/calendar/index.html">main calendar</a>
        for festival dates and other holy days, as these are observed uniformly throughout our worldwide mission.
    </p>
    <p>
        <strong>Attention!</strong> Dear Vaiṣṇavas, the calendar was recalculated on March 22, 2026.
        Please update your calendar files (ICS).
    </p>
    <p>
        Our special thanks to <strong>Srila Madhusudan Maharaj</strong> for inspiration
        and <strong>Sadhu Priya Prabhu</strong> for expert assistance!
    </p>
</div>
INTRO
}

sub render-day-line(%entry, Str $locale --> Str) {
    return "<p class='day-line'>"
        ~ (%entry{"{$locale}-date-info"} // '')
        ~ (%entry{"{$locale}-tithi-title"} // '') ~ '. '
        ~ (%entry{"{$locale}-line"} // '')
        ~ "</p>";
}

sub render-filtered-en-line(%entry, Str $city --> Str) {
    my $cline = %entry{'en-line'} // '';
    return '' if $cline eq '';

    my $prefix = (%entry{'en-date-info'} // '') ~ (%entry{'en-tithi-title'} // '') ~ '. ';
    my $text   = '';

    if $cline.contains('<b>Fast</b>') || $cline.contains('Paran') {
        my $right-index = $city eq 'nabadwip' ?? $cline.index(')') + 1 !! $cline.index('(');
        $text = $cline.substr(0, $right-index) ~ '.' if $right-index.defined && $right-index >= 0;
    }

    if $cline.contains('Gaura Purnima paran') {
        my $index = $cline.index('Anandotsav');
        $text = $cline.substr(0, $index - 1) if $index.defined && $index > 0;
    }

    if $cline.contains('Nrisimha Chaturdashi paran') {
        my $index = $cline.index('a.m.');
        $text = $cline.substr(0, $index + 4) if $index.defined && $index >= 0;
    }

    if $cline.contains('Janmashtami paran') {
        my $left-index  = $cline.index('Janmashtami paran');
        my $right-index = $cline.index('a.m.');
        if $left-index.defined && $right-index.defined && $right-index >= $left-index {
            $text = $cline.substr($left-index, $right-index - $left-index + 4);
        }
    }

    return '' if $text eq '';
    return "<p class='day-line'>{$prefix}{$text}</p>";
}

sub render-extra-day-line(Str $date-info, Str $tithi-title, Str $line --> Str) {
    return "<p class='day-line'>{$date-info}{$tithi-title}. {$line}</p>";
}

sub render-extra-note(Str $text --> Str) {
    return "<div class='notice-card'><p>{$text}</p></div>";
}

sub MAIN(Str $city, Int $year, Str $locale) {
    my $year1 = 1485 + $year;
    my $year2 = $year1 + 1;

    my @list = 'csv/cities.csv'.IO.lines.grep(*.contains($city));
    my @fields = @list[0].split: ';';
    my $city-name = $locale eq 'ru' ?? @fields[3] !! @fields[0];

    my @ru-months = <Январь Февраль Март Апрель Май Июнь Июль Август Сентябрь Октябрь Ноябрь Декабрь>;
    my @en-months = <January February March April May June July August September October November December>;

    my $title = $locale eq 'ru'
        ?? "Календарь Шри Чайтанья Сарасват Матха,<br /> {$city-name}"
        !! "Ekadashi Fasting Days and Breaking Fast (<em>paran</em>) Times after Ekadashi and other fasting days for {$city-name}";

    my $subtitle = $locale eq 'ru'
        ?? "{$year1}/{$year2} год ({$year} эры Гаурабда)"
        !! "{$year1}/{$year2} year ({$year} year of Gaurabda era)";

    my %calendar = from-json "calendars/json/{$city}_{$year}.json".IO.slurp;

    my $out = qq:to/HTML/;
<!doctype html>
<html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>{$title}</title>
        <link rel="stylesheet" href="/css/bootstrap.min.css">
        <link rel="stylesheet" href="/css/fonts.css">
        {page-style()}
    </head>
    <body>
        <div class="page-shell">
            <div class="content">
                <h1 class="page-title">{$title}</h1>
                <div class="page-subtitle">{$subtitle}</div>
            </div>
            {nav-html($locale, $city, $year)}
HTML

    if $locale eq 'en' {
        $out ~= intro-html();
    }

    my $head-month = '';
    my $calendar-masa = '';
    my $current-masa = '';

    for %calendar.keys.sort -> $date {
        my $month-num = Date.new($date).month;
        my $calendar-year = $date.substr(0, 4);
        my %entry = %calendar{$date};
        my $line = %entry{"{$locale}-line"} // '';

        next unless %entry{"{$locale}-line"}:exists && $line ne '';

        if $locale eq 'ru' || $city eq 'nabadwip' {
            my $sun-month = $locale eq 'ru' ?? @ru-months[$month-num - 1] !! @en-months[$month-num - 1];

            if $sun-month ne $head-month {
                $out ~= "<h2 class='month-title'>{$sun-month} {$calendar-year}</h2>";
                $head-month = $sun-month;
            }

            $current-masa = $locale eq 'ru'
                ?? (%entry{'ru-masa-title'} // '')
                !! (%entry{'en-masa-title'} // '');

            if $calendar-masa eq '' || $current-masa ne $calendar-masa {
                $calendar-masa = $current-masa;
                $out ~= "<h3 class='masa-title'>{masa-title-html($calendar-masa, $locale)}</h3>";
            }

            $out ~= render-day-line(%entry, $locale);
        }
        else {
            my $cline = %entry{'en-line'} // '';
            my $sun-month = @en-months[$month-num - 1];
            $current-masa = %entry{'en-masa-title'} // '';

            if ($cline ~~ rx{'<b>Fast</b>' | Paran}) && $sun-month ne $head-month && $current-masa ne '' {
                $out ~= "<h2 class='month-title'>{$sun-month} {$calendar-year}</h2>";
                $head-month = $sun-month;
            }

            if $calendar-masa eq '' || $current-masa ne $calendar-masa {
                $calendar-masa = $current-masa;
                $out ~= "<h3 class='masa-title'>{masa-title-html($calendar-masa, $locale)}</h3>";
            }

            $out ~= render-filtered-en-line(%entry, $city);
        }
    }

    if $locale eq 'en' && $year == 541 && $city eq 'nabadwip' {
        $out ~= render-extra-note('The following are expected dates, and can only be confirmed close to Sri Gaura-purnima 2027:');
        $out ~= render-extra-day-line(
            '<b>15.</b> (Tue) ',
            'Gaura Navami',
            '<a href="http://scsmath.com/events/calendar_events/04_Rama-navami.html"><b>Sri Rama Navami.</b></a> <b>Appearance at noon of Sri Ramachandra. Fast until noon.</b>'
        );
        $out ~= render-extra-day-line(
            '<b>17.</b> (Sat) ',
            'Gaura Ekadashi',
            'Kamada <b>Ekadashi. Fast</b> (in Nabadwip).'
        );
        $out ~= render-extra-day-line(
            '<b>18.</b> (Mon) ',
            'Gaura Dvadashi (in Nabadwip)',
            '<a href="http://scsmath.com/events/calendar_events/04_SrilaGovindaMaharaj-disap.html"><b>Festival in honour of the disappearance of Om Vishnupad Paramahamsa Parivrajakacharya-varya Ashtottara-shata-sri Srila Bhakti Sundar Govinda Dev-Goswami Maharaj.</b></a>'
        );
    }

    $out ~= nav-html($locale, $city, $year);
    $out ~= q:to/ENDHTML/;
        </div>
    </body>
</html>
ENDHTML

    my $path = "ekadashis/html/{$city}/{$year}/{$locale}".IO;
    mkdir $path if not $path ~~ :d;
    ($path.Str ~ '/index.html').IO.spurt: $out;
    say "Result saved in " ~ $path.Str ~ '/index.html';
}
