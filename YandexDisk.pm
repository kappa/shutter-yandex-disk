#! /usr/bin/env perl
###################################################
#
#  Copyright (C) 2012 Alex Kapranoff <alex@kapranoff.ru>
#       and Shutter Team
#
#  This file contains parts of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
###################################################
 
package YandexDisk;
 
use lib "$ENV{SHUTTER_ROOT}/share/shutter/resources/modules";
 
use strict;
use Locale::gettext;
use File::Basename;
use URI::Escape;
use Glib qw/TRUE FALSE/;
 
use parent qw/Shutter::Upload::Shared/;
 
my $d = Locale::gettext->domain("shutter-upload-plugins");
$d->dir($ENV{SHUTTER_INTL});
 
my %upload_plugin_info = (
    module                        => "YandexDisk",
    url                           => "https://mail.yandex.com/neo2/#disk",
    registration                  => "http://disk.yandex.ru/",
    description                   => $d->get("Upload screenshots to Yandex.Disk"),
    supports_anonymous_upload     => FALSE,
    supports_authorized_upload    => TRUE,
);
 
binmode(STDOUT, ":utf8");
if (exists $upload_plugin_info{$ARGV[0]}) {
    print $upload_plugin_info{$ARGV[0]};
}
 
sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    bless $self, $class;
}
 
sub init {
    use HTTP::DAV;

    return TRUE;
}

# conjure up a filename that will not clobber existing files
sub will_not_clobber {
    my ($new_file, @existing) = @_;

    my %existing = map { $_ => 1 } @existing;
    my ($filename, $ext) = split /\./, $new_file;
    my $rv = $new_file;
    my $count = 1;

    while ($existing{$rv}) {
        $rv = "$filename-$count" . ($ext ? ".$ext" : "");
        ++$count;
    }

    return $rv;
}
 
sub upload {
    my ($self, $upload_filename, $username, $password) = @_;
 
    $self->{_filename} = $upload_filename;
    $self->{_username} = $username;
    $self->{_password} = $password;
 
    # convert from characters to octets in-place
    utf8::encode $upload_filename;
    utf8::encode $password;
    utf8::encode $username;
 
    my $webdav = HTTP::DAV->new;
    my $url = 'https://webdav.yandex.ru';
    my $dir = 'Screenshots';
    my $basename = uri_escape(basename($upload_filename));
 
    # this code is strange, but it's taken from Shutter
    # plugin template
    eval{
        $webdav->credentials(
            -user   => $username,
            -pass   => $password,
            -url    => $url,
        );
        unless ($webdav->open(-url => $url)) {
            $self->{_links}{status} = 999;
            die $webdav->message;
        }
    };
    if ($@) {
        $self->{_links}{status} ||= $@;
        return %{ $self->{_links} };
    }
     
    # and this is actual upload code
    eval{
        if (!$webdav->cwd($dir)) {
            $webdav->mkcol($dir)
                and $webdav->cwd($dir)
                    or die "Cannot open $dir directory: " . $webdav->message . "\n";
        }
        my $r = $webdav->propfind("")
            or die "Cannot PROPFIND $dir: " . $webdav->message . "\n";

        # if found anything then try not to clobber
        if ($r->get_resourcelist) {
            $basename = will_not_clobber($basename,
                map { basename($_->get_uri->path) } $r->get_resourcelist->get_resources);
        }

        $webdav->put(-local => $upload_filename, -url => "/$dir/$basename")
            or die "Cannot upload to $dir: " . $webdav->message . "\n";
         
        my $ua = $webdav->get_user_agent;
        my $resp = $ua->post("$url/$dir/$basename?publish");
        $resp->code == 302
            or die "Cannot publish $basename: " . $resp->message . "\n";

        $self->{_links}{direct_link} = $resp->header('Location');
 
        $self->{_links}{status} = 200;
    };
    if ($@) {
        $self->{_links}{status} = $@;
    }
     
    return %{ $self->{_links} };
}
 
1;
