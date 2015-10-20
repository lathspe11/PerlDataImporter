#!C:\Strawberry\perl\bin\perl
use strict;
use warnings; 

#use lib 'C:\Users\djwilli\Documents\GitHub\PerlDataImporter';

#python importer.py 
use PerlDataImporter::import_mod;

my $debugp = 1; 

#should have a configuration set up for these values
my $datapath = 'C:\\Users\\djwilli\\documents\\programs\\data\\';
my $errlog = 'C:\\Users\\djwilli\\programs\\data\\importerrors.txt';
my $importFile = $datapath . 'initdata.txt';

#Every program needs a usage statement to educate users on syntax
sub usageMsg {
	print "you're doing it wrong.\n";
	print "importer.pl [import-file-path]* \n";
}

#easy debug message routine
sub dprintf { #true/null, msg
	if ($debugp){
		print $_[0];
	}
}

#Read the import file and merge with the proper data store files
#I'm assuming the data is validated and I'm not doing typical checks 
sub readImport{
	my $openme = $_[0];
	open (my $f, '<', $openme) || die "Cant open file $openme: $!\n";
	my $header = "STB|TITLE|PROVIDER|DATE|REV|VIEW_TIME";
	my $foundhead = 0;
	my %partdict;
	my %impDict;

	dprintf("Read import data\n");
	while (my $readOneLine = <$f>) {
		chomp($readOneLine);
		#dprintf ("$readOneLine\n");
		if (($foundhead == 0) && ($readOneLine =~ /$header/)){
			#This is a Header line
			$foundhead = 1;
			#dprintf ("got header \n");
		}else{
			my @impFields = split /\|/,$readOneLine;
			#TITLE|STB|DATE
			my $akey = join('|',$impFields[1],$impFields[0],$impFields[3]);
			#print "$akey @impFields\n";
			#insert into hash
			$impDict{$akey} = \@impFields;
			#print join('--',@impFields);
			#process date for partitioning
			my ($yr,$mnth,$day) = split('-',$impFields[3], 3);
			#Validate date has a partition
			my $partnam = $yr."\\".$mnth;
			#Collect the date values to use as partition in associated hash
			
			$partdict{$partnam} += 1; #Save partition locations for data
			if ($partdict{$partnam} == 1){ #On 1st pass 
				my $ppath = PerlDataImporter::import_mod::ifPartition($impFields[3]); 
			}
		}
	}
	#Verify partition
	
	close($f);
	
	#for each partition open the stored list
	#Merge the current list with stored list
	#Overlay today's data file on all hashes
	#write data to partitioned files
	my %allDicts;
	#look at each partition in order
	foreach my $dtpath (sort( keys %partdict)) {
		#Get the data store 
		my $testref = PerlDataImporter::import_mod::openPartition($dtpath);
		if ($testref){
			my %dsdict = %{$testref};
			
			#Copy all partitions into allDicts
			@dsdict{ keys %impDict } = values %impDict;
			PerlDataImporter::import_mod::writePartition($dtpath,\%dsdict);

		}else {
			PerlDataImporter::import_mod::writePartition($dtpath,\%impDict);
		}
		#write the partitioned data for that store
	}	
}			
#do I have a file args to open?
#If not open the test file importFile

my $latest = $ARGV[0];
if (defined $latest) {
	#Open the default 
	print "Open file $latest \n";
	readImport($latest);
}else {
	readImport($importFile);
}

#In a real system we would move the original file aside as history
#storeHist(latest)



print "Program Completed\n";