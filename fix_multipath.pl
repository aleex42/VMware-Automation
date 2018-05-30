#!/usr/bin/perl -w

# --
# # fix_multipath.pl - Fix all LUNs to use Round-Robin Multipath
# # https://github.com/aleex42/VMware-Automation
# # --
# # Copyright (C) 2018 Alexander Krogltoh, E-Mail: git <at > krogloth.de
# # --
# # This software comes with ABSOLUTELY NO WARRANTY. For details, see
# # the enclosed file COPYING for license information (GPL). If you
# # did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# # --

use strict;
use warnings;
use 5.010;

use FindBin;
use lib "/usr/lib/vmware-vcli/apps/";

use VMware::VILib;
use VMware::VICredStore;
use FindBin;
use Data::Dumper;
use VMware::VIRuntime;
use AppUtil::HostUtil;
use AppUtil::VMUtil;

Opts::parse();

#######

fix_paths("vcenter01.example.com");

sub fix_paths {

    my $vc = shift;

    connect_vcenter($vc);
    
    my $hosts = Vim::find_entity_views(view_type => 'HostSystem');
    
    foreach my $host (sort{$a->name cmp $b->name} @$hosts) {
    
        my $hostname = $host->name;
        my $storage = $host->configManager->storageSystem;
        my $storage_view = Vim::get_view(mo_ref => $storage);
        my $multipath_info = $storage_view->storageDeviceInfo->multipathInfo->lun;
    
        foreach my $lun (@$multipath_info){
    
            my $lun_id = $lun->id;
            my $type = $lun->storageArrayTypePolicy->policy;
    
            if($type eq "VMW_SATP_LOCAL"){
                next;
            }
    
            my $policy = $lun->policy->policy;
            my $id = $lun->id;
    
            unless($policy eq "VMW_PSP_RR"){
                my $new_policy = HostMultipathInfoLogicalUnitPolicy->new(policy => "VMW_PSP_RR");
                $storage_view->SetMultipathLunPolicy(lunId => $id, policy => $new_policy);
                print "fixed $hostname policy on $lun_id\n";
            }
        }
    }
    
    Util::disconnect();

}       

sub connect_vcenter {

    my $server = shift;

    my $username = 'user@sso';

    VMware::VICredStore::init(filename => "/home/vmware/.vmware/credstore/vicredentials.xml");
    my $password = VMware::VICredStore::get_password(server => $server, username => $username);
    VMware::VICredStore::close();

    Util::connect("https://$server/sdk/webService", $username, $password);
}
