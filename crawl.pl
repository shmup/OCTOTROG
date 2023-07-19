#!/usr/bin/env perl

use strict;
use Irssi;
use DBI;
use Try::Tiny;
use warnings;
use vars qw($VERSION %IRSSI);

no warnings qw{qw};

$VERSION = '1.00';
%IRSSI = (
    authors     => 'Jared Tyler Miller',
    contact     => 'jtmiller@gmail.com',
    name        => 'DCSS Bot Repeater',
    description => 'Repeats ##crawl bots ' .
                   'that reference a nick' .
                   'that you specify.',
    license     => 'Public Domain',
);

print CLIENTCRAP "loading crawl.pl $VERSION!";

my $bot_name = "ghost_of_shmup";
my $root_server = "slashnet";
my $root_chan = "#cats";
my $target_server = "slashnet";
my @target_chan = qw(#dogs);
my $db_location = "/home/jtm/.irssi/scripts/crawl.db";
my $ts = Irssi::server_find_tag($target_server);
my $rs = Irssi::server_find_tag($root_server);

my $dbh;

my %commands = (
    'Sizzell' => ['%whereis','%dump'],
    'Gretell' => ['@??','@whereis','@dump'],
    'Sequell' => ['!chars','!cmd','!cmdinfo','!deathsin','!gamesby','!gkills','!help','!hs',
                  '!keyworddef','!killratio','!killsby','!kw','!lg','!listgame','!lm','!locateall','!log','!nchoice','!nick','%rc','!streak',
                  '!title','!ttr','!ttyrec','!tv','!tvdef','!won'],
    'apocalypsebot' => ['!time'],
    'Henzell' => ['??','!abyss','!apt','!cdefine','!cheers','!cmdinfo','!coffee','!dump','!echo',
                  '!ftw','!function','!help','!idle','!learn','!macro','!messages','!nick',
                  '!rc','!rng','!seen','!send','!skill','!source','!tell','!time','!vault',
                  '!whereis','!wtf'],
    $bot_name => ['!watch', '!unwatch', '!watched', '!help', '!dbadd', '!dbremove', '?!', '!dblist', '$$'],
    'Cheibriados' => ['%??'],
    'OCTOTROG' => [],
    'shmup' => [],
    );

sub db_connect {
    $dbh = DBI->connect(
        "dbi:SQLite:dbname=$db_location",
        "",
        "",
        { RaiseError => 1}
    ) or die $DBI::errstr;
}

sub check_if_command {
    # check if $msg starts with a command
    my ($nick, $msg, $chan) = @_;
    my $count = 0;
    # look at all the bots
    for my $bot ( keys %commands ) {
        # look at all the commands
        foreach my $command ( @{ $commands{$bot} } ) {
            # if index of 0, means command belongs to X bot
            if ((index $msg, $command) eq 0) {
                # clean everything up (trim whitespace, add nick to command)
                my $clean_msg = add_to_command($nick, trim($msg), trim($command));
                # if it was our bot, figure out what to do
                if ($bot eq $bot_name) {
                    if ($command eq '!watch') {
                        add_nick(lc $clean_msg);
                    } elsif ($command eq '!unwatch') {
                        rem_nick(lc $clean_msg);
                    } elsif ($command eq '!watched') {
                        list_nicks();
                    } elsif ($command eq '!dbadd') {
                        add_learndb($clean_msg);
                    } elsif ($command eq '!dbremove') {
                        remove_learndb($clean_msg);
                    } elsif ($command eq '?!') {
                        get_learndb($clean_msg);
                    } elsif ($command eq '$$') {
                        test_db($clean_msg);
                    } elsif ($command eq '!dblist') {
                        get_dblist();
                    } elsif ($command eq '!help') {
                        public_msg($chan, uc 'type !cmdinfo to see a list of all the bot commands. '.
                                          '!watched will list all nicks being monitored. !watch/!unwatch to change list. '.
                                          '??death yak, ??death yak[2], @??death yak. !dbadd <thing>. ?!<thing>. praise be to trog.');
                    }
                } else {
                    private_msg($bot, $command . ' ' . $clean_msg);
                }
            }
        }
    }
}

sub add_nick {
    my $nick = shift;
    my @nicks = split(/ +/, Irssi::settings_get_str("crawlwatchnicks"));
    my $found_nick = 0;
    my $message;
    foreach my $n (@nicks) {
        if ($n eq $nick) {
            $found_nick = 1;
        }
    }

    if ($found_nick) {
        $message = uc $nick . ' already in watch list. praise be to trog.';
    } else {
        push @nicks, $nick;
        @nicks = sort @nicks;
        Irssi::settings_set_str("crawlwatchnicks", join(" ", @nicks));
        $message = uc 'i added ' . $nick . '. praise be to trog.';
    }
    public_msg($target_chan[0], $message);
}

sub rem_nick {
    my $nick = shift;
    my @nicks = split(/ +/, Irssi::settings_get_str("crawlwatchnicks"));
    my @new_nicks = ();
    my $found = 0;
    my $message;
    foreach my $n (@nicks) {
        if ($n ne $nick) {
            push @new_nicks, $n;
        } else {
            $message = uc 'i removed ' . $nick . '. praise be to trog.';
            $found = 1;
        }
    }
    if (!$found) {
        $message = uc 'no nick with that name';
    }

    public_msg($target_chan[0], $message);
    Irssi::settings_set_str("crawlwatchnicks", join(" ", @new_nicks));
}

sub list_nicks {
    public_msg($target_chan[0], uc 'i am watching ' . Irssi::settings_get_str("crawlwatchnicks") . '. praise be to trog.');
}

sub process_msg {
    my $msg = shift;
}

sub get_dblist {
    db_connect();

    my $query = $dbh->prepare("SELECT DISTINCT Name FROM Info")
        or die $DBI::errstr;

    $query->execute() or
        die "Couldn't execute query\n";

    my @records;

    while (my $hash_ref = $query->fetchrow_hashref) {
        push @records, $hash_ref->{Name};
    }

    @records = sort @records;

    my $message = 'DB List (?! <word>): ' . join(', ', @records);

    public_msg($target_chan[0], $message);

    $query->finish();
    $dbh->disconnect() or die "Failed to disconnect.\n";
}


sub get_learndb {
    my $name = shift;
    my $index = 0;

    if ( $name =~ /(.*)\[([0-9]+)\]?$/) {
        $name = $1;
        # subtract 1 because definitions are in 0 indexed array
        $index = $2 - 1;
    }

    db_connect();

    $name = trim($name);

    my $query = $dbh->prepare("SELECT desc FROM Info WHERE name = '$name'")
        or die $DBI::errstr;

    $query->execute() or
        die "Couldn't execute query\n";

    my @records;
    my $counter = 1;

    while (my $hash_ref = $query->fetchrow_hashref) {
        push @records, $hash_ref->{Desc};
    }

    my $message;

    if ($index + 1 > scalar @records || $index < 0) {
        $index = $index > 0 ? "[" . ($index+1) . "]" : "";
        $message = uc "there isn't a definition for " . $name . $index . " in my database.";
    } else {
       my @descriptions;

       foreach (@records) {
           my $result = $name . "[" . ($index + 1) . "/" . scalar @records . "]: " . $_;
           push @descriptions, $result;
       }
       $message = $descriptions[$index];
    }

    public_msg($target_chan[0], $message);

    $query->finish();
    $dbh->disconnect() or die "Failed to disconnect.\n";
}

sub test_db {
    my $parameters = shift;
    my $name;
    my $index = 0;
    my $desc;

    if ($parameters =~ /^(['"])(.*)\[([0-9]+)\]\1(.*)$/) {

        $name = trim($2);
        $index = trim($3);

        if ($4 ne "") {
            $desc = trim($4);
        }

    } elsif ($parameters =~ /^(.*)\[([0-9]+)\](.*)$/) {

        $name = trim($1);
        $index = trim($2);

        if ($3 ne "") {
            $desc = trim($3);
        }
    }
}

sub add_learndb {
    my $text = shift;
    my $name;
    my $desc;

    if ($text =~ /^(['"])(.*)\1(.*)$/) {
        if ($2 eq "" or $3 eq "") {
            public_msg($target_chan[0], uc 'you must specify both name and description');
            return;
        }
        $name = $2;
        $desc = $3;
        print $name;
        print $desc;
    } else {
        my @words = split(" ", $text);
        # learndb needs name + value, return if length is not greater than 1
        if (scalar @words < 2) {
            public_msg($target_chan[0], uc 'you must specify both name and description');
            return;
        }
        return unless scalar @words > 1;
        $name = $words[0];
        shift @words;
        $desc = join(' ', @words);
    }

    $name = trim($name);
    $desc = trim($desc);
    my $index;

    if ($name =~ /(.*)\[([0-9]+)\]?$/) {
        $name = $1;
        $index = $2;
        update_learndb($name, $desc, $index);
        return;
    }

    $name = lc $name;
    my $message;

    db_connect();
    print 'Inserting: ' . $name . ' - ' . $desc;
    my $sql = "INSERT INTO Info (Name, Desc) VALUES(?,?)";
    my $query = $dbh->prepare($sql);
    my $status = $query->execute($name, $desc);
    $dbh->disconnect();

    if ($status ne "0E0") {
        $message = 'ADDED => ' . $name . ': ' . $desc;
    } else {
        $message = uc 'failed to add';
    }

    public_msg($target_chan[0], $message);
}

sub remove_learndb {
    my $name = shift;
    $name = lc $name;
    my $index;
    my $message;

    if ($name =~ /(.*)\[([0-9]+)\]/) {
        $name = $1;
        $index = $2;
    } else {
        public_msg($target_chan[0], uc 'to delete you must refer to the index [#].');
        return;
    }

    db_connect();

    my $indexToRemove = $index - 1;

    my $sql = "DELETE FROM Info WHERE Id = (SELECT Id from (SELECT Id from Info WHERE Name = '$name' Order By ID limit $indexToRemove,1) as t)";
    my $query = $dbh->prepare($sql);
    my $status = $query->execute();
    if ($status eq "0E0") {
        $message = uc "there isn't a definition for " . $name . "[" . $index . "] in my database.";
    } else {
        $message = uc 'deleted => ' . $name . '[' . $index . ']';
    }
    public_msg($target_chan[0], $message);
    $dbh->disconnect();
}

sub update_learndb {
    my ($name, $desc, $index) = @_;
    db_connect();

    $name = lc $name;

    my $indexToUpdate = $index - 1;

    my $sql = "UPDATE Info set Desc = '$desc' WHERE Id = (SELECT Id from (SELECT Id from Info WHERE Name = '$name' Order By ID limit $indexToUpdate,1) as t)";
    # my $sql = "UPDATE Info set Desc = '$desc' WHERE (SELECT count(*) FROM Info as I WHERE I.Name = '$name') = $index";
    my $query = $dbh->prepare($sql);
    my $status = $query->execute();
    my $message;
    if ($status eq "0E0") {
        $message = uc "there isn't a definition for " . $name . "[" . $index . "] in my database.";
    } else {
        $message = uc 'updated => ' . $name . '[' . $index . ']: ' . $desc;
    }
    public_msg($target_chan[0], $message);
    $dbh->disconnect();
}

sub add_to_command {
    # stupid hack to add your nick to $msg if nick isn't provided
    my ($nick, $msg, $command) = @_;
    my $new_msg;
    if ($msg eq $command) {
        $new_msg = $nick;
    } else {
        $new_msg = substr($msg, length($command));
    }

    return trim($new_msg);
}

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub public_msg  {
    my ($chan, $msg) = @_;
    $ts->send_message($chan, $msg, 0);
}

sub private_msg {
    my ($bot, $msg) = @_;
    try {
            $rs->send_message($bot, $msg, 1)
    } catch {
            warn "caught error: $_";
    };
}

sub dispatch {
    my ($server, $msg, $nick, $mask, $chan) = @_;

    # if coming from target channel
    if (lc($chan) eq lc($target_chan[0])) {
        check_if_command($nick, trim($msg), $target_chan[0]);
    }

    # root channel
    if (lc($chan) eq lc($root_chan)) {
        # return unless the nick is in the keys
        return unless (grep {lc($_) eq lc($nick)} keys %commands);
        # return unless the $player is found in the $text
        return unless (grep { lc($msg) =~ /\b\Q$_\E\b/i } split(" ", Irssi::settings_get_str("crawlwatchnicks")));
        # return unless (grep {lc($msg) =~ lc($_)} split(/ +/, Irssi::settings_get_str("crawlwatchnicks")));
        # send command if $text contains any @player names
        foreach (@target_chan) {
            public_msg($_, $msg)
        }
    }
}

sub priv_dispatch {
    my ($server, $msg, $nick, $mask) = @_;
    # return unless the nick is in the keys
    if (grep {lc($_) eq lc($nick)} keys %commands) {
        public_msg($target_chan[0], $msg)
    } else {
        $server->send_message($nick, uc $bot_name . uc ' does not concern himself with private messages', 1)
    }
}

Irssi::signal_add("message public", "dispatch");
Irssi::signal_add("message private", "priv_dispatch");
Irssi::settings_add_str("crawlwatch", "crawlwatchnicks", "");

db_connect();
$dbh->do("CREATE TABLE IF NOT EXISTS Info(Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Desc TEXT NOT NULL)");
$dbh->disconnect();

print CLIENTCRAP "/set crawlwatchnicks ed edd eddy ...";
print CLIENTCRAP "Watched nicks: " . Irssi::settings_get_str("crawlwatchnicks");
