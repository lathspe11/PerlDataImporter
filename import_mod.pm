use strict;
package PerlDataImporter::import_mod;
#file and directory operations for importer
my $datapath = 'C:\\Users\\djwilli\\Documents\\programs\\data\\';
my $vuedata = 'vuedata.txt';
#New Partition

#Is file there?
sub validFile{
	my $apath = shift;
	#if I can't open the file prnt usage
	if (-f $apath) {
		return 'True';
	} else {
		return '';
	}
}
sub verifyDataFolder{
	unless (-d $datapath or mkdir $datapath){
		die("Unable to create directory $datapath");
	}
}
sub verifydatapath{
	my $mypath = shift;	
	unless (-e $mypath or mkdir $mypath){
		die("Unable to create directory $mypath");
	}
}

#Does Partition exist? make sure
sub ifPartition{
	my $date = shift;
	#print("ifPartition\($date\)");
	#Is date arg valid?
	
	my ($yr,$mnth,$day) = split /-/, $date, 3;
	#Validate date has a partition
	my $newpath = $yr ."\\" . $mnth;
	verifydatapath($datapath.$yr); #Test sub path
	verifydatapath($datapath.$newpath); #Test full partition path
	return $datapath . $newpath;
}
#Get partition name
sub getPartitionName{
	my $date = shift;
	#print "getPartitionName from $date\n";
	#Is date arg valid?	
	my ($yr,$mnth,$day) = split /-/, $date, 3;
	#Validate date has a partition
	my $newpath = $yr ."\\" . $mnth;
	#print "getPartition $date => $newpath\n";
	return $newpath;
}
sub writePartition{
	#Only write entries for date input
	my ($wrtpath,$refwrtDict) = @_;	#date path and pointer to Hash of entries
	
	my $newpath = "$datapath$wrtpath\\$vuedata";
	#print ">write $newpath<\n";
	open (my $f, '>', $newpath) || die "writePartition Failed to open $newpath $!\n";
	#For clarity let's dereference the pointer to the hash
	my %deref = %{$refwrtDict};
	foreach my $pks  (keys %deref){
		#print "$pks = ";
		#foreach my $entry (@{$deref{$pks}}){
		#	print "$entry--";
		#}
		#print "\n";
		my $gotdate = @{$deref{$pks}}[3]; #Date of Record determines the partition path
		my $cmpdt = getPartitionName($gotdate); #simple string transform
		if ($wrtpath eq $cmpdt){ #Explicit match of paths 
			my $outline = join ('|', @{$deref{$pks}});
			print $f "$outline\n";
		}
	}	
	close($f);
}
sub openPartition{
	my $oppath = shift;
	my $newpath = "$datapath$oppath\\$vuedata";
#print "openPartition $oppath \n";
	my %opDict;

	if (validFile($newpath)) {
		open (my $fh, '<', $newpath) || die "OpenPartition Failed to open $newpath $!\n";
		while (my $readOneLine = <$fh>) {
			chomp($readOneLine);
			my @pFields = split /\|/,$readOneLine;
			#TITLE|STB|DATE
			my $akey = join('|',$pFields[1],$pFields[0],$pFields[3]);
			$opDict{$akey} = \@pFields;
		}
		close($fh);
		return \%opDict;
	}
	print "OpenPartition No $newpath\n";
	return '';
}

1;