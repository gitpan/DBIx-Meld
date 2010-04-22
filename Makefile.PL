
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
                       'VERSION' => '0.01',
                       'PREREQ_PM' => {
                                        'namespace::autoclean' => '0.09',
                                        'DBIx::Connector' => '0.33',
                                        'MooseX::Types' => '0.21',
                                        'SQL::Astract' => '1.65',
                                        'Moose' => '1.01'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



