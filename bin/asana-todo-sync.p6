#! /usr/bin/env perl6
use v6.c;
use HTTP::UserAgent;
use JSON::Fast;


constant ASANA_API = "https://app.asana.com/api/1.0";

sub MAIN(Str :$project-file = '.asana-todo-sync.json') {
    die "Unable to find project file '$project-file'" unless $project-file.IO.f;
    my $project-conf = $project-file.IO.slurp.&from-json;

    my $key-file = "/home/sam/.asana-todo-sync/app-auth";
    my $key = $key-file.IO.slurp.chomp;

    my $ua = HTTP::UserAgent.new;
    $ua.timeout = 3;

    my $me = get $ua, $key, ASANA_API ~ "/users/me";
    say $me.perl;

    my $project = do {
        with .grep( -> $project { $project-conf<project-name> ~~ $project<name> }).head {
            $_
        }
        else {
            fail "No poject named $project-conf<project-name> found on your workspace:\n{ .gist }"
        }
    } given get($ua, $key, ASANA_API ~ "/projects");


    say $project.perl;

    my $new-task = post $ua, $key, ASANA_API ~ "/tasks", {
        assignee => $me<id>,
        projects => $project<id>,
        name     => "Test Task",
    };

    say $new-task.perl;
}

#! Generalised handler for user agent get requests
sub unpack-req($req) {
    if $req.is-success {
        $req.content.&from-json<data>
    }
    else {
        fail "Error in Asana query (Error: { $req.status-line } for [{ $req.request.method }] { $req.request.url }) { $req.content.&from-json<error> }";
    }
}

sub get(HTTP::UserAgent $ua, Str $auth, Str $url) {
    $ua.get($url, Authorization => "Bearer $auth").&unpack-req
}

sub post(HTTP::UserAgent $ua, Str $auth, Str $url, %form) {
    $ua.post($url, %form, Authorization => "Bearer $auth").&unpack-req
}
