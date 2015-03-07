#/usr/bin/env perl

use strict;
use warnings;

my $times_logged_in = 0;
use Mojolicious::Lite;

use DBI;
my $dbh = DBI->connect("dbi:SQLite:database.db","","") or die "Could not connect";

#use Mojolicious::Sessions;
#my $sessions = Mojolicious::Sessions->new;
#$sessions->cookie_name('');

get '/' => sub {
   $times_logged_in++;
   my $c = shift;
   $c->render(template => 'index', logged_in => $times_logged_in);
};

sub prep_string {
   my $str = "";
   for (my $i = 0; $i < 50; $i++) {
      $str .= "\<option\> $i \</option\>\n";
   }
   return $str;
}

my $current_color = "6600FF";
get '/AmbiLight/' => sub {
   my $options = prep_string();
   my $c = shift;
   my $username = $c->session('user');
   $c->render(template => 'AmbiLight', options => $options, current_color => $current_color, user => $username);

};

get '/colorize' => sub {
   my $self = shift;
   use Mojo::Log;

   my $log = Mojo::Log->new;
   my @names       = $self->param;
   $log->debug("@names");
   $log->debug($self->req->url);

   my (@active_leds) = ($self->req->url =~ m/LED=(\d+)/g);
   $log->debug("@active_leds");
   
   my ($r, $g, $b) = ($self->req->url =~ m/color=((?:\d|[A-F]){2})((?:\d|[A-F]){2})((?:\d|[A-F]){2})/);
   $log->debug("$r, $g, $b");
   
   # execute here the python script to activate the leds
   system("echo 'command -r $r -g $g -b $b'");
   $current_color = "$r$g$b";
   $self->redirect_to('/AmbiLight');
};

get '/AmbiLight/favs' => sub {
   my $self = shift;
   use Mojo::Log;
   my $log = Mojo::Log->new;
   my $name = $self->session('user');
   if ($name eq "") {
      $self->redirect_to("/AmbiLight/login");
   } else {
      $self->redirect_to("/AmbiLight/");
   }
   
};

get '/AmbiLight/login' => sub {
   my $self = shift;
   $self->session("user" => "");
   $self->render(template => "AmbiLightLogin");
};

post '/AmbiLight/login' => sub {
   my $self = shift;
   use Mojo::Log;
   my $log = Mojo::Log->new;
   my $username =  $self->req->param('username');
   $log->debug("params: $username");
   if ($username eq "tina") {
      $self->session('user' => "tina");
      $self->redirect_to("/AmbiLight");
   } else {
      $self->redirect_to("/AmbiLight/error");
   }
   
};

get '/AmbiLight/error' => sub {
   my $self = shift;
   $self->render(template => "AmbiLightLoginError");
};

app->start;



__DATA__
@@ AmbiLightLoginError.html.ep
ERROR

@@ AmbiLightLogin.html.ep
<!DOCTYPE html>
<html>
<head><title>People</title></head>
<body>
  <form action="/AmbiLight/login" method="post">
    Name: <input type="text" name="username"> 
    Age: <input type="password" name="password"
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

<form action="/colorize" method=get>
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
 <% if ($user eq "") { %>
   not logged in, consider logging in: <a href="/AmbiLight/login/"> here </a>
   </p>
  <% } else { %>
   you're logged in as: $user
   </p>
   Your favorites: ... generated favorites here by database, previously login via user and pass from db. done then.
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
</html>
