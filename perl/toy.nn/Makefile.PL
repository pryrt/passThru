use ExtUtils::MakeMaker;
use 5.014; # //, strict, say, s///r
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my %mm_args = (
    'NAME'          => 'ToyNN',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>',
    'ABSTRACT'      => 'ToyNN - Toy implementation of a multi-layer Perceptron neural network',
    'VERSION'       => '0.001',
    'PREREQ_PM'     => {
        'PDL'               => 2.025,
        'Exporter'          => 5.57,    # needed for `use Exporter qw(import);` notation
        'version'           => 0.77,
        'warnings'          => 0,
        'strict'            => 0,
        'constant'          => 0,
        'Carp'              => 0,
    },
    'realclean'     => {
        FILES => 'cover_db LICENSE.pod README.pod MYMETA.json.lock',
    },
    'META_MERGE'    => {            # EUMM 6.46
        'meta-spec' => {
            version => '2',
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        resources => {
            bugtracker => {
                mailto  => 'bug-CAD-Mesh3D@rt.cpan.org',
                web     => 'https://github.com/pryrt/passThru/issues',
            },
            repository => {
                url     => 'https://github.com/pryrt/passThru.git',
                web     => 'https://github.com/pryrt/passThru/perl/toy.nn',
                type    => 'git',
            },
        },
        keywords => [ qw/toy neural network perceptron backpropagation/ ],
        no_index => {
            directory   => [ 'patch' ], # don't include packages in patch/ in the indexer report
        },
        provides => {
            'ToyNN::PerceptronLayer' => { file => 'lib/ToyNN/PerceptronLayer.pm' },
            'ToyNN::PerceptronNetwork' => { file => 'lib/ToyNN/PerceptronNetwork.pm' },
        },
    },
    'LICENSE' => 'perl_5',          # EUMM 6.31
    'MIN_PERL_VERSION' => '5.14.0', # EUMM 6.48
    'CONFIGURE_REQUIRES' => {       # EUMM 6.52
        'ExtUtils::MakeMaker' => 0,
        'warnings' => 0,
        'strict' => 0,
        'Test::More' => 0.86,
        'constant' => 0,
    },
    'TEST_REQUIRES' => {            # EUMM 6.64
        'Test::More' => 0.86,
        'warnings' => 0,
        'strict' => 0,
        'constant' => 0,
        'Config' => 0,
    },
);

if(1) {
    # in most cases, delete from %mm_args rather than adding to the hash like I used to do
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION < '6.46' ) {
        delete $mm_args{META_MERGE};
    } else {
        # automatically determine the versions for 'provides'; MM->parse_version exists as of MM v6.31, so not a problem with >= 6.46
        my $v = ''.$mm_args{VERSION};
        for my $k ( keys %{ $mm_args{META_MERGE}{provides} }) {
            $mm_args{META_MERGE}{provides}{$k}{version} = $v;
        };
    }

    # simple deletions
    if( $ExtUtils::MakeMaker::VERSION < '6.31' ) {
        delete $mm_args{LICENSE};
    }
    if( $ExtUtils::MakeMaker::VERSION < '6.48' ) {
        delete $mm_args{MIN_PERL_VERSION};
    }

    # merge TEST_REQUIRES into CONFIGURE_REQUIRES, or both into PREREQ_PM
    if( $ExtUtils::MakeMaker::VERSION < '6.52' ) {
        $mm_args{PREREQ_PM} = {
            $mm_args{TEST_REQUIRES},
            $mm_args{CONFIGURE_REQUIRES},
            $mm_args{PREREQ_PM},
        };            # merge TEST and CONFIG into PREREQ
        delete $mm_args{CONFIGURE_REQUIRES};
        delete $mm_args{TEST_REQUIRES};
    } elsif( $ExtUtils::MakeMaker::VERSION < '6.64' ) {
        $mm_args{CONFIGURE_REQUIRES} = {
            $mm_args{TEST_REQUIRES},
            $mm_args{CONFIGURE_REQUIRES},
        } if exists $mm_args{CONFIGURE_REQUIRES};   # merge TEST into CONFIG
        delete $mm_args{TEST_REQUIRES};
    }

    # sign distro if able
    if( $ExtUtils::MakeMaker::VERSION >= '6.18' ) {
        $mm_args{SIGN} = 1 if MM->can('signature_target') && $ENV{MM_SIGN_DIST};
    }
}

sub MY::postamble {
    my (undef,%h) = @_;
    return <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

MY_COPYRIGHT = Copyright (C) 2023 Peter C. Jones

testcover :: lib/ToyNN/PerceptronNetwork.pm
	$(NOECHO) cover -test -report html

windebug ::
	$(NOECHO) for %f in ( t\*.t ) do $(NOECHO) (echo %f & perl %f & echo ----------)

# run author-tests on the original
authtest ::
	$(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# run author-tests on the distribution
distauthtest :: disttest
	cd $(DISTVNAME) && $(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# auto-populate the VERSION in the submodules from $(VERSION), which comes from main module
populateversion ::
	$(NOECHO) $(ECHO) want to auto-populate VERSION in all sub-modules: $(VERSION)
	$(PERL) -pi -e "s/^(\s*our\s+.VERSION\s*=).*?;.*?$$/\1 '$(VERSION)'; # auto-populated from Makefile.PL/" lib/ToyNN/PerceptronNetwork.pm lib/ToyNN/PerceptronLayer.pm

# auto-populate COPYRIGHT line
populatecopyright ::
	$(NOECHO) $(ECHO) want to auto-populate COPYRIGHT
	$(PERL) -pi -e "s/^\QCopyright (C)\E.*$$/$(MY_COPYRIGHT)/" lib/ToyNN/PerceptronNetwork.pm lib/ToyNN/PerceptronLayer.pm

# auto-generate the README from the module
README.md :: lib/ToyNN/PerceptronNetwork.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(README.pod));$$p->select({head1 => [qq(NAME),qq(SYNOPSIS),qq(DESCRIPTION),qq(TODO),qq(AUTHOR),qq(COPYRIGHT),qq(LICENSE)]});$$p->parse_file(qq(lib/ToyNN/PerceptronNetwork.pm));'
	pod2markdown README.pod README.md
	$(RM_F) README.pod

# auto-generate the LICENSE file from the module
LICENSE :: lib/ToyNN/PerceptronNetwork.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(LICENSE.pod));$$p->select({head1 => [qw/AUTHOR COPYRIGHT LICENSE/]});$$p->parse_file(qq(lib/ToyNN/PerceptronNetwork.pm));'
	pod2text LICENSE.pod LICENSE
	$(RM_F) LICENSE.pod

docs :: realclean manifest populateversion populatecopyright README.md LICENSE

POSTAMBLE
}

WriteMakefile( %mm_args )
