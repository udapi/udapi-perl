package Udapi::Tool::UDPipe;
use Udapi::Core::Common;
use Udapi::Core::Node::Root;
use Ufal::UDPipe;

has_ro model_file => (required=>1);

has_rw _model => ();
has_rw _tokenizer => ();

sub BUILD {
    my ($self, $args) = @_;
    my $model_file = $self->model_file;
    my $model = Ufal::UDPipe::Model::load($model_file);
    confess "Cannot load UDPipe model from file '$model_file'" if !$model;
    $self->set__model($model);
    my $tokenizer = $model->newTokenizer($Ufal::UDPipe::Model::DEFAULT);
    $self->set__tokenizer($tokenizer);
    return;
}

# Note that the variables with prefix "udpipe_"
# are not normal Perl variables, but Swig-magic tied hashes.
# So we can to use only the methods specified in UDPipe API to work with them.

sub tokenize {
    my ($self, $string) = @_;
    my $udpipe_sentence = Ufal::UDPipe::Sentence->new();
    my @forms;
    my $tokenizer = $self->_tokenizer;
    $tokenizer->setText($string);
    while ($tokenizer->nextSentence($udpipe_sentence)) {
        my $udpipe_words = $udpipe_sentence->{words};
        for my $i (1 .. $udpipe_words->size-1){
           my $udpipe_word = $udpipe_words->get($i);
           push @forms, $udpipe_word->{form};
           # TODO $udpipe_word->{misc} eq 'SpaceAfter=No'
         }
    }
    return @forms;
}

sub tag {
    my ($self, @nodes) = @_;
    my $udpipe_sentence = Ufal::UDPipe::Sentence->new();
    my $model = $self->_model;
    foreach my $form (map {$_->form} @nodes) {
        $udpipe_sentence->addWord($form);
    }

    $model->tag($udpipe_sentence, $Ufal::UDPipe::Model::DEFAULT);

    my $udpipe_words = $udpipe_sentence->{words};
    for my $i (1 .. $udpipe_words->size-1){
       my $udpipe_word = $udpipe_words->get($i);
       my $node = $nodes[$i-1];
       $node->set_upos($udpipe_word->{upostag});
       $node->set_xpos($udpipe_word->{xpostag});
       $node->set_lemma($udpipe_word->{lemma});
       $node->set_feats($udpipe_word->{feats});
     }
     return;
}

sub tokenize_tag_parse {
    my ($self, $root) = @_;
    my $string = $root->sentence;
    confess 'parse_sentence must be called on an empty tree' if $root->children;
    confess 'empty sentence' if !length $string;

    # tokenization (I cannot turn off segmenter, so I need to join the segments)
    my $tokenizer = $self->_tokenizer;
    $tokenizer->setText($string);
    my $udpipe_sentence = Ufal::UDPipe::Sentence->new();
    my $is_another = $tokenizer->nextSentence($udpipe_sentence) ;
    my $udpipe_words = $udpipe_sentence->{words};
    my $n_words = $udpipe_words->size - 1;
    if ($is_another) {
        my $udpipe_sent_cont = Ufal::UDPipe::Sentence->new();
        while ($tokenizer->nextSentence($udpipe_sent_cont)) {
            my $udpipe_words_cont = $udpipe_sent_cont->{words};
            my $n_cont = $udpipe_words_cont->size - 1;
            for my $i (1 .. $n_cont){
                my $udpipe_word = $udpipe_words_cont->get($i);
                $udpipe_word->{id} = ++$n_words;
                $udpipe_words->push($udpipe_word);
            }
        }
    }

    # tagging and parsing
    my $model = $self->_model;
    $model->tag($udpipe_sentence, $Ufal::UDPipe::Model::DEFAULT);
    $model->parse($udpipe_sentence, $Ufal::UDPipe::Model::DEFAULT);

    # converting UDPipe nodes to Udapi nodes
    my @heads;
    for my $i (1 .. $udpipe_words->size-1){
        my $uw = $udpipe_words->get($i);
        my $node = $root->create_child(
            form=>$uw->{form}, lemma=>$uw->{lemma}, upos=>$uw->{upostag},
            xpos=>$uw->{xpostag}, feats=>$uw->{feats}, deprel=>$uw->{deprel},
            deps=>$uw->{deps}, misc=>$uw->{misc},
        );
        push @heads, $uw->{head};
    }
    my @nodes = ($root, $root->descendants);
    foreach my $node ($root->descendants){
        $node->set_parent($nodes[shift @heads]);
    }
    return;
}

1;
