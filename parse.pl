#!/usr/bin/perl5.40

use v5.40;
use Data::Dumper;
use File::Slurp;
use JSON::XS;

my $uas = './uas.txt';
my $socks = '127.0.0.1:9050';
my $year;
my $city;
my $TRIES = 50;
my @timeouts = 3 .. 7;
my $server_restart = "/etc/init.d/tor restart";
my $api = "https://www.drikpanchang.com/dp-api/panchangam/" .
            "dp-surya-siddhanta-panjika.php?" .
            "key=FGHSDD-BENGALI-PANJIKA-778JKS";

sub usage {
    print STDERR "Usage: $0 <city> <year>";
    exit 1;
}

sub already_done {
    my $filename = shift;
    my $last_line = get_last_line($filename);
    return $last_line =~ m/12-31/;
}

sub get_geoname_id {
    my $city = shift;
    my $cities = './csv/cities.csv';

    open my $fh, '<', $cities or die "can not open file $cities";
    my $matched_line = '';
    while (<$fh>) {
        if ($_ =~ /\Q$city\E/){
            $matched_line = $_;
            last;
        }
    } 
    close $fh;
    return '' unless $matched_line;

    my @fields = split /;/, $matched_line;
    return $fields[4];
}

sub get_random_ua {
    use File::Random qw/random_line/;
    my $uafile = './uas.txt';
    return random_line($uafile);
}

sub get_last_line {
    use File::ReadBackwards;

    my $filename = shift;
    my $bw = File::ReadBackwards->new($filename) or 
        die ("Can not open file $filename");
    my $last_line = $bw->readline;
    $bw->close;
    chomp $last_line if defined $last_line;
    return $last_line;
}

sub get_next_date {
    use DateTime;
    use DateTime::Format::Strptime;
    my $line = $_[0];
    my $format = '%d/%m/%Y';

    if ($line =~ m/^\s*$/) {
        return "01/01/${year}";
    }

    my $date_string = substr($line, 0, 10);
    my $strp = DateTime::Format::Strptime->new(
        pattern => $format,
        on_error => 'croak'
    );
    my $dt;
    eval {
        $dt = $strp->parse_datetime($date_string);
    };

    if($@) {
        print STDERR "Error parsing date: $@";
        exit 1;
    };

    my $next_dt = $dt->add(days => 1);
    return $next_dt->strftime($format);
}

sub get_dp_response {
    use WWW::Mechanize;
    use LWP::Protocol::socks;

    my $uri = $_[0];
    my $ua = get_random_ua();
    my $mech = WWW::Mechanize->new();
    $mech->proxy(['http', 'https'], "socks://$socks");
    $mech->agent($ua);
    eval { 
        $mech->get($uri);
    };
    if ($@) {
        print STDERR "Error getting url. Try again...\n ";
        return '';
    }
    if ($mech->status == 200) {
        return $mech->content();
    }
    else {
        print STDERR "Failed to get url \n";
        return '';
    }
}

sub get_appending_line {
    my($date, $sunrise, $sunset) = @_;
    my $conv_date = join '-', reverse(split '/', $date);
    return sprintf("%s;%s %s;%s %s", 
        $date, $conv_date, $sunrise, $conv_date, $sunset);
}

sub wait_a_little() {
    use Data::Random qw(rand_enum);

    my $timeout = rand_enum(\@timeouts);
    sleep($timeout);
}

sub show_title {
    my ($city, $date, $gid) = @_;
    my $title_string = "$city $date";
    say '';
    say "Processing $title_string";
    say '=' x (length($title_string) + 11);
    say '';
}

sub show_intro {
    my ($city, $gid) = @_;
    say 'Starting work with ' . $city;
    say 'I got geoname id as follow: ' . $gid;
}

sub main() {
    if (scalar @ARGV != 2) {
        usage();
    }

    $year = $ARGV[1];
    $city = $ARGV[0];

    my $filename = "./srss/${city}_${year}.csv";

    if (! -e $filename) {
        open my $fh, '>', $filename or die "Cannot create file $filename";
        close $fh;
    }

    my $gid = get_geoname_id($city);
    show_intro($city, $gid);

    MAIN_CYCLE:
    while (not already_done($filename)) {
        my $last_line = get_last_line($filename);
        my $date = get_next_date($last_line);
        show_title($city, $date, $gid);
        my $idx = 1;
        my $result = '';
        while  ((not $result) && $idx < $TRIES) {
            system $server_restart;
            my $uri = "$api&geoname-id=$gid&date=$date&time-format=24hour";
            $result = get_dp_response($uri);
            $idx++;
            wait_a_little();
        }
        if (not $result) {
            print STDERR \
            "not possible to get result from command. STOPPED\n";
            exit 1;
        }
        my $data = decode_json($result);

        if (not defined($data)) {
            next MAIN_CYCLE;
        }

        my $sunrise = $data->{panchangam_data}->{sunrise}[0]->{element_value};
        my $sunset = $data->{panchangam_data}->{sunset}[0]->{element_value};
        my $appending_line = get_appending_line($date, $sunrise, $sunset);
        append_file $filename, $appending_line . "\n";
    }
    say '';
    say 'done.';
}

main();
