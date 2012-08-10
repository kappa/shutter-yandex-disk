#! /usr/bin/perl
use uni::perl;
use Data::Dumper;
use HTTP::DAV;
use Config::Tiny;

my $cfg = Config::Tiny->read('disk.conf')
    or die $!;

binmode(STDOUT, ":utf8");
my $filename = $ARGV[0]
    or die "Usage: $0 <filename>\n";

utf8::decode $filename;

$ENV{SHUTTER_ROOT} = '/usr';
require 'YandexDisk.pm';

my $yd = {};

YandexDisk::upload($yd, $filename, $cfg->{webdav}->{username}, $cfg->{webdav}->{passwd});

print Dumper($yd);
