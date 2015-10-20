data paths need a config file. Currently they are hard coded to a path on my box and need changes.
The import_mod.pl needs to be in @INC , easiest way is -I flag on the execution. 

I execute with a line like :
>perl -IC:\mydocs\GitHub querytool.pl -s TITLE,STB,REV -o TITLE,REV ...

and the importer like :
>perl -IC:\mydocs\GitHub importer.pl [FILEPATH]
