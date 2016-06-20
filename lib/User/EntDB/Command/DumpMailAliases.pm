
package User::EntDB::Command::DumpMailAliases;

use strict;
use warnings;

use User::EntDB;
use User::EntDB::KeyValue;

sub new;
sub do;

sub new {
	my $class = shift;
	my $app = shift;

	my $longhelp = "dumpmailaliases db\n\n"
	. "Dump aliases(5) file from database 'db'.\n\n"
	;

	my $self = {
		'app' => $app,
		'cmdname' => 'dumpmailaliases',
		'shorthelp' =>
		"dumpmailaliases db: dump aliases(5) data from db\n",
		'longhelp' => $longhelp
	};

	bless $self,$class;
	$app->register($self);
	return $self;
}

sub do {
	my $self = shift;
	my $args = shift;
	my $kvargs = {};

	my $dbfname = shift @{$args};
	if(!$dbfname) {
		print $self->{app}->help($self->{cmdname});
		return 0;
	}

	my $kv = User::EntDB::MailAlias->new($kvargs);
	if(!$kv) {
		print STDERR "error: $!\n";
		return 1;
	}

	print "# aliases(5) file\n";
	print "# autogenerated by " .  $self->{app}->{appname}
		. " from $dbfname\n";

	if(!defined($kv->dumpAllKeyValues($dbfname))){
		print STDERR "error: $!\n";
		return 1;
	}

	return 0;

}

1;
