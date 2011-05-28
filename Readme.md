# Annotate-GFF

## License
This program is licensed under the GNU Lesser General Public License.
See License.txt for more information.

## Description
Annotate-GFF is a Ruby gem to turn BLAST search results into
annotations in a GFF file. BLAST search results must be saved XML format.
The tool takes all HSPs of all BLAST hits and adds them as records at
the end of the GFF file. As an optional parameter, Annotate-GFF can
read another set of BLAST results in XML format that can be used to
provide functional annotations for the search hits to be added to the
GFF file. For that purpose it is advisable to blast against a peptide
sequence database like
[NCBI nr](http://www.ncbi.nlm.nih.gov/blast/blast_databases.shtml)

## Usage
Annotate-GFF takes the following parameters:

            --input-gff, -i <s>:   Input GFF file
           --output-gff, -o <s>:   Output GFF file
            --blast-xml, -b <s>:   Blast XML output
       --annotation-xml, -a <s>:   Blast XML output for annotations
                     --help, -h:   Show a help message
                     
## Walkthrough
Let's assume you want to map EST reads of *Ephydatia muelleri* onto
genome scaffolds of *Amphimedon queenslandica*.
Let's also assume that you already have another set of annotations for *Amphimedon queenslandica*
that are stored in GFF format.

If you want functional annotations for the EST reads you must first
blast all *Ephydatia muelleri* reads against NCBI nr. Instructions on
how to scquire this database can be found
[here](http://www.ncbi.nlm.nih.gov/staff/tao/URLAPI/blastdb.html). An
example BLAST command could be:

    blastx -query ephydatia.fasta -db BLASTDB/nr -evalue 0.0001 -max_target_seqs 1 -out ephydatia_annotations.xml -outfmt 5

Now you need to build a BLAST database of your *Ephydatia*
sequences. You can use makeblastdb for that task:

    makeblastdb -in ephydatia.fasta -dbtype nucl
    
After that, you can produce the BLAST XML output that will be used for
constructing GFF records:

    tblastx -db ephydatia.fasta -query amphimedon.fasta -lcase_masking -evalue 0.0001 -outfmt 5 -out ephydatia.xml

You now have all the input files you need to run Annotate-GFF.

    annotate-gff -i amphimedon.gff -o amphimedon_with_ephydatia.gff -b ephydatia.xml -a ephydatia_annotations.xml

This will produce a new GFF file called amphimedon_with_ephydatia.gff
that contains the mapping of *Ephydatia muelleri* onto the genome
scaffolds of *Amphimedon queenslandica*.

This file can be opened and viewed with a program like
[Geneious](http://www.geneious.com/)

## Prerequisites
In order to install this gem you need to have several programs
installed:

 * Ruby either in version 1.8.7 or 1.9.2. The use of [JRuby](http://www.jruby.org/) (a Java implementation of Ruby) is recommended.
 * Git

In the following, the installation procedure is given for **Mac OS X** and **Ubuntu Linux 10.10**. The commands for Ubuntu also have been tested to work for **Debian Squeeze** although you should substitute apt-get by aptitude.

### Installing Git
An installer for Mac OS X can be obtained from the [official website](http://git-scm.com/). For any Linux distribution it is recommended that you use your system's package manager to install Git. Look for a package called git or git-core. For Ubuntu 10.10 the command is:

    sudo apt-get install git

### Installing JRuby
Very few distributions offer packages for the most recent version of JRuby.
The easiest way to install the most recent version of JRuby is via the [Ruby Version Manager](http://rvm.beginrescueend.com/) by Wayne E. Seguin.

Before you install RVM, make sure you have git and curl installed on your system.

RVM can be installed by calling:

    bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-head )

This will install RVM to .rvm in your home folder and print several instructions specific to your platform on how to finish the installation. Please pay close attention to the "dependencies" section and look for the part where it says something like this:

    # For Ruby (MRI & ree)  you should install the following OS dependencies:
    ruby: /usr/bin/apt-get install build-essential bison openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev

These are the requirements for building the normal C version of Ruby. However, many of those tools are also required for building the Java version of Ruby so it is advisable that you install all of these prerequisites. Please do not copy the commands from this file, look at the output of the RVM installer.

    sudo apt-get install build-essential bison openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev

If installing any of these packages gives you an error, consider updating your packages by using your system's update manager.

Next you need to install the tools that are specifically required for installing JRuby. The output of RVM might look like this:

    # For JRuby (if you wish to use it) you will need:
      jruby: /usr/bin/apt-get install curl g++ openjdk-6-jre-headless
      jruby-head: /usr/bin/apt-get install ant openjdk-6-jdk

It is recommended that you use the latest stable version of JRuby, not jruby-head. Accordingly, on Ubuntu 10.10 you have to install the following packages in order to use JRuby with RVM:

    apt-get install curl g++ openjdk-6-jre-headless
    
Next, you have to make sure that RVM is loaded when you start a new shell. Look for the part where it says: "You must now complete the install by loading RVM in new shells."

On Ubuntu 10.10 you can edit your .bashrc by calling:

    gedit .bashrc
    
On Mac OS X, you can type:

    open -a TextEdit .bash_profile

At the very end of this file add the following line:
    
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"  # This loads RVM into a shell session.
    
Now save the file, close your editor and close your shell. Start a new shell and type:
    
    type rvm | head -1
    
If you see something like "rvm is a function" the installation was
successful. If you run into problems, read the
[documentation](http://rvm.beginrescueend.com/rvm/install/).

**The following command is not part of the installation procedure!**
You can always delete RVM and start from scratch by typing:

    rvm implode
     
Please note that this will delete all versions of Ruby you installed with RVM as well as all of the gems you installed. It will not reverse the changes you made to your shell's load configuration.

Now you can install JRuby by calling:
    
    rvm install jruby
    
Please note that everything RVM installs is placed in the folder .rvm in your home directory. Therefore, it is not necessary to use sudo when calling rvm.

In order to use JRuby instead of your system's Ruby version you must type
    
    rvm use jruby
    
every time you open a new shell. You can check which version you are currently using with:

    ruby -v
    
If you want to switch back to the version of Ruby that came with your system, type:

    rvm use system
    
In order to use JRuby as the default Ruby implementation on your system you can type:

    rvm --default use jruby
    
Now JRuby will be called when you type ruby in a new shell.

## Installing Annotate-GFF
This gem is distributed in source form for the time being, so you must build it yourself in order to use it. Don't worry, it's not hard:

First you must download the source code of this gem by going to a folder of your choice and typing:

    git clone git://github.com/PalMuc/Annotate-GFF.git

This will will clone a copy of this repository in a folder named Annotate-GFF. Go to this folder by typing:

    cd Annotate-GFF

Annotate-GFF is delivered as a Ruby gem. In order to build and install it, you first have to install another gem called bundler. Type:

    rvm jruby gem install bundler

In order to install the other gems Annotate-GFF depends on, first switch to JRuby:
    
    rvm use jruby

Now type:

    bundle install

Before you build an updated version of Annotate-GFF, you should
delete previous builds by typing:

    rm pkg/annotate-gff-*.gem

After that, create a new Ruby gem by typing:

    rake install
    
Finally you can install the gem by typing:

    rvm jruby gem install pkg/annotate-gff-*.gem
    
Annotate-GFF is now in your global path, meaning that from any point in the system you can use it by typing

    annotate-gff
    
on the command line. Please note that in order to do that you have to switch to JRuby as mentioned before.
