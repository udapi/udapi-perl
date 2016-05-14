package Udapi::Core::ScenarioParser;
use Udapi::Core::Common;

sub parse {
    my ($scen) = @_;
    my (@blocks, $params);

    while ($scen =~ /(\s+|[^=\s]+=?)/g) {
        my $token = $1;

        # 1. whitespace tokens
        if ($token =~ /^\s+$/){
            # nothing to do, just skip them
        }

        # 2. block names
        elsif ($token =~ /::/) {
            _err("'$token' not a proper Perl module name", \$scen) if $token !~ /^(\w+)?(::\w+)+$/;
            if ($token !~ s/^:://) {
                $token = "Udapi::Block::$token";
            }
            $params = [];
            push @blocks, {block_name=>$token, block_parameters=>$params};
        }

        # 3. *.scen files
        elsif ($token =~ /.scen$/){
            _err("*.scen not implemented yet ($token)", \$scen);
        }

        # 4. parameters
        elsif ($token =~ s/=$//){
            _err("'$token' not a proper parameter name", \$scen) if $token !~ /^\w+$/;
            my $param_name = $token;
            my $param_value;

            # 4a double quoted parameter value
            if ($scen =~ /\G"/gc) {
                if ($scen =~ /\G((?:[^"\\]|\\.)*)"/gc){
                    $param_value = $1;
                    $param_value =~ s{\\"}{"};
                    # TODO \n,\t? or should it be responsibility of blocks to interpret these sequences?
                } else {
                    _err("parameter $param_name does not have properly quoted value", \$scen);
                }
            }

            # 4b single quoted parameter value
            elsif ($scen =~ /\G'/gc) {
                if ($scen =~ /\G((?:[^'\\]|\\.)*)'/gc){
                    $param_value = $1;
                    $param_value =~ s{\\'}{'};
                } else {
                    _err("parameter $param_name does not have properly quoted value", \$scen);
                }
            }
            # 4c unquoted parameter value
            elsif ($scen =~ /\G(\S*)/gc) {
                $param_value = $1;
            }
            # 4d no valid value parameter value
            else {
                _err("parameter $param_name does not have a proper value", \$scen);
            }
            push @$params, [$param_name => $param_value];
        }

        # 5. comments
        elsif ($token =~ /^#/){
            $scen =~ /\G[^\n]*\n/gc;
        }

        # 6. other tokens
        else {
            _err("Unrecognized token '$token'", \$scen);
        }
    }

    return @blocks;
}

sub _err {
    my ($msg, $scen_ref) = @_;
    my $pos = pos $$scen_ref;
    my $hint;
    if (!defined $pos){
        $hint = "Could not find position of the error. The full scenario is:\n".$$scen_ref;
    } else {
        my $start = max(0, $pos-20);
        my $pos_in_context = $pos - $start;
        my $context = substr $$scen_ref, $start, 40;
        my $newlines = $context =~ tr/\n//d;
        $pos_in_context -= $newlines;
        $hint = "Near:\n$context\n". (' ' x $pos_in_context) . " <---HERE";
    }
    confess "Error in parsing scenario: $msg\n$hint\n";
}

1;