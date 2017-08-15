#/usr/bin/env perl
### TODO: can use PERL bindings for ola

use strict;
use warnings;

my $times_logged_in = 0;
use Mojolicious::Lite;

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

my $current_color = uc sprintf("%02x%02x%02x", 233, 11, 241);

   my $log = Mojo::Log->new;
    $log->debug("color: $current_color");

get '/AmbiLight/' => sub {
   my $options = prep_string();
   my $c = shift;
   $c->render(template => 'AmbiLight', options => $options, current_color => $current_color);
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

   my $ri = hex($r);
   my $gi = hex($g);
   my $bi = hex($b);

   # execute here the python script to activate the leds
   system("/home/pi/code/plspotify/lib/public/go_constant_color.py $ri $gi $bi");
   $current_color = "$r$g$b";
   $self->redirect_to('/AmbiLight');
};

get '/control' => sub {
  my $self = shift;
  use Mojo::Log;
  my $log = Mojo::Log->new;
  my @names=$self->param;
  $log->debug("@names");
  $log->debug($self->req->url);
  if ($#names eq 1) {
      my $command = @names;
      if ($command == "reboot") {
        system("sudo reboot");
      } elsif ($command == "shutdown") {
        system("sudo shutdown -h now");
      } else {
        $log->debug("Unknown command provided: $command");
    }
  }
   $self->redirect_to('/AmbiLight');
};


app->start;

__DATA__
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
<title>Ambilight management</title>
</head>
<body>

<h1> Ambilight control center </h1>
<h2>LED control (WS2801 pixel string)</h2>

<form action="/colorize" method=get>
  <p>
    <select name="LED" size="10" multiple>
      <% for (my $i = 1; $i <= 50; $i++) { %>
      <option value="<%=$i%>" selected>
      <%= $i %>
      </option>
      % } %>
    </select>
<p> Select a subset or all LEDs (all selected by default) </p>

<p>
<script type="text/javascript" src="/jscolor/jscolor.js"></script>
<script>
function setFocusToTextBox(){
    document.getElementById("color").focus();
    document.getElementById("turnon").focus();
    document.getElementById("color").focus();
}
</script>
<input name="color" class="color" id="color" value="<%= $current_color %>">
</p>
Default color: E90BF1.
<!-- have to add onclick method fo reset color from input with name color above
-->
<!-- onclick="$(color).focus() something like this -->
<p>
    <input type="submit" value="Turn lights on" id="turnon">
    <input type="reset" value="Reset selection" onclick="setFocusToTextBox()">
</p>
</form>

<br />
<br />

<h2> Power management </h2>
<form action="/control" method=get>
<p> Shutdown: 
<input type="submit" name="shutdown"/>
(Turn off Raspi)
</p> 
</form>

<form action="/control" method="get">
<p> Reboot:
<input type="submit" name="reboot"/>
(Restarts Raspi)
</p>
</form>




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
