#!/usr/bin/perl
use HTTP::Daemon;
use threads;

my $leases = '/var/lib/dhcpd/dhcpd.leases';
my $d = new HTTP::Daemon(LocalPort => 6868, Reuse => 1);

while (my $c = $d->accept) {
  threads->create(\&process_request, $c)->detach();
}

sub process_request {
  my $c = shift;
  while (my $r = $c->get_request(TRUE)) {
    if ($r->method eq 'GET') {
      my $ip = substr($r->url->path, 1);
      `sed -n '/\\s$ip\\s/,/}/p' $leases` =~ m/hardware ethernet\s([a-zA-Z0-9:]+)/;
      my $response;
      if (not defined $1) {
        $response = HTTP::Response->new(404);
        $response->content('');
      }
      else {
        $response = HTTP::Response->new(200);
        $response->header("Content-Type" => "text/plain");
        $response->content($1);
      }
      $c->send_response($response);
    }
    else {
      $c->send_error(RC_FORBIDDEN)
    }
  }
  $c->close;
  undef($c);
}

