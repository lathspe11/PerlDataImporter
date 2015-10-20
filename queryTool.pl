#!C:\Strawberry\perl\bin\perl
use strict;
use warnings; 

#python importer.py 
use PerlDataImporter::import_mod;

my $debugp = ''; 
#easy debug message routine
sub dprintf { #true/null, msg
	if ($debugp){
		print $_[0];
	}
}
#Globals section
my $defaultdate = '2014-04-01';
my %colDict = (
	'STB', 0,
	'TITLE', 1,
	'PROVIDER', 2,
	'DATE', 3,
	'REV', 4,
	'VIEW_TIME', 5,
	);

my %vueDict;
my @vuelist;

#Every program needs a usage statement to educate users on syntax
sub usageMsg {
	print "you're doing it wrong.\n";
	print "querytool -s [STB,TITLE,PROVIDER,DATE,REV,VIEW_TIME]* \n";
	print "          -f [STB||TITLE||PROVIDER||DATE||REV||VIEW_TIME]=VALUE \n";
	print "          -o [STB,TITLE,PROVIDER,DATE,REV,VIEW_TIME] \n";
	die("Exiting Program\n");
}
#Parse Select flag values
sub selectcolumn{
	my $colStr = shift;
	
	my @transCols;
	my %groupCol;
	my @listCols = split(',',$colStr);
	#$debugp = 1;
	dprintf("selected ");
	foreach my $aCol (@listCols){
		dprintf("$aCol ");
		if ($aCol =~ /:/){
			#we have advanced filter option
			my ($col,$AdvProc) = split(':', $aCol);
			dprintf("$col , $AdvProc");
			$groupCol{uc $col} = $AdvProc;
			$aCol = $col;
		}
		my $ucCol = uc $aCol;
		if (exists ($colDict{$ucCol})){
			push (@transCols, $colDict{$ucCol});
		}else{
			die("Did not find select string $aCol\n");
		}
	}
	dprintf("@transCols\n");

	return (\@transCols, \%groupCol);
}
#Parse Select flag values
sub ordercolumn{
	my $colStr = shift;
	
	my @transCols;
	my @listCols = split(',',$colStr);
	dprintf("Ordered ");
	foreach my $aCol (@listCols){
		if ($aCol =~ /:/){
			#we have advanced filter option
			my ($col,$AdvProc) = split(':', $aCol);
			dprintf("$col , $AdvProc");
			$aCol = $col;
		}
		dprintf("$aCol ");

		my $ucCol = uc $aCol;
		if (exists ($colDict{$ucCol})){
			push (@transCols, $colDict{$ucCol});
		}else{
			die("Did not find order string $aCol\n");
		}
	}
	dprintf("\n");
	return \@transCols;
}

#Filter data remove all but what matches the columnn value
sub filtercolumn{
	my $colStr = shift;
	dprintf("Filtercolumnn $colStr\n");
	my ($aCol, $aVal) = split('=',$colStr);
	my $ucCol = uc $aCol;
	if (exists ($colDict{$ucCol})){
		return ($colDict{$ucCol}, $aVal);
	}else{
		die("Did not find filter string $aCol\n");
	}
}

sub groupcolumn{
	my $colStr = shift;
	
	my @transCols;
	my @listCols = split(',',$colStr);
	dprintf("selected ");
	foreach my $aCol (@listCols){
		my $ucCol = uc $aCol;
		if (exists ($colDict{$ucCol})){
			push (@transCols, $colDict{$ucCol});
		}else{
			die("Did not find group string $aCol\n");
		}
	}
	dprintf("\n");
	return \@transCols;
}

#Main routine 
my @selCols;
my @ordCols;
my @grpCols;
my %grpHash;
my $filtCol;
my $filtVal;
my $vueref;
#Available on cpan for download 
use Getopt::Mixed;

Getopt::Mixed::init( 's=s o=s f=s g=s t=s v h ?');
while( my( $option, $value, $pretty ) = Getopt::Mixed::nextOption() ) {
    OPTION: {
    	#Select by results
      $option eq 's' and do {
        dprintf("$option $value $pretty\n");
        my ($aref1, $aref2) = selectcolumn($value);
        @selCols = @{$aref1};
        %grpHash = %{$aref2};
        last OPTION;
      };
      $option eq 'o' and do {
      	#Order by Results
        dprintf("$option $value $pretty\n");
        my $aref = ordercolumn($value);
        @ordCols = @{$aref};
        last OPTION;
      };
      $option eq 'f' and do {
      	#filter by results
      	#May need some complex parsing to resolve AND/OR inclusion
        dprintf("$option $value $pretty\n");
        ($filtCol, $filtVal) = filtercolumn($value);
        if ($filtCol == 3) {
        	#open a date partition
   			my $apath = PerlDataImporter::import_mod::getPartitionName($filtVal);
        	my $vueref = PerlDataImporter::import_mod::openPartition($apath);
        	%vueDict = %{$vueref}; 
        }
        last OPTION;
      };
      $option eq 'g' and do {
      	#Group by results
        dprintf("$option $value $pretty\n");
        my $aref = groupcolumn($value);
        @grpCols = @{$aref};
        
        last OPTION;
      };
      $option eq 'v' and do {
      	#Group by results
        $debugp = 1;

        last OPTION;
      };
      $option eq 'h' and do {
      	#Group by results
        usageMsg();

        last OPTION;
      };
      $option eq '?' and do {
      	#Group by results
        usageMsg();

        last OPTION;
      };
      usageMsg();

    }
}

#Processing the directives to present rows to the Users
#1) Open default partition unless we have a defined view to open
#2) filter partition results 
#3) order the results
#4) Display the columnns of results as requested

if (!(%vueDict)){ #Open the default
	my $apath = PerlDataImporter::import_mod::getPartitionName($defaultdate);

	my $vueref = PerlDataImporter::import_mod::openPartition($apath);
    %vueDict = %{$vueref}; 
}
#use Data::Dump;
#dd %vueDict;

#Transform the hash into a multi-dimentional array
if (defined $filtCol){
	my @vlist = values(%vueDict);
	foreach $vueref (@vlist){ #Array of array reference 
		my @deref = @{$vueref}; #Single array 6 fields
		if ($deref[$filtCol] eq $filtVal){
			push @vuelist, [@deref]; #push matching rows
		}
	}
}else {
	my @vlist = values(%vueDict);
	foreach $vueref (@vlist){ #Array of array reference 
		my @deref = @{$vueref}; #Single array 6 fields
		push @vuelist, [@deref]; #push rows into md array
	}
}
if (@ordCols){
	foreach $vueref (reverse(@ordCols)){ #Apply sorts in reverse order Prioritize last
		my @sorted = sort { $a->[$vueref] cmp $b->[$vueref] } @vuelist;
		@vuelist = @sorted;
	}
}#else do nothing


#vuelist has all records I want in order I want
#collect the group by columnn
#This functionality is in progress 
if (@grpCols){
	#Group columns to dieplay by index 
	foreach $vueref (@grpCols){ #Apply sorts in reverse order Prioritize last
		my @sorted = sort { $a->[$vueref] cmp $b->[$vueref] } @vuelist;
		@vuelist = @sorted;
	}
}# else do nuttin

#select display columnns	
if (@selCols){
	foreach my $v (@vuelist){
		my @vref = @$v;
		foreach my $c (@selCols){
			print $vref[$c] . " ";
		}
		print "\n";
	}
}else {
	#Output all columnns 
		foreach my $v (@vuelist){
			print "@$v \n";
	}
}
	Getopt::Mixed::cleanup();

	