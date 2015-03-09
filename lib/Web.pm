#/usr/bin/env perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::Log;
use Crypt::SaltedHash;
use DBI;

my $current_color = "6600FF";
use constant INITIAL_COLOR => "FFFFFF";
use constant DEFAULT_FAVORITE_NAME => "Favorite";
my $num_LEDS = 50;
my $log = Mojo::Log->new;
app->sessions->default_expiration(3600);

# {{{ Routes
## {{{ get '/'
get '/' => sub {
   shift->render(template => 'index');
};
## }}}

## {{{ get '/AmbiLight/' 
get '/AmbiLight/' => sub {
   my $self = shift;
   my $options = prep_option_string($num_LEDS);
   my $username = $self->session('user');

   my $dbh = connect_db("./data/sqlite/ambilight.db");
   my $sql = "SELECT * FROM favorites WHERE user = ? ORDER BY name ASC";
   my $sth = $dbh->prepare($sql) or die $dbh->errstr;
   $sth->execute($username) or die $sth->errstr;

   # all favorites
   my $entries = $sth->fetchall_hashref('id');
   $self->render(template => 'AmbiLight', options => $options, current_color => $current_color, user => $username, entries => $entries);
};
## }}}

## {{{ get '/AmbiLight/colorize' 
get '/AmbiLight/colorize' => sub {
   my $self = shift;
   my @names = $self->param;

   my (@active_leds) = ($self->req->url =~ m/LED=(\d+)/g);
   $log->debug("@active_leds");
   
   my ($r, $g, $b) = ($self->req->url =~ m/color=((?:\d|[A-F]){2})((?:\d|[A-F]){2})((?:\d|[A-F]){2})/);
   $log->debug("$r, $g, $b");
   
   # execute the python script to activate the LEDS: TODO we can use also perl and send data to DMX server directly
   system("echo 'command -r $r -g $g -b $b'");
   $current_color = "$r$g$b";
   $self->redirect_to('/AmbiLight');
};
## }}}

## {{{ get '/AmbiLight/login'
get '/AmbiLight/login' => sub {
   my $self = shift;
   $self->render(template => "AmbiLightLogin");
};
## }}}
#
## {{{ post '/AmbiLight/login'
post '/AmbiLight/login' => sub {
   my $self = shift;
   if ($self->session('user') eq $self->req->param('username')) {
      $self->redirect_to("/AmbiLight");
   } else {
      my $username =  $self->req->param('username');
      my $dbh = connect_db("./data/sqlite/ambilight.db");
      my $sql = 'SELECT pass FROM users WHERE user = ?';
      my $sth = $dbh->prepare($sql) or die $dbh->errstr;

      $sth->execute($username);
      my $res = $sth->fetchrow_hashref;
      if ($res) {
         my $pass = $res->{'pass'};
         my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');

         $csh->add($self->req->param('password'));
         if (Crypt::SaltedHash->validate($pass, $self->req->param('password'))) {
            $self->session('user' => $username);
            $self->redirect_to("/AmbiLight");
         }
      } else {
         $self->redirect_to("/AmbiLight/error");
      }
   }
};
## }}}

## {{{ get '/AmbiLight/logout' 
get '/AmbiLight/logout' => sub {
   my $self = shift;
   $self->session("user" => "");
   $self->redirect_to("/AmbiLight");
};
## }}}

## {{{ get '/AmbiLight/error' 
get '/AmbiLight/error' => sub {
   my $self = shift;
   $self->render(template => "AmbiLightLoginError");
};
## }}}

## {{{ get '/AmbiLight/add_fav'
get '/AmbiLight/add_fav' => sub {
   shift->render(template => "AmbiLightAddFav", init_color => INITIAL_COLOR);
};
## }}}

## {{{ post '/AmbiLight/add_fav'
post '/AmbiLight/add_fav' => sub {
   my $self = shift;
   if ($self->session('user')) {
      my $dbh = connect_db("./data/sqlite/ambilight.db");
      my $sql = 'INSERT INTO favorites (user, name, red, green, blue) values (?, ?, ?, ?, ?)';
      my $sth = $dbh->prepare($sql) or die $dbh->errstr;
      my $name = $self->req->param('name');
      my $red = $self->req->param('red');
      my $green = $self->req->param('green');
      my $blue = $self->req->param('blue');
      my $color = $self->req->param('fav_color');

      if ( ($green eq "") || ($red eq "") || ($blue eq "") ) {
         my ($r, $g, $b) = ($color =~ m/((?:\d|[A-F]){2})((?:\d|[A-F]){2})((?:\d|[A-F]){2})/);
         $green = hex($g);
         $red = hex($r);
         $blue = hex($b);
      }
   
      if ( $name eq "") {
         $name = DEFAULT_FAVORITE_NAME;
      }

      $sth->execute($self->session('user'), $name, $red, $green, $blue);
      $self->redirect_to("/AmbiLight/");
      disconnect_db($dbh);
   } else {
      $self->redirect_to("/AmbiLight/");
   }
};
## }}}
# }}}

# {{{ Helpers
## {{{ DB handling
## {{{ connect
sub connect_db {
    my $db = shift;
    my $dbh = "";

    if (!$db) {
        die("No database name given: $!");
    } else {
        $dbh = DBI->connect("dbi:SQLite:dbname=".$db) or die $DBI::errstr;
    }
    return $dbh;
}
## }}}

## {{{ disconnect
sub disconnect_db {
    my $dbh = shift;
    if (!$dbh) { 
        die("No database handle given: $!");    
        return 0;
    } else {
       $dbh->disconnect() or die $dbh->errstr;
    }
    return 1;
}
## }}}
## }}}

## {{{ prepare option string for LEDs
sub prep_option_string {
   my $num_leds = shift;
   my $str = "";
   for (my $i = 0; $i < $num_leds; $i++) {
      $str .= "\<option\> $i \</option\>\n";
   }
   return $str;
}
## }}}
# }}}

# {{{ Start application
app->start;
# }}}

__DATA__
@@ AmbiLightAddFav.html.ep
<html>
<head><title>Login</title></head>
<body>
  <form action="/AmbiLight/add_fav" method="post">
    Favorite Name: <input type="text" name="name"> 
    Red <input type="text" name="red">
    Green <input type="text" name="green">
    Blue <input type="text" name="blue">
   Color: <script type="text/javascript" src="/jscolor/jscolor.js"></script>
   <input name="fav_color" class="color" value="<%= $init_color %>">
   <p>
       <input type="submit" value=" Absenden ">
        <input type="reset" value=" Abbrechen">
   </p>
  </form>
 </body>
</html>



@@ AmbiLightLoginError.html.ep
TODO add more sophisticated login error here, or
redirect to /AmbiLight/ and show login error status!

@@ AmbiLightLogin.html.ep
<!DOCTYPE html>
<html>
<head><title>Login</title></head>
<body>
  <form action="/AmbiLight/login" method="post">
    Name: <input type="text" name="username"> 
    Password: <input type="password" name="password">
   <p>
       <input type="submit" value=" Absenden ">
        <input type="reset" value=" Abbrechen">
   </p>
  </form>
 </body>
</html>


@@ AmbiLight.html.ep
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
       "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<style type="text/css">
  body {
    color: white; background-color: black;
    font-size: 100.01%;
    font-family: Helvetica,Arial,sans-serif;
    margin: 0; padding: 1em 0;
    text-align: left;  
   background-image: url("/raspi.jpg");
  }
</style>
<title>Select LEDs to colorize</title>
</head>
<body>

<h1>Select LEDs to colorize</h1>

<form action="/AmbiLight/colorize" method=get>
  <p>
    <select name="LED" size="10" multiple>
      <% for (my $i = 1; $i <= 50; $i++) { %>
      <option value="<%=$i%>" selected>
      <%= $i %>
      </option>
      % } %>
    </select>

<p>
<script type="text/javascript" src="/jscolor/jscolor.js"></script>
<input name="color" class="color" value="<%= $current_color %>">
</p>

<p>
    <input type="submit" value="Turn lights on">
    <input type="reset" value="Reset selection">
</p>
</form>

<p> Login status:
 <% if (!defined($user) || $user eq "") { %>
   not logged in, consider logging in: <a href="/AmbiLight/login/"> here </a>
   </p>
  <% } else { %>
   you are logged in as: <%= $user %>
   </p>
   Your favorites: ... generated favorites here by database, previously login via user and pass from db. done then.
   <p>
   Add a new favorite <a href="/AmbiLight/add_fav/"> here </a>
   </p>
   
   <p>
    <table style="width:100%">
  <tr>
    <th>Favorite name</th>
    <th>Favorite number</th>
    <th>Date added </th>
    <th> rot </th>
    <th> grün </th>
    <th> blau </th>
    <th> color choser </th>
    <th> number of activaitions </th>
    <th> activate </th>
   </tr>
   <% for my $key (reverse sort keys(%{$entries})) { %>
  <tr>
      <td> <%= $entries->{$key}->{'name'} %> </td>
      <td> <%= $entries->{$key}->{'id'} %> </td>
      <td> not used for now </td>
      <td> <%= $entries->{$key}->{'red'} %> </td>
      <td> <%= $entries->{$key}->{'green'} %> </td>
      <td> <%= $entries->{$key}->{'blue'} %> </td>
      <td>
      <form action="/AmbiLight/colorize" method=get>
      <script type="text/javascript" src="/jscolor/jscolor.js"></script>
      <input name="color" class="color" value="<%=  uc sprintf("%02x%02x%02x",$entries->{$key}->{'red'}, $entries->{$key}->{'green'}, $entries->{$key}->{'blue'}) %>">
      </td>
      <td> not used for now </td>
      <td> 
     <p>
    <select name="LED" size="10" multiple>
      <% for (my $i = 1; $i <= 50; $i++) { %>
      <option value="<%=$i%>" selected>
      <%= $i %>
      </option>
      % } %>
    </select>


       <input type="submit" value="Turn lights on">
       <input type="reset" value="Reset selection">
      </form>
      </td>
  </tr>
    <% } %>
</table>
      <p> you have <%= scalar keys %$entries %> favorites </p> 

   <p>
   Logout <a href="/AmbiLight/logout"> here </a>
   </p>
<% } %>


</body>
</html>

@@ index.html.ep
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
       "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>Raspberry Pi Control Center (RPiCC)</title>
<style type="text/css">
  body {
    color: black; background-color: white;
    font-size: 100.01%;
    font-family: Helvetica,Arial,sans-serif;
    margin: 0; padding: 1em 0;
    text-align: center;  
   background-image: raspi.jpg;
  }

  div#Seite {
    text-align: left;    
    margin: 0 auto;     
    width: 760px;
    padding: 0;
    background: #ffffe0 url(hintergrund.gif) repeat-y;
    border: 2px ridge silver;
  }

  h1 {
    font-size: 1.5em;
    margin: 0; padding: 0.3em;
    text-align: center;
    background: #fed url(logo.gif) no-repeat 100% 45%;
    border-bottom: 1px solid silver;
  }

  ul#Navigation {
    font-size: 0.83em;
    float: left; width: 200px;
    margin: 0 0 1.2em; padding: 0;
  }
  ul#Navigation li {
    list-style: none;
    margin: 0; padding: 0.5em;
  }
  ul#Navigation a {
    display: block;
    padding: 0.2em;
    font-weight: bold;
  }
  ul#Navigation a:link {
    color: black; background-color: white;
  }
  ul#Navigation a:visited {
    color: #666; background-color: white;
  }
  ul#Navigation a:hover {
    color: black; background-color: #eee;
  }
  ul#Navigation a:active {
    color: white; background-color: gray;
  }

  div#Content {
    margin: 0 0 1em 220px;
    padding: 0 1em;
  }
  * html div#Content {
    height: 1em;  /* Workaround gegen den 3-Pixel-Bug des Internet Explorer bis Version 6 */
    margin-bottom: 0;
  }
  div#Content h2 {
    font-size: 1.2em;
    margin: 0.2em 0;
    color: navy;
  }
  div#Content p {
    font-size: 1em;
    margin: 1em 0;
  }

  p#Footer {
    clear: both;
    font-size: 0.83em;
    margin: 0; padding: 0.1em;
    text-align: center;
    background-color: #fed;
    border-top: 1px solid silver;
  }
</style>
</head>
<body>

<div id="Seite">
  <h1>Raspberry Pi Control Center (RPiCC) </h1>

  <ul id="Navigation">
    <li><a href="/MusicBox">MusicBox</a></li>
    <li><a href="/AmbiLight">AmbiLight</a></li>
  </ul>

  <div id="Content">
    <h2>Welcome</h2>


     <p> Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. </p>

     <p> Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. </p>

  </div>

  <p id="Footer"> &copy; stephan@syntaktischer-zucker.de </p>
</div>

</body>
