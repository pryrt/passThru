#!perl

use 5.014; # strict, //, s//r
use warnings;
use autodie;
use XML::LibXML;
use Data::Dump ();

$| = 1;
our %LanguageRequirements = language_requirements();

if(!@ARGV) {
    push @ARGV, $ENV{APPDATA} . '/Notepad++/stylers.xml';
}

for my $filename (@ARGV) {
    print "file($filename)\n";
    my $dom = XML::LibXML->load_xml(location => $filename, no_blanks => 1);
    my ($node_GlobalStyles) = $dom->findnodes('//GlobalStyles');
    my $gStyles = globalStyles_node_to_hashref($node_GlobalStyles);
    for my $lang ( keys %LanguageRequirements ) {
        my ($node_LexerType) = $dom->findnodes(sprintf '//LexerType[@name="%s"]', $lang);
        reconcileLanguage($node_LexerType, $LanguageRequirements{$lang}, $gStyles);
    }
}

sub globalStyles_node_to_hashref {
    my ($node) = @_;
    my $hashref = {};
    my ($node_default) = $node->findnodes('//WidgetStyle[@name="Default Style"]');
    # print $node_default->toString(1), "\n";
    for my $attr (qw/fgColor bgColor fontStyle/) {    # these need to be explicit copies of DefaultStyle
        $hashref->{$attr} = $node_default->{$attr} if exists $node_default->{$attr};
    }
    for my $attr (qw/fontName fontSize/) { # set these empty to automatically inherit from DefaultStyle
        $hashref->{$attr} = "";
    }
    return $hashref;
}

sub reconcileLanguage {
    my ($node, $req, $gStyles) = @_;
    printf "Need to check =>\n%s\nagainst =>\n%s\nusing styling =>\n%s\n", $node//'<undef>', Data::Dump::pp($req), Data::Dump::pp($gStyles);

    # find all the styles that are currently used (and rename any that don't match req)
    my %usedID;
    for my $node_WordsStyle ( $node->childNodes ) {
        # findnodes('//WordsStyle') uses whole DOM, not just the active node, so returns the whole document's WordsStyle elements
        # find('//WordsStyle') returned 'carp croak', which was useless.
        my $id = $node_WordsStyle->{styleID};
        my $reqName = $req->{$id}{name};
        my $rename = ($reqName eq $node_WordsStyle->{name}) ? "" : $reqName;
        $node_WordsStyle->{name} = $rename if length $rename;
        $node_WordsStyle->{keywordClass} = $req->{$id}{keywordClass} if exists $req->{$id}{keywordClass};
        printf "WordsStyle(%d,%s)\n", $id, $node_WordsStyle->{name};
        $usedID{$id} = $node_WordsStyle;
    }

    # loop through req elements, adding any that don't exist as children to $node
    for my $styleID (sort keys %$req) {
        next if exists $usedID{$styleID};
        printf "UnusedCategory(%d,%s) TODO = needs to be added\n", $styleID, $req->{$styleID}{name};
        my $newWordsStyle = XML::LibXML::Element->new('WordsStyle');
        $newWordsStyle->{name} = $req->{$styleID}{name};
        $newWordsStyle->{styleID} = $styleID;
        for my $attr ( qw/fgColor bgColor fontName fontStyle fontSize/ ) {
            $newWordsStyle->{$attr} = $gStyles->{$attr};
        }
        $newWordsStyle->{keywordClass} = $req->{$styleID}{keywordClass} if exists $req->{$styleID}{keywordClass};
        printf "\t%s\n", $newWordsStyle->toString();
        $node->addChild($newWordsStyle);
    }

    print "updated_node => \n", $node->toString(1), "\n";
}

sub language_requirements {
    my %req;
    $req{sql} = {
        0   => { name => "DEFAULT",                                             }, ##     <WordsStyle name="DEFAULT" styleID="0" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize="" />
        1   => { name => "COMMENT",                                             }, ##     <WordsStyle name="COMMENT" styleID="1" fgColor="008000" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" />
        2   => { name => "COMMENT LINE",                                        }, ##     <WordsStyle name="COMMENT LINE" styleID="2" fgColor="008000" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" />
        3   => { name => "COMMENT DOC",                                         }, ##     <WordsStyle name="COMMENT DOC" styleID="3" fgColor="008000" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" />
        4   => { name => "NUMBER",                                              }, ##     <WordsStyle name="NUMBER" styleID="4" fgColor="FF8000" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" />
        5   => { name => "KEYWORD",                 keywordClass => "instre1",  }, ##     <WordsStyle name="KEYWORD" styleID="5" fgColor="0000FF" bgColor="FFFFFF" fontName="" fontStyle="1" fontSize="" keywordClass="instre1" />
        6   => { name => "STRING",                                              }, ##     <WordsStyle name="STRING" styleID="6" fgColor="808080" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" />
        7   => { name => "STRING2",                                             }, ##     <WordsStyle name="STRING2" styleID="7" fgColor="808080" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" />
        8   => { name => "SQLPLUS",                 keywordClass => "type2",    }, ##     <WordsStyle name="SQLPLUS" styleID="8" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize="" keywordClass="type2" />
        9   => { name => "SQLPLUS_PROMPT",                                      }, ##     <WordsStyle name="SQLPLUS_PROMPT" styleID="9" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize="" />
        10  => { name => "OPERATOR",                                            }, ##     <WordsStyle name="OPERATOR" styleID="10" fgColor="000080" bgColor="FFFFFF" fontName="" fontStyle="1" fontSize="" />
        11  => { name => "IDENTIFIER",                                          }, ##     <WordsStyle name="IDENTIFIER" styleID="11" fgColor="FF0000" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" />
        13  => { name => "SQLPLUS_COMMENT",                                     }, ##     <WordsStyle name="SQLPLUS_COMMENT" styleID="13" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize="" />
        15  => { name => "COMMENTLINEDOC",                                      }, ##     <WordsStyle name="COMMENTLINEDOC" styleID="15" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize="" />
        16  => { name => "KEYWORD2",                keywordClass => "instre2",  }, ##     <WordsStyle name="KEYWORD2" styleID="16" fgColor="0000FF" bgColor="FFFFFF" fontName="" fontStyle="1" fontSize="" keywordClass="instre2" />
        17  => { name => "COMMENTDOCKEYWORD",       keywordClass => "type1",    }, ##     <WordsStyle name="COMMENTDOCKEYWORD" styleID="17" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize=""  keywordClass="type1" />
        18  => { name => "COMMENTDOCKEYWORDERROR",                              }, ##     <WordsStyle name="COMMENTDOCKEYWORDERROR" styleID="18" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize="" />
        19  => { name => "USER1",                   keywordClass => "type3",    }, ##     <WordsStyle name="USER1" styleID="19" fgColor="800080" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" keywordClass="type3" />
        20  => { name => "USER2",                   keywordClass => "type4",    }, ##     <WordsStyle name="SQL_USER2" styleID="20" fgColor="000000" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" keywordClass="type4" />
        21  => { name => "USER3",                   keywordClass => "type5",    }, ##     <WordsStyle name="SQL_USER3" styleID="21" fgColor="000000" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" keywordClass="type5" />
        22  => { name => "USER4",                   keywordClass => "type6",    }, ##     <WordsStyle name="SQL_USER4" styleID="22" fgColor="000000" bgColor="FFFFFF" fontName="" fontStyle="0" fontSize="" keywordClass="type6" />
        23  => { name => "QUOTEDIDENTIFIER",                                    }, ##     <WordsStyle name="QUOTEDIDENTIFIER" styleID="23" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize="" />
        24  => { name => "QOPERATOR",                                           }, ##     <WordsStyle name="QOPERATOR" styleID="24" fgColor="FF0000" bgColor="FF0000" fontName="" fontStyle="0" fontSize="" />
    };

    return %req;
}

__END__
C:\Users\PJones2\AppData\Roaming/Notepad++/stylers.xml




LexSQL.cxx#L411                                             // peter's comments
	case 0:                     wordListN = &keywords1;
	case 1:                     wordListN = &keywords2;
	case 2:                     wordListN = &kw_pldoc;      // pldoc is comment-based doc generation syntax: https://pldoc.sourceforge.net/maven-site/
	case 3:                     wordListN = &kw_sqlplus;
	case 4:                     wordListN = &kw_user1;
	case 5:                     wordListN = &kw_user2;
	case 6:                     wordListN = &kw_user3;
	case 7:                     wordListN = &kw_user4;

        langs.xml name="sql" excerpt, with my additions based on sql.properties
            <Keywords name="instre2"    pcj="keywords2: database objects" />
            <Keywords name="type1"      pcj="keywords3: kw_pldoc" >kw_pldoc param author since return see deprecated todo</Keywords>
            <Keywords name="type2"      pcj="keywords4: kw_sqlplus" >kw_sqlplus acc~ept a~ppend archive log attribute                     bre~ak bti~tle c~hange cl~ear col~umn comp~ute conn~ect copy def~ine del desc~ribe disc~onnect                     e~dit exec~ute exit get help ho~st i~nput l~ist passw~ord pau~se pri~nt pro~mpt                     quit recover rem~ark repf~ooter reph~eader r~un sav~e set sho~w shutdown spo~ol sta~rt startup store                     timi~ng tti~tle undef~ine var~iable whenever oserror whenever sqlerror</Keywords>
            <Keywords name="type3"      pcj="kw_user1">bfile bigint binary binary_integer bit blob bool boolean char char_base clob cursor date datetime datetime2 datetimeoffset day dec decimal double enum float hierarchyid image int integer interval long longblob longtext mediumblob mediumint mediumtext money nchar nclob ntext number numeric nvarchar precision raw real rowid smalldatetime smallint smallmoney sql_variant text time timestamp tinyblob tinyint tinytext uniqueidentifier urowid varbinary varchar varchar2 xml year</Keywords>
            <Keywords name="type4"      pcj="kw_user2">kw_user2 was_keywords5 dbms_output.disable dbms_output.enable dbms_output.get_line                     dbms_output.get_lines dbms_output.new_line dbms_output.put dbms_output.put_line</Keywords>
            <Keywords name="type5"      pcj="kw_user3" />
            <Keywords name="type6"      pcj="kw_user4" />


__MAP__
Maps keywordClass(stylers.xml) to LANG_INDEX (0-8) for which word list it is

	if (!lstrcmp(TEXT("instre1"), str)) return LANG_INDEX_INSTR;        // = 0;     // Parameters.h#L110 // Parameters.cpp#L597
	if (!lstrcmp(TEXT("instre2"), str)) return LANG_INDEX_INSTR2;       // = 1;
	if (!lstrcmp(TEXT("type1"), str)) return LANG_INDEX_TYPE;           // = 2;
	if (!lstrcmp(TEXT("type2"), str)) return LANG_INDEX_TYPE2;          // = 3;
	if (!lstrcmp(TEXT("type3"), str)) return LANG_INDEX_TYPE3;          // = 4;
	if (!lstrcmp(TEXT("type4"), str)) return LANG_INDEX_TYPE4;          // = 5;
	if (!lstrcmp(TEXT("type5"), str)) return LANG_INDEX_TYPE5;          // = 6;
	if (!lstrcmp(TEXT("type6"), str)) return LANG_INDEX_TYPE6;          // = 7;
	if (!lstrcmp(TEXT("type7"), str)) return LANG_INDEX_TYPE7;          // = 8;

