#!/usr/bin/perl
use strict;

use FindBin qw/$Bin/;
use Test::More;
use Test::SQL::Translator;
use Test::Exception;
use Data::Dumper;
use SQL::Translator;
use SQL::Translator::Schema::Constants;


BEGIN {
    maybe_plan(1, 'SQL::Translator::Parser::XML::SQLFairy',
              'SQL::Translator::Producer::DB2');
}

my $xmlfile = "$Bin/data/xml/schema.xml";

my $sqlt;
$sqlt = SQL::Translator->new(
    no_comments => 1,
    show_warnings  => 1,
    add_drop_table => 1,
);

die "Can't find test schema $xmlfile" unless -e $xmlfile;

my @sql = $sqlt->translate(
    from     => 'XML-SQLFairy',
    to       => 'DB2',
    filename => $xmlfile,
) or die $sqlt->error;

my $want = [ 'DROP TABLE Basic;',
q|CREATE TABLE Basic (
id INTEGER GENERATED BY DEFAULT AS IDENTITY (START WITH 1, INCREMENT BY 1) NOT NULL,
title VARCHAR(100) NOT NULL DEFAULT 'hello',
description VARCHAR(0) DEFAULT '',
email VARCHAR(255),
explicitnulldef VARCHAR(0),
explicitemptystring VARCHAR(0) DEFAULT '',
emptytagdef VARCHAR(0) DEFAULT '',
timest TIMESTAMP,
CONSTRAINT emailuniqueindex UNIQUE (email)   ,
 PRIMARY KEY(id)
);|,

'CREATE INDEX titleindex ON Basic ( title );',

'CREATE VIEW email_list AS
SELECT email FROM Basic WHERE email IS NOT NULL;',

'CREATE TRIGGER foo_trigger after insert ON Basic REFERENCING OLD AS oldrow NEW AS newrow FOR EACH ROW MODE DB2SQL update modified=timestamp();'
];

is_deeply(\@sql, $want, 'Got correct DB2 statements in list context');
