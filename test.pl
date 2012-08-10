#! /usr/bin/perl
use uni::perl;
use Data::Dump;
use HTTP::DAV;
use Config::Tiny;

my $cfg = Config::Tiny->read('disk.conf')
    or die $!;

$ENV{SHUTTER_ROOT} = '/usr';
require 'YandexDisk.pm';

my $yd = {};

YandexDisk::upload($yd, $ARGV[0], $cfg->{webdav}->{username}, $cfg->{webdav}->{passwd});

dd $yd;
