package MyInit;

use strict;
use warnings;

use DBI;
use File::Slurp;
use Crypt::SaltedHash;
use Exporter;
our @ISA= qw( Exporter );
our @EXPORT = qw( init_auth init_favs );

# initialize auth db {{{
sub init_auth {
        my $dbh = DBI->connect("dbi:SQLite:dbname=./data/sqlite/auth.db") or
                die $DBI::errstr;
        my $schema = read_file('./data/schema/auth.sql');
  $dbh->do("BEGIN TRANSACTION;") or die $dbh->errstr;
        $dbh->do($schema) or die $dbh->errstr;

        my $sql = 'insert into users (user, pass) values (?, ?)';
        my $sth = $dbh->prepare($sql) or die $dbh->errstr;

 my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
 $csh->add('stephan');
        $sth->execute("stephan", $csh->generate) or die $sth->errstr;

        $sql = 'insert into users (user, pass) values (?, ?)';
        $sth = $dbh->prepare($sql) or die $dbh->errstr;

 $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
 $csh->add('tina');
        $sth->execute("tina", $csh->generate) or die $sth->errstr;

        $sql = 'insert into users (user, pass) values (?, ?)';
        $sth = $dbh->prepare($sql) or die $dbh->errstr;

 $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
 $csh->add('test');
        $sth->execute("admin", $csh->generate) or die $sth->errstr;
  $dbh->do("COMMIT;") or die $dbh->errstr;

 $dbh->disconnect() or die $dbh->errstr;
}
# }}}

# initialize favorites db {{{
sub init_favs {
        my $db = DBI->connect("dbi:SQLite:dbname=./data/sqlite/fav.db") or
                die $DBI::errstr;
    
$db->do("BEGIN TRANSACTION;");
        my $schema = read_file('./data/schema/fav.sql');
        $db->do($schema) or die $db->errstr;
 $db->do("COMMIT;") or die $db->errstr;

  $db->disconnect() or die $db->errstr;
}
# }}}
