#!/usr/bin/perl -w

# --
# rename-portgroup.pl - Rename Portgroup Name in Distributed Switch
# https://github.com/aleex42/VMware-Automation
# --
# Copyright (C) 2013 Alexander Krogltoh, E-Mail: git <at > krogloth.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;

my %opts = (
        'dvswitch' => {
        type => "=s",
        help => "Name of dvSwitch",
        required => 1,
        },
		  'vlan' => {
		  type => "=i",
		  help => "VLAN-ID",
		  required => 1,
		  },
		  'new_name' => {
  		  type => "=s",
		  help => "New Name for VLAN",
		  required => 1,
		  },
);
Opts::add_options(%opts);

Opts::parse();
Opts::validate();
Util::connect();

my $dvswitch = Opts::get_option('dvswitch');
my $vlan = Opts::get_option('vlan');
my $newname = Opts::get_option('new_name');

my $dvSwitches = Vim::find_entity_views(view_type => 'DistributedVirtualSwitch', filter => {'name' => $dvswitch});

foreach my $dvs (@$dvSwitches) {

	foreach my $dvs (@$dvSwitches) {
		if(defined($dvs->portgroup)) {
	   	my $dvPortgroups = $dvs->portgroup;

			foreach my $dvpg (@$dvPortgroups) {
		
				my $dvpgView = Vim::get_view(mo_ref => $dvpg);
				my $vlan_id = $dvpgView->{'config'}->{'defaultPortConfig'}->{'vlan'}->{'vlanId'};
		
				if($vlan_id eq $vlan){

					my $configVersion = $dvpgView->{'config'}->{'configVersion'};
					my $spec = DVPortgroupConfigSpec->new(name => $newname, configVersion => $configVersion);
					$dvpgView->ReconfigureDVPortgroup_Task(spec => $spec);
					if($@){
						print "Error: " . $@ . "\n";
					} else {
						print $dvpgView->{'name'} . " => " . $newname . "\n";
					}
					
					last;

				}
			}
		}
	}
}

Util::disconnect();
