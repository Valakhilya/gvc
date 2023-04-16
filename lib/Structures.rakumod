#!/usr/bin/env raku
unit module Structures;
our %tithi-names is export;
our %months-names is export;
our %months-numbers is export;
our @masas is export;
our %nakshatra-yogas is export;
our %gaurabda-years is export;
our %weekdays is export;
our %pakshas is export;
our %tithi-titles is export;

%tithi-names = (
    'Pratipad' => 'pratipad',
    'Dvitīya' => 'dvitiya',
    'Tṛtīya' => 'tritiya',
    'Chaturthī' => 'chaturti',
    'Pañchamī' => 'panchami',
    'Śaṣṭhī' => 'shashthi',
    'Saptamī' => 'saptami',
    'Aṣṭamī' => 'ashtami',
    'Navamī' => 'navami',
    'Daśamī' => 'dashami',
    'Ekādaśī' => 'ekadashi',
    'Dvādaśī' => 'dvadashi',
    'Trayodaśī' => 'trayodashi',
    'Chaturdaśī' => 'chaturdashi',
    'Amāvasyā' => 'amavasya',
    'Pūrṇimā' => 'purnima'
);

%months-names = (
    'Viṣṇu' => 'vishnu',
    'Madhusūdan' => 'madhusudan',
    'Trivikram' => 'trivikram',
    'Vāman' => 'vaman',
    'Śrīdhar' => 'shridhar',
    'Hṛṣīkeś' => 'hrishikesh',
    'Padmanābha' => 'padmanabha',
    'Dāmodar' => 'damodar',
    'Keśava' => 'keshava',
    'Nārāyaṇ' => 'narayan',
    'Mādhava' => 'madhava',
    'Govinda' => 'govinda',
    'Viṣṇu' => 'vishnu',
    'Puruṣottam' => 'purushottam',
    'Purushottam' => 'purushottam',
    'Start Beng' => 'madhusudan'
);

%months-numbers = (
    'Jan' => '01',
    'Feb' => '02',
    'Mar' => '03',
    'Apr' => '04',
    'May' => '05',
    'Jun' => '06',
    'Jul' => '07',
    'Aug' => '08',
    'Sep' => '09',
    'Oct' => '10',
    'Nov' => '11',
    'Dec' => '12'
);

%nakshatra-yogas = (
    'punarvasu' => 'jaya',
    'shravana'  => 'vijaya',
    'rohini'    => 'jayanti',
    'pushya'    => 'papanashini'
);

@masas = (
    'vishnu',
    'madhusudan',
    'trivikram', 
    'vaman',
    'shridhar',
    'hrishikesh',
    'padmanabha',
    'damodar',
    'keshava',
    'narayan',
    'madhava',
    'govinda',
    'purushottam'
);

%gaurabda-years = (
    538 => {
        'start' => "2023-03-07",
        'end' =>  "2024-03-25"
    }
);

%weekdays = (
    1 => {
        'en' => '(Mon)',
        'ru' => '(Понедельник)'
    },
    2 => {
        'en' => '(Tue)',
        'ru' => '(Вторник)'
    },
    3 => {
        'en' => '(Wed)',
        'ru' => '(Среда)'
    },
    4 => {
        'en' => '(Thu)',
        'ru' => '(Четверг)'
    },
    5 => {
        'en' => '(Fri)',
        'ru' => '(Пятница)'
    },
    6 => {
        'en' => '(Sat)',
        'ru' => '(Суббота)'
    },
    7 => {
        'en' => '(Sun)',
        'ru' => '(Воскресенье)'
    }
);

%pakshas = (
    'K' => {
        'en' => 'Krishna',
        'ru' => 'Кришна'
    },
    'G' => {
        'en' => 'Gaura',
        'ru' => 'Гаура'
    }
);

%tithi-titles = (
    'pratipad' => {
        'en' => 'Pratipad',
        'ru' => 'Пратипад'
    },
    'dvitiya' => {
        'en' => 'Dvitiya',
        'ru' => 'Двития'
    },
    'tritiya' => {
        'en' => 'Tririya',
        'ru' => 'Трития'
    },
    'chaturti' => {
        'en' => 'Chaturthī',
        'ru' => 'Чатурти'
    },
    'panchami' => {
        'en' => 'Panchami',
        'ru' => 'Панчами'
    },
    'shashthi' => {
        'en' => 'Shashthi',
        'ru' => 'Шаштхи'
    },
    'saptami' => {
        'en' => 'Saptamī',
        'ru' => 'Саптами'
    },
    'ashtami' => {
        'en' => 'Ashtami',
        'ru' => 'Аштами'
    },
    'navami' => {
        'en' => 'Navami',
        'ru' => 'Навами'
    },
    'dashami' => {
        'en' => 'Dashami',
        'ru' => 'Дашами'
    },
    'ekadashi' => {
        'en' => 'Ekadashi',
        'ru' => 'Экадаши'
    },
    'dvadashi' => {
        'en' => 'Dvadashi',
        'ru' => 'Двадаши'
    },
    'trayodashi' => {
        'en' => 'Trayodashi',
        'ru' => 'Трайодаши'
    },
    'chaturdashi' => {
        'en' => 'Chaturdashi',
        'ru' => 'Чатурдаши'
    },
    'purnima' => {
        'en' => 'Purnima',
        'ru' => 'Пурнима'
    },
    'amavasya' => {
        'en' => 'Amavasya',
        'ru' => 'Амавасья'
    }
);
