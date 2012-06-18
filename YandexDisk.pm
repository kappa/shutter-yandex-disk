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
 
use lib $ENV{'SHUTTER_ROOT'}.'/share/shutter/resources/modules';
 
use utf8;
use strict;
use POSIX qw/setlocale/;
use Locale::gettext;
use Glib qw/TRUE FALSE/;
 
use Shutter::Upload::Shared;
our @ISA = qw(Shutter::Upload::Shared);
 
my $d = Locale::gettext->domain("shutter-upload-plugins");
$d->dir( $ENV{'SHUTTER_INTL'} );
 
my %upload_plugin_info = (
    'module'                        => "YandexDisk",
    'url'                           => "https://mail.yandex.com/neo2/#disk",
    'registration'                  => "http://disk.yandex.ru/",
    'description'                   => $d->get("Upload screenshots to Yandex.Disk"),
    'supports_anonymous_upload'     => FALSE,
    'supports_authorized_upload'    => TRUE,
);
 
binmode( STDOUT, ":utf8" );
if ( exists $upload_plugin_info{$ARGV[ 0 ]} ) {
    print $upload_plugin_info{$ARGV[ 0 ]};
    exit;
}
 
 
sub new {
    my $class = shift;
 
    #call constructor of super class (host, debug_cparam, shutter_root, gettext_object, main_gtk_window, ua)
    my $self = $class->SUPER::new( shift, shift, shift, shift, shift, shift );
 
    bless $self, $class;
    return $self;
}
 
sub init {
    my $self = shift;
 
    use HTTP::DAV;
     
    return TRUE;    
}
 
sub upload {
    my ( $self, $upload_filename, $username, $password ) = @_;
 
    #store as object vars
    $self->{_filename} = $upload_filename;
    $self->{_username} = $username;
    $self->{_password} = $password;
 
    utf8::encode $upload_filename;
    utf8::encode $password;
    utf8::encode $username;
 
    #examples related to the sub 'init'
    my $webdav = HTTP::DAV->new;
    my $url = 'https://webdav.yandex.ru';
 
    eval{
        $webdav->credentials(
            -user   => $username,
            -pass   => $password,
            -url    => $url,
        );
        unless ($webdav->open(-url => $url)) {
            $self->{_links}{status} = 999;
            return;
        }
    };
    if($@){
        $self->{_links}{'status'} = $@;
        return %{ $self->{_links} };
    }
    if($self->{_links}{'status'} == 999){
        return %{ $self->{_links} };
    }
     
    #upload the file
    eval{
        if (!$webdav->cwd('Screenshots')) {
            $webdav->mkcol('Screenshots')
                and $webdav->cwd('Screenshots')
                    or die "Cannot open Screenshots directory\n";
        }
        $webdav->put($upload_filename)
            or die "Cannot upload to Screenshots";
         
        $self->{_links}->{'direct_link'} = 'https://mail.yandex.com/neo2/#disk/disk/Screenshots';
 
        #set success code (200)
        $self->{_links}{'status'} = 200;
         
    };
    if($@){
        $self->{_links}{'status'} = $@;
    }
     
    #and return links
    return %{ $self->{_links} };
}
 
1;
