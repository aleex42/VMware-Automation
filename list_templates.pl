#!/usr/bin/perl -w

# list all VMware templates on vcenter
# 2014-07-30
# alex@noris.net

use strict;
use warnings;

use lib "/usr/lib/vmware-vcli/apps/";

use VMware::VIRuntime;
use VMware::VILib;
use VMware::VICredStore;
use AppUtil::VMUtil;
use AppUtil::HostUtil;

connect_vcenter();

my $vm_views = VMUtils::get_vms ('VirtualMachine');

open(TEMPLATES, ">/tmp/vmware_templates.txt");

foreach (@$vm_views) {

    if($_->summary->config->template eq 1){
        print TEMPLATES $_->name . "\n";
    }
}

close(TEMPLATES);

Util::disconnect();

sub connect_vcenter {

   my $server = "vcenter.example.com";
   my $username = "user";

   VMware::VICredStore::init(filename => "/home/vmware/.vmware/credstore/vicredentials.xml");
   my $password = VMware::VICredStore::get_password(server => $server, username => $username);
   VMware::VICredStore::close();

   Util::connect('https://vcenter.example.com/sdk/webService', $username, $password);

}

