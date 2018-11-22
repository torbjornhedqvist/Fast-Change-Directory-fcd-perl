#!/usr/bin/perl -w

# Copyright (C) Torbjorn Hedqvist - All Rights Reserved
# You may use, distribute and modify this code under the
# terms of the MIT license. See LICENSE file in the project 
# root for full license information.  

##############################################################################
# fcd.pl (F)ast (C)ange (D)irectory 
#
# Known bugs:
#     - None, but I'm sure they are hidden inside ;)
#       All feedback is appreciated.
#
##############################################################################
use strict;
use Term::Complete;
use File::Basename;

# Version
my $versionShort = "1.7.1";
my $version = "fcd.pl Version $versionShort\n" .
    "Author: Torbjorn Hedqvist, torbjorn.hedqvist.c\@gmail.com\n" .
    "This is totally free software; There is NO warranty;\n\n";

# Some colors
my $reset     = "\033[0m";
my $fgRed     = "\033[31m";
my $fgBlue    = "\033[34m";
my $fgyellow  = "\033[33m";

# Catch SIGINT and use own function for cleanup.
$SIG{INT} = \&SigintHandler;

# environments
my $vobRoot    = $ENV{'VOB_ROOT'};
my $homeDir    = $ENV{'HOME'};
my $currentDir = $ENV{'PWD'};
my $myName     = basename($0);

# files
my $dirsFile    = "$homeDir/.fcd_dirs";
my $cdDirFile   = "$homeDir/.fcd_dir";
my $commandFile = "$homeDir/.fcd_cmd";

# global defaults
my @dirs    = {};
my $savedArgument = "";


### START ###

# clean out result from previous calls to fcd
if (-e $commandFile)
{
    unlink $commandFile;
}
if (-e $cdDirFile)
{
    unlink $cdDirFile;
}

ReadInputFile();

if (@ARGV == 0)
{
    # If no cmd-line argument was given this is treated as a read. 
    # Read entry or entries.
    ReadEntry("short");
}
elsif (@ARGV >= 1)
{
    SWITCH:
    {
        $ARGV[0] =~ /^-w$/ && do 
        {
            $savedArgument = "write";
            WriteNewEntry();
            last SWITCH;
        };

        $ARGV[0] =~ /^-d$/ && do 
        {
            $savedArgument = "delete";
            # Delete entry or entries.
            DeleteEntry();
            last SWITCH;
        };

        $ARGV[0] =~ /^-c$/ && do
        {
            $savedArgument = "modify";
            # Add, replace or delete a command to an existing entry
            ModifyCommand();
            last SWITCH;
        };

        ($ARGV[0] =~ /^--help$/ || $ARGV[0] =~ /^-h$/) && do
        {
            PrintHelp();
            last SWITCH;
        };

	$ARGV[0] =~ /^-v$/ && do
	{
	    print "$versionShort\n";
            last SWITCH;
        };

        $ARGV[0] =~ /^--version$/ && do
        {
            print "$version\n";
            last SWITCH;
        };

        $ARGV[0] =~ /^-l$/ && do
        {
            pop; # remove argument, else it will be treated as a tag

            # Read entry or entries with full listing of applied commands
            ReadEntry("long");
            last SWITCH;
        };


        # Default:
        # If no cmd-line argument matched this is treated as a read. 
        # Read entry or entries.
        ReadEntry("short");
    }
}

exit(0);

### END ###



### Functions ###

sub WriteNewEntry
{
    my $tag = $ARGV[1] if @ARGV == 2;

    open DIRS_OUTFILE, ">>$dirsFile" 
        or die "Error: Can't open $dirsFile: $!\n";

    # If tag was provided, check if tag already exist in input file
    if($tag)
    {
        my $countTags = 0;
        foreach my $dir (@dirs)
        {
            # Skip comment lines
            next if $dir =~ /^\s*#.*/;
 
            $countTags++ if $dir =~ /^$tag\s+/;
        }
        $countTags != 0 && do 
        { 
            print $fgyellow, "Tag \"$tag\" already exists, no entry added...\n", $reset; 
            exit(1); 
        };
    }

    foreach my $dir (@dirs)
    {
        # Skip comment lines
        next if $dir =~ /^\s*#.*/; 

        # remove trainling command if it exists.
        $dir =~ s%(.*)\s+cmd:.*$%$1%;

        # If $VOB_ROOT is defined replace the tag $VOB_ROOT in saved path before
        # comparison.
        $dir =~ s%\$VOB_ROOT(.*)%$vobRoot$1% if $vobRoot;

        if ($dir =~ /^.*?$currentDir$/)
        {
            print $fgyellow, "This path already exists, no entry added...\n", $reset;
            exit(1);
        }
    }

    # If environment $VOB_ROOT is defined and is part of the current directory,
    # replace it with keyword $VOB_ROOT
    if ($vobRoot)
    {
        my $vobPattern = '$VOB_ROOT';
	if ($currentDir eq "$vobRoot")
	{
	    # This is an exact match of VOB_ROOT and the next substitution
	    # can't handle that. Just replace it.
	    $currentDir = "$vobPattern";
	}
	else
	{
	    $currentDir =~ s%/local/tmp/views/.*?src_.*?(/.*)%$vobPattern$1%;
	}
    }

    if ($tag)
    {
        print DIRS_OUTFILE "$tag $currentDir\n";
    }
    else
    {
        print DIRS_OUTFILE "$currentDir\n";   
    }
}

sub DeleteEntry
{
    my $tag = "";

    if (@ARGV == 2)
    {
        $tag = $ARGV[1];
    }

    open DIRS_OUTFILE, ">$dirsFile" or
        die "Error: Can't open $dirsFile: $!\n";

    if ($tag eq "all")
    {
        print $fgyellow, "Do you really want to delete all entries (yes/no)? ", $reset;
        my $answer = <STDIN>;
        if ($answer =~ /[Yy][Ee][Ss]/)
        {
            print $fgyellow, "Swoosh, all entries deleted...\n", $reset;
            unlink $dirsFile;
        }
        else
        {
            print $fgyellow, "No entries deleted...\n", $reset;
            foreach my $dir (@dirs)
            {
                print DIRS_OUTFILE $dir;
            }
        }
    }
    elsif ($tag)
    {
        open DIRS_OUTFILE, ">$dirsFile" or
            die "Error: Can't open $dirsFile: $!\n";

        my $entryFound = 0;
        foreach my $dir (@dirs) 
        {
            if ($dir =~ /^$tag\s+/)
            {
                $entryFound = 1;
                next;
            } 
            print DIRS_OUTFILE $dir;
        }                
        
        if (! $entryFound)
        {
            print $fgyellow, "Can't find tag \"$tag\", no entry deleted...\n", $reset;
        }
    }
    else # no tag provided
    {
        PrintDirs("short");
        print "delete item(s): ";
        my $answer = <STDIN>;
        my @deleteItems = split(/,/, $answer) if $answer =~ /,/;
        $answer = shift @deleteItems if @deleteItems;
        if ($answer && $answer =~ /^\d+$/)
        {
            my $counter = 0;
            foreach my $dir (@dirs) 
            {
                # Skip comment lines
                next if $dir =~ /^\s*#.*/; 

                $counter++;
                if ($counter == $answer)
                {
                    $answer = shift @deleteItems if @deleteItems;
                    next;
                }
                print DIRS_OUTFILE $dir;
            }
        }
        else 
        {
            # No valid option given put all back to file
            print $fgyellow, "Invalid input, no entry deleted...\n", $reset;
            foreach my $dir (@dirs)
            {
                print DIRS_OUTFILE $dir;
            }
        }
    }
}

sub ReadEntry
{
    my $viewCommands = $_[0];
    my $tag = $ARGV[0];
    my $answer = "";
    my $command = "";
    my $output = "";

    if ($tag)
    {
        FindDirBasedOnTag($tag, \$command, \$output);
    }
    else 
    {
        # No tag provided, print the complete list and let the user select.
        my @completion_list = PrintDirs($viewCommands);
        my $answer = Complete('Select (number or tag): ', \@completion_list);
        my $length = @dirs;
        if ($answer =~ /^\d+$/ && $answer <= $length)
        {
            $output = $dirs[$answer -1];
            $command = $1 if $output =~ /^.*?cmd:(.*)/;
            if ($output =~ /^\s*\//)
            {
                # No tag at start of line
                $output =~ s%^\s*(.*?)\s+.*%$1%;
            }
            else
            {
                # has tag, remove it...
                if ($output =~ /\$VOB_ROOT/)
                {
                    $output =~ s%^\s*.*?(\$VOB_ROOT.*?)\s+.*%$1%;
                }
                else
                {
                    $output =~ s%^\s*.*?(\/.*?)\s+.*%$1%;
                }
            }

            if ($output =~ /VOB_ROOT/ && !$vobRoot)
            {
                print $fgyellow, 'Entry contains $VOB_ROOT but $VOB_ROOT not defined', "\n", $reset;
            }
        }
        elsif ($answer !~ /^$/)
        {
            # Answer not empty and not digits, assume its a tag
            FindDirBasedOnTag($answer, \$command, \$output);
        }
    }
    
    if ($output)
    {
        if ($vobRoot)
        {
            # Replace VOB_ROOT keyword with current environment
            $output =~ s%\$VOB_ROOT(.*)%$vobRoot$1%;
        }
        open OUTFILE, ">$cdDirFile"
            or die "Error: Can't open $cdDirFile: $!\n";
        print OUTFILE $output;
        close OUTFILE;

        if ($command)
        {
            open CMDFILE, ">$commandFile" 
                or die "Error: Can't open $commandFile: $!\n";

            print CMDFILE "$command\n";
            close CMDFILE;
        }
    }

}

sub FindDirBasedOnTag
{
    my $tag = shift;
    my $command = shift; # Passed as reference
    my $output = shift; # Passed as reference
    foreach my $dir (@dirs)
    {
        # Skip comment lines
        next if $dir =~ /^\s*#.*/;
        
        if ($dir =~ /^$tag\s/)
        {
            $$command = $1 if $dir =~ /^.*?cmd:(.*)/;
            
            $dir =~ s%$tag\s+(.*?)\s+.*%$1%;
            $$output = $dir; # row found, pick dir
            last;
        }
    }

    if (! $$output)
    {
        print $fgyellow, 
        "Can't find specified tag \"$tag\" in list. ", 
        "Try with the option -h or --help for more information\n", $reset;
    }
    elsif ($$output =~ /VOB_ROOT/ && !$vobRoot)
    {
        print $fgyellow, 'Entry contains $VOB_ROOT but $VOB_ROOT not defined', "\n", $reset;
    }
}


sub ReadInputFile
{
    # slurp the input file
    `touch $dirsFile` if ! -e "$dirsFile";
    open DIRS_INFILE, "$dirsFile" or die "Error: Can't open $dirsFile: $!\n";
    @dirs = <DIRS_INFILE>;
    close DIRS_INFILE;
}

sub ModifyCommand
{
    PrintDirs("long");
    print "select entry (number) to add or replace a command to: ";
    my $answer = <STDIN>;
    my $length = @dirs;
    if ($answer =~ /^\d+$/ && $answer <= $length)
    {
        chomp $answer;
        my $entry = $answer;
        print 
            "Insert your command, if no input is given any existing ",
            "command will be deleted.\n",
            "Selected entry [$entry] Command: ";
        my $command = <STDIN>;
        chomp $command;
        if ($command eq "")
        {
            print "No command provided...\n";
        }

        
        open DIRS_OUTFILE, ">$dirsFile" 
            or die "Error: Can't open $dirsFile: $!\n";
        my $position = 0;
        foreach my $dir (@dirs)
        {
            # Skip comment lines
            next if $dir =~ /^\s*#.*/;
                
            $position++;
            if ($position != $entry)
            {
                print DIRS_OUTFILE $dir;

            }
            else
            {
                $dir =~ s/(.*?)\s+cmd:.*/$1/;
                if ($command ne "")
                {
                    chomp $dir;
                    print DIRS_OUTFILE "$dir cmd:$command\n";
                    print "Modified entry [$position] $dir cmd:$command\n";
                }
                else
                {
                    # Remove existing command
                    print DIRS_OUTFILE $dir;
                    print "If existing command it's removed.\n";
                }
            }
        }
    }
    elsif ($answer !~ /^$/)
    {
        print $fgyellow, "Invalid selection...\n", $reset;
    }
}


sub PrintDirs
{
    my $viewCommands = $_[0];
    my @localDirs = @dirs; # local copy since we modify it.
    my @completion_list;

    my $counter = 0;
    my $tag     = "";
    foreach my $dir (@localDirs)
    {
        # toggle line color to enhance readability
        $counter++;
        if ($counter % 2 == 0)
        {
            print $fgBlue;
        }
        else
        {
            print $fgRed;
        }

        my $command = "";
        if ($dir =~ /(cmd:.*)/)
        {
            $command = $1 if $viewCommands eq "long";
        }

        # Remove the command keyword and all commands
        $dir =~ s/^(.*?)\s+cmd:.*$/$1/g;

        if ($dir !~ /^\// && $dir !~ /^\$/)
        {
            my @list = split(/\s+/, $dir);
            my $tag = shift @list;
            push @completion_list, $tag; 
            if ($command eq "")
            {
                printf "[%2s, %s] %s%s\n", $counter, $tag, @list, $reset;
            }
            else
            {
                printf "[%2s, %s] %s%s %s\n", 
                    $counter, $tag, @list, $reset, $command;
            }
        }
        else
        {
            # $dir starts with / as in a path e.g /bin/... or 
            # $dir starts with $ as in $VOB_ROOT.
            if ($command eq "")
            {
                printf "[%2s] %s%s", $counter, $dir, $reset;
            }
            else
            {
                chomp $dir;
                printf "[%2s] %s%s %s\n", $counter, $dir, $reset, $command;
            }
        }
    }
    
    return @completion_list;
}

sub SigintHandler
{
    $SIG{INT} = \&SigintHandler;
    print $reset, "\n";
    if ($savedArgument eq "delete")
    {
        # Restore orignal file since it might have been opened for writing
        open DIRS_OUTFILE, ">$dirsFile" or
            die "Error: Can't open $dirsFile: $!\n";

        # put all back to file
        foreach my $dir (@dirs)
        {
            print DIRS_OUTFILE $dir;
        }
    }
    exit(0);
}


sub GetCommandLineOptions
{

}


sub PrintHelp
{
    print 
        "Usage: $myName [OPTION] [TAG]\n",
        "Options:\n",
        " -w            - write current directory to list\n",
        " -d            - delete entry or multiple entries (comma separated)\n",
        " -c            - add, replace or delete a command to an existing entry\n",
        " -l            - print added commands to entries\n",
        " -v, --version - output version information and exit\n",
        " -h, --help    - display this help and exit\n\n",
        "Examples:\n",
        "> $myName -w mytag - add current directory with shortcut TAG <mytag> to list\n",
        "> $myName mytag    - change to the directory mapped to TAG <mytag>.\n",
        "> $myName -w       - add current dir to the list\n",
        "> $myName          - show all entries and user can select from list\n",
        "> $myName -d mytag - delete entry with TAG <mytag>.\n",
        "> $myName -d       - show all entries and user can delete entry or entries\n",
        "> $myName -d all   - reserved tag-keyword \"all\" deletes all entries in list.\n\n",
}


