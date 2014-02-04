#!/usr/bin/perl -w

# --
# check_vmware_disk_consolidation.pl - Check if VMs need disk consolidation
# --
# Copyright (C) 2013 Alexander Krogltoh, E-Mail: git <at > krogloth.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;

BEGIN {
        unshift ( @INC, "/usr/lib/vmware-vcli/apps/" );
}

use strict;
use warnings;

use FindBin;
use lib "/usr/lib/nagios/plugins";

use utils qw(%ERRORS $TIMEOUT);

use VMware::VIRuntime;
use VMware::VICredStore;
use AppUtil::HostUtil;
use AppUtil::VMUtil;

Opts::parse();

my $host_address = "vcenter.example.org";
my $user = "Administrator";

VMware::VICredStore::init(filename => "/var/lib/nagios/.vmware/credstore/vicredentials.xml");
my $cred_password = VMware::VICredStore::get_password(server => $host_address, username => $user);
VMware::VICredStore::close();

Util::connect("https://" . $host_address, $user, $cred_password);

my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine', properties => ['name','runtime']);

my @needed = ();

foreach my $vm (@$vm_views) {

    my $consolidation_needed = $vm->runtime->consolidationNeeded;
    my $vmname = $vm->name;

    if($consolidation_needed eq "1"){
        unless(grep(/$vmname/, @needed)){
            push(@needed, $vmname);
        }
    }
}

if(@needed){
    my $count = $#needed+1;
    my $message;
    foreach (@needed){
        $message .= $_ . ", ";
    }

    $message =~ s/..$//;

    print "$count VM(s) need disk consolidation:\n";
    print "$message\n";
    exit 2;
} else {
    print "OK - no VMs need disk consolidation\n";
    exit 0;
}

Util::disconnect();
