package Init;

use strict;
use warnings;

use DBI;
use File::Slurp;
use Crypt::SaltedHash;
use Exporter;

our @ISA= qw( Exporter );
our @EXPORT = qw( init_dbs );

sub init_dbs {
   # connect to db
   my $dbh = DBI->connect("dbi:SQLite:dbname=./data/sqlite/ambilight.db") or die $DBI::errstr;

   # variables to be used
   my $sql;
   my $sth;
   my $schema;
   my $csh;

   # create auth table
   $schema = read_file('./data/schema/auth.sql');
   $dbh->do("BEGIN TRANSACTION;") or die $dbh->errstr;
   $dbh->do($schema) or die $dbh->errstr;
   $dbh->do("COMMIT;") or die $dbh->errstr;

   # add some others
   $sql = 'insert into users (user, pass, about) values (?, ?, ?)';
   $sth = $dbh->prepare($sql) or die $dbh->errstr;
   
   $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
   $dbh->do("BEGIN TRANSACTION;");
   $csh->add('stephan');
   $sth->execute("stephan", $csh->generate, "Stephan's user account") or die $sth->errstr;
   $dbh->do("COMMIT;") or die $dbh->errstr;

   $dbh->do("BEGIN TRANSACTION;");
   $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
   $csh->add('tina');
   $sth->execute("tina", $csh->generate, "Tina's user account") or die $sth->errstr;
   $dbh->do("COMMIT;") or die $dbh->errstr;
   
   # create fav database
   $dbh->do("BEGIN TRANSACTION;");
   $schema = read_file('./data/schema/fav.sql');
   $dbh->do($schema) or die $dbh->errstr;
   $dbh->do("COMMIT;") or die $dbh->errstr;

   # disconnect from db
   $dbh->disconnect() or die $dbh->errstr;
}
