
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'DBIx::Meld',
                       'DISTNAME' => 'DBIx-Meld',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Aran Deltac <bluefeet@gmail.com>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'An ORMish amalgamation.',
                       'EXE_FILES' => [],
                       'VERSION' => '0.07',
                       'PREREQ_PM' => {
                                        'SQL::Abstract' => '1.65',
                                        'SQL::Abstract::Limit' => '0.141',
                                        'namespace::autoclean' => '0.09',
                                        'Test::Exception' => '0.29',
                                        'DBIx::Connector' => '0.33',
                                        'Test::Simple' => '0.94',
                                        'Data::Page' => '2.02',
                                        'Module::Load' => '0.18',
                                        'MooseX::Types' => '0.21',
                                        'Clone' => '0.31',
                                        'List::MoreUtils' => '0.22',
                                        'Moose' => '1.01'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



