# How to install Perl Udapi

These guidelines are for Linux, but Perl Udapi should work on other platforms as well.

## Perl setup
- You need Perl 5.10 or higher (ideally 5.22). Check [Perlbrew](http://perlbrew.pl).
- You need [cpanm](http://metacpan.org/pod/App::cpanminus) v1.6 or higher.
  If you don't have perl from Perlbrew and you don't have root (sudo) access,
  you can use [local::lib](https://metacpan.org/pod/local::lib) to install Perl modules locally, e.g. in your `~/perl5/`.
  To install `cpanm` and `local::lib` in one step you can use:
```
wget -O- http://cpanmin.us | perl - -l ~/perl5 App::cpanminus local::lib
eval `perl -I ~/perl5/lib/perl5 -Mlocal::lib`
echo '## Install Perl modules to ~/perl5 by default ##' >> ~/.bashrc
echo 'eval `perl -I ~/perl5/lib/perl5 -Mlocal::lib`'    >> ~/.bashrc
```

## Udapi for users
Udapi has not been released to CPAN yet. We recommend to install it (and all its dependencies) directly from GitHub.
```
cpanm git://github.com/udapi/udapi-perl
```
This installs Udapi to your standard Perl paths (`~/perl5/lib/perl5/` if you followed the steps above),
but it's not versioned in git, so you cannot contribute by pull requests etc.


## Udapi for developers
Let's clone the git repo to `~/udapi-perl/` and setup `$PATH` and `$PERL5LIB` accordingly.
```
cd
git clone https://github.com/udapi/udapi-perl.git
cpanm --installdeps ./udapi-perl
echo '## Use Udapi from ~/udapi-perl/ ##'               >> ~/.bashrc
echo 'export PATH="$HOME/udapi-perl/script:$PATH"       >> ~/.bashrc
echo 'export PERL5LIB="$HOME/udapi-perl/lib:$PERL5LIB"' >> ~/.bashrc
source ~/.bashrc # or open new bash
```

## Test Udapi
```
udapi.pl -h
```
or `cd udapi-perl/demo/` and run `./perl-demo.sh`.
