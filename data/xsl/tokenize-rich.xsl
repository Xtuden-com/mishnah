<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:its="http://www.w3.org/2005/11/its"
    xmlns="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xd xs its local" version="2.0" xmlns:local="local-functions.uri">
    <xsl:strip-space elements="tei:w tei:reg tei:c tei:expan tei:g tei:note tei:label tei:gap tei:add tei:del tei:damage tei:unclear tei:gap" />
    <xsl:preserve-space elements="tei:space tei:seg tei:lb"/>
    <xsl:output indent="yes" method="xml" omit-xml-declaration="no" encoding="UTF-8"/>
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 25, 2011</xd:p>
            <xd:p><xd:b>Author:</xd:b> hlapin</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    <xsl:param name="rqs" select="'S07326=1&amp;S00483=2&amp;S01520=3'"
        />
    <xsl:param name="mcite" select="'4.3.9.8'"/>
    <xsl:variable name="cite" select="if (string-length($mcite) = 0) then '4.2.2.1' else $mcite"/>
    <xsl:variable name="witlist">
        <xsl:variable name="params">
            <xsl:call-template name="tokenize-params">
                <xsl:with-param name="src" select="$rqs"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:for-each select="$params/tei:sortWit[text()]">
            <xsl:sort select="@sortOrder"/>
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:variable>
    <xsl:template match="tei:text"/>
    <xsl:template match="tei:TEI/tei:teiHeader">
        <TEI xmlns:xi="http://www.w3.org/2001/XInclude">
            <teiHeader>
                <fileDesc>
                    <titleStmt>
                        <title>Title</title>
                    </titleStmt>
                    <publicationStmt>
                        <p>Publication Information</p>
                    </publicationStmt>
                    <sourceDesc>
                        <p>Information about the source</p>
                    </sourceDesc>
                </fileDesc>
            </teiHeader>
            <text>
                <body>
                    <div>
                        <xsl:attribute name="n">
                            <xsl:value-of select="$cite"/>
                        </xsl:attribute>
                        <xsl:variable name="uriList">
                            <xsl:call-template name="buildURI">
                                <xsl:with-param name="wits" select="//tei:witness[@corresp]"> </xsl:with-param>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:for-each select="$uriList/tei:uri">
                            <ab>
                                <xsl:attribute name="n" select="@n"/>
                                <!-- Extract text -->
                                <xsl:variable name="mExtract">
                                    <extract>
                                        <!-- Choose mechanism a workaround to Collatex's refusal of
                                            empty witnesses -->
                                        <xsl:choose>
                                            <!-- This one entirely a temporary kludge: if all of M is an addition -->
                                            <xsl:when test="document(.)/element()[self::tei:add and (not(following-sibling::element()[not(tei:add)]))]"><xsl:text>&#160;</xsl:text></xsl:when>
                                            <xsl:when test="document(.)/element()">
                                                <xsl:copy-of select="document(.)/node()|@*"/>
                                            </xsl:when>
                                            <xsl:otherwise><xsl:text>&#160;</xsl:text></xsl:otherwise>
                                        </xsl:choose>
                                        
                                        <!-- Previous version -->
                                        <!--<xsl:copy-of select="document(.)/node()|@*"/>-->
                                    </extract>
                                </xsl:variable>
                                <xsl:variable name="mPreproc-1">
                                    <!-- Preprocess pass 1. By sibling recursion (mode = "preproc-1")
                                    and processing within sibling nodes ("preproc-within"), convert
                                    to text + a few select elements. -->
                                    <xsl:apply-templates mode="preproc-1" select="$mExtract/tei:extract/node()[1]"/>
                                </xsl:variable>
                                <xsl:variable name="mTokenize">
                                    <xsl:apply-templates mode="tokenize" select="$mPreproc-1/node()[1]"/>
                                </xsl:variable>
                                <xsl:variable name="cleaned">
                                    <xsl:apply-templates select="$mTokenize/element()[1]" mode="final"/>
                                </xsl:variable>
                                <xsl:copy-of select="$cleaned"/>
                            </ab>
                        </xsl:for-each>
                    </div>
                </body>
            </text>
        </TEI>
    </xsl:template>
    <xsl:template match="node()" mode="preproc-1">
        <xsl:choose>
            <xsl:when test="self::text()">
                <xsl:value-of select="."/>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:c[(@rend != 'nonlettermark')] | self::tei:g[not(@ref = '#fill')]">
                <xsl:value-of select="."/>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:c[@rend = 'nonlettermark'] | self::tei:g[@ref = '#fill']">
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:quote">
                <xsl:apply-templates mode="preproc-within"/>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:w">
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:for-each select="node()">
                        <xsl:variable name="temp"><xsl:apply-templates select="." mode="preproc-within" /></xsl:variable>
                        <xsl:value-of select="translate(normalize-space($temp),' ','')"/>
                    </xsl:for-each>
                    <seg>
                        <xsl:copy-of select="node()"/>
                    </seg>
                    <reg>
                        <xsl:value-of select="translate(normalize-space(translate(.,'?סןוי','שם*')),' ','')"/>
                    </reg>
                </xsl:element>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::comment()">
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:persName">
                <xsl:apply-templates select="./node()" mode="preproc-within"/>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:pc">
                <xsl:element name="{name()}">
                    <xsl:if test="@type">
                        <xsl:attribute name="type" select="@type"/>
                    </xsl:if>
                </xsl:element>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:label">
                <xsl:element name="{name()}">
                    <xsl:value-of select="."/>
                </xsl:element>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1" xml:space="default"/>
            </xsl:when>
            <xsl:when test="self::tei:lb">
                <xsl:element name="{name()}">
                    <xsl:attribute name="n" select="./@n"/>
                </xsl:element>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:add"><xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/></xsl:when>
            <xsl:when test="self::tei:del"><xsl:value-of select="."/><xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/></xsl:when>
            <xsl:when test="self::tei:seg">
                <!-- Currently selects only "original" text. Can be altered to include to include
                    added corrected text as well. 
                    Can also be altered to deal with cases of known hands-->
                <!-- Have now added seg for poem-like text in columns. Need to verify that this does not cause errors -->
                <xsl:for-each select="node()">
                    <xsl:choose>
                        <xsl:when test="self::text()">
                            <xsl:copy-of select="."/>
                        </xsl:when>
                        <xsl:when test="self::tei:del | self::tei:sic"><xsl:value-of select="normalize-space(.)"/></xsl:when>
                        <xsl:when test="self::tei:add | self::tei:corr"/>
                        <xsl:otherwise>
                            <xsl:apply-templates select="./node()" mode="preproc-within" xml:space="default"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:choice[child::tei:abbr]">
                <xsl:variable name="expan" select="normalize-space(./tei:expan)"> </xsl:variable>
                <xsl:variable name="abbr" select="normalize-space(./tei:abbr)"> </xsl:variable>
                <xsl:choose>
                    <xsl:when test="not(contains($expan,' '))">
                        <w>
                            <xsl:value-of select="$abbr"/>
                            <expan>
                                <xsl:value-of select="$expan"/>
                            </expan>
                            <reg>
                                <xsl:value-of select="translate($expan,'?סןוי','*שם')"/>
                            </reg>
                        </w>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="tokenize-abbr">
                            <xsl:with-param name="abbr" select="$abbr"> </xsl:with-param>
                            <xsl:with-param name="src" select="$expan"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:choice[child::tei:orig and child::tei:reg]">
                <xsl:variable name="reg"><xsl:for-each select="tokenize(normalize-space(./tei:reg),' ')"><regToken><xsl:value-of select="."/></regToken></xsl:for-each></xsl:variable>
                <xsl:variable name="orig"><xsl:for-each select="tokenize(normalize-space(./tei:orig),' ')"><origToken><xsl:value-of select="."/></origToken></xsl:for-each></xsl:variable>
                <xsl:for-each select="$orig/tei:origToken">
                    <xsl:variable name="i" select="1+ count(preceding-sibling::*)"/>
                    <w><xsl:value-of select="."/><reg><xsl:value-of select="translate($reg/tei:regToken[$i],'?סןוי','*שם')"></xsl:value-of></reg></w></xsl:for-each>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:when test="self::tei:damage">
                <xsl:apply-templates select="./node()" mode="preproc-within" xml:space="default"/>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <!-- Nodes to be removed altogether-->
            <!-- NB includes fw  -->
            <xsl:when
                test="self::tei:g[@ref='#fill'] | self::tei:note | self::tei:space | self::tei:surplus | self::tei:milestone | self::tei:fw | self::comment()">
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="preproc-1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- These templates process nodes within the siblings selected by sibling recursion -->
    <xsl:template match="//tei:choice" mode="preproc-within">
        <!-- For abbreviations embedded in other nodes (e.g., persName) use this template -->
        <xsl:variable name="expan" select="normalize-space(./tei:expan)"/>
        <xsl:variable name="abbr" select="normalize-space(./tei:abbr)"/>
        <xsl:choose>
            <xsl:when test="not(contains($expan,' '))">
                <w>
                    <xsl:value-of select="$abbr"/>
                    <expan>
                        <xsl:value-of select="$expan"/>
                    </expan>
                    <reg>
                        <xsl:value-of select="translate($expan,'?סןוי','*שם')"/>
                    </reg>
                </w>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="tokenize-abbr">
                    <xsl:with-param name="abbr">
                        <xsl:value-of select="$abbr"/>
                    </xsl:with-param>
                    <xsl:with-param name="src">
                        <xsl:value-of select="$expan"/>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="//tei:ref" mode="preproc-within"/>
    <!-- This looks like a duplication -->
    <xsl:template match="tei:c[@type='nonlettermark']" mode="preproc-within"/>
    <xsl:template match="tei:g[@type='wordbreak'] | tei:c[@type='wordbreak'] | tei:metamark" mode="preproc-within"/>
    <xsl:template match="tei:g[@type!='wordbreak']" mode="preproc-within">
        <xsl:value-of select="."/>
    </xsl:template>
    
    
    <xsl:template match="tei:lb[not(parent::tei:w)] | tei:pb | tei:cb" mode="preproc-within">
        <xsl:element name="{name()}">
            <xsl:attribute name="n">
                <xsl:value-of select="./@n"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:lb[parent::tei:w]" mode="preproc-within" xml:space="default"></xsl:template>
    <xsl:template match="//tei:supplied | //tei:damageSpan | //tei:anchor | //tei:space | //tei:note | //tei:fw | //tei:surplus | //tei:metamark"
        mode="preproc-within"/>
    <xsl:template match="//tei:unclear | //tei:gap" mode="preproc-within">
        <xsl:text>[ ]</xsl:text>
    </xsl:template>
    <!-- Tokenize mode -->
    <xsl:template match="node()" mode="tokenize">
        <xsl:choose>
            <xsl:when test="self::text()">
                <xsl:variable name="string" select="normalize-space(replace(.,'\]\s*?\[',''))"/>
                <xsl:choose>
                    <xsl:when test="not(contains($string,' '))">
                        <w>
                            <xsl:value-of select="$string"/>
                            <reg>
                                <xsl:value-of select="translate($string,'?סןוי','*שם')"/>
                            </reg>
                        </w>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="tokenize-wds">
                            <xsl:with-param name="src" select="$string"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="tokenize"/>
            </xsl:when>
            
            <xsl:otherwise>
                <xsl:copy-of select="."/>
                <xsl:apply-templates select="following-sibling::node()[1]" mode="tokenize"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="element()" mode="final">
        <!-- sibling recursion to -->
        <!-- 1. remove any empty <w>s with no text -->
        <!-- 2. Concatenate or split shel, lefi-(kak), e-(ze/zo/zehu) [ke-(sad) for alignment] -->
        <!-- 3. regularize final alef to heh -->
        <xsl:choose>
            <!-- 1. remove any empty <w>s with no text -->
            <xsl:when test="self::tei:w[not(string(.))]">
                <xsl:apply-templates mode="final" select="following-sibling::element()[1]"/>
            </xsl:when>
            <!-- 2. Concatenate or split shel, lefi-(kak), ke-(sad) for alignment -->
            <!-- shel -->
            <xsl:when test="self::tei:w[normalize-space(text()) = 'של']">
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="./text()"/>
                    <xsl:element name="reg" namespace="http://www.tei-c.org/ns/1.0">
                        <xsl:value-of
                            select="concat(./tei:reg,
                            following-sibling::tei:w[normalize-space(text())][1]/tei:reg)"
                        />
                    </xsl:element>
                </xsl:element>
                <xsl:for-each
                    select="following-sibling::element() intersect
                    following-sibling::tei:w[normalize-space(text())][1]/preceding-sibling::element()">
                    <xsl:if test="not(self::tei:w[not(normalize-space(.))])">
                        <!-- Condition excludes empty <w>s -->
                        <xsl:copy-of select="."/>
                    </xsl:if>
                </xsl:for-each>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="following-sibling::tei:w[normalize-space(text())][1]/text()"/>
                    <xsl:element name="reg" namespace="http://www.tei-c.org/ns/1.0">
                        <xsl:text>–</xsl:text>
                    </xsl:element>
                    <xsl:if test="following-sibling::tei:w[normalize-space(text())][1]/tei:expan">
                        <xsl:element name="expan" namespace="http://www.tei-c.org/ns/1.0">
                            <xsl:value-of select="following-sibling::tei:w[normalize-space(text())][1]/tei:expan"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
                <xsl:apply-templates mode="final"
                    select="following-sibling::tei:w[normalize-space(text())][1]/following-sibling::element()[1]"/>
            </xsl:when>
            <xsl:when
                test="self::tei:w[normalize-space(text()) = 'לפי' and
                following-sibling::tei:w[normalize-space(text())][1]/tei:reg = 'כך']">
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="text()"/>
                    <reg>
                        <xsl:value-of
                            select="concat(tei:reg/text(),
                        following-sibling::tei:w[normalize-space(text())][1]/tei:reg/text())"
                        />
                    </reg>
                </xsl:element>
                <xsl:for-each
                    select="following-sibling::element() intersect
                    following-sibling::tei:w[normalize-space(text())][1]/preceding-sibling::element()">
                    <xsl:if test="not(self::tei:w[not(normalize-space(.))])">
                        <!-- Condition excludes empty <w>s -->
                        <xsl:copy-of select="."/>
                    </xsl:if>
                </xsl:for-each>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="following-sibling::tei:w[normalize-space(text())][1]/text()"/>
                    <reg>
                        <xsl:text>–</xsl:text>
                    </reg>
                    <xsl:if test="following-sibling::tei:w[normalize-space(text())][1]/tei:expan">
                        <xsl:element name="expan" namespace="http://www.tei-c.org/ns/1.0">
                            <xsl:value-of select="following-sibling::tei:w[normalize-space(text())][1]/tei:expan"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
                <xsl:apply-templates mode="final"
                    select="following-sibling::tei:w[normalize-space(text())][1]/following-sibling::element()[1]"/>
            </xsl:when>
            <xsl:when test="self::tei:w[text() = 'אי'] or self::tei:w[text() = 'ואי']">
                <!-- Match following <w> with forms of zeh -->
                <xsl:choose>
                    <!-- e zehu zohi -->
                    <xsl:when
                        test="starts-with(following-sibling::tei:w[normalize-space(text())][1]/text(),
                        'זהו') or
                        starts-with(following-sibling::tei:w[normalize-space(text())][1]/text(),
                        'זוהי') or starts-with(following-sibling::tei:w[normalize-space(text())][1]/text(),
                        'זהי')">
                        <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                            <xsl:value-of select="text()"/>
                            <reg>
                                <xsl:variable name="num"
                                    select="string-length(concat(tei:reg/text(),
                                    following-sibling::tei:w[normalize-space(text())][1]/tei:reg/text()))"/>
                                <xsl:value-of
                                    select="substring(concat(tei:reg/text(),
                                following-sibling::tei:w[normalize-space(text())][1]/tei:reg/text()),
                                1, $num
                                - 1)"
                                />ה </reg>
                            <xsl:copy-of select="* except tei:reg"/>
                        </xsl:element>
                        <xsl:for-each
                            select="following-sibling::element() intersect
                            following-sibling::tei:w[normalize-space(text())][1]/preceding-sibling::element()">
                            <xsl:if test="not(self::tei:w[not(normalize-space(.))])">
                                <!-- Condition excludes empty <w>s -->
                                <xsl:copy-of select="."/>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                            <xsl:value-of select="following-sibling::tei:w[normalize-space(text())][1]/text()"/>
                            <reg>
                                <xsl:text>–</xsl:text>
                            </reg>
                        </xsl:element>
                        <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                            <reg>
                                <xsl:text>–</xsl:text>
                            </reg>
                            <xsl:copy-of select="* except tei:reg"/>
                        </xsl:element>
                        <xsl:apply-templates mode="final"
                            select="following-sibling::tei:w[normalize-space(text())][1]/following-sibling::element()[1]"/>
                    </xsl:when>
                    <!-- e ze/zo hu/hi -->
                    <xsl:when
                        test="matches(following-sibling::tei:w[normalize-space(text())][2]/text(),'ה[וי]א')
                        and (following-sibling::tei:w[normalize-space(text())][1]/text() =
                        'זה') or (following-sibling::tei:w[normalize-space(text())][1]/text() =
                        'זו')">
                        <xsl:variable name="num"
                            select="string-length(concat(tei:reg/text(),
                            following-sibling::tei:w[normalize-space(text())][1]/tei:reg/text(),
                            following-sibling::tei:w[normalize-space(text())][2]/tei:reg/text()))"/>
                        <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                            <xsl:value-of select="text()"/>
                            <reg>
                                <xsl:value-of
                                    select="substring(concat(tei:reg/text(),
                                        following-sibling::tei:w[normalize-space(text())][1]/tei:reg/text(),
                                        following-sibling::tei:w[normalize-space(text())][2]/tei:reg/text()),
                                        1, $num - 1)"
                                />ה </reg>
                        </xsl:element>
                        <xsl:for-each
                            select="following-sibling::element() intersect
                                following-sibling::tei:w[normalize-space(text())][1]/preceding-sibling::element()">
                            <xsl:if test="not(self::tei:w[not(normalize-space(.))])">
                                <!-- Condition excludes empty <w>s -->
                                <xsl:copy-of select="."/>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                            <xsl:value-of select="following-sibling::tei:w[normalize-space(text())][1]/text()"/>
                            <reg>
                                <xsl:text>–</xsl:text>
                            </reg>
                            <xsl:if test="following-sibling::tei:w[normalize-space(text())][1]/tei:expan">
                                <xsl:element name="expan" namespace="http://www.tei-c.org/ns/1.0">
                                    <xsl:value-of
                                        select="following-sibling::tei:w[normalize-space(text())][1]/tei:expan"/>
                                </xsl:element>
                            </xsl:if>
                        </xsl:element>
                        <xsl:for-each
                            select="following-sibling::tei:w[normalize-space(text())][1]/following-sibling::element() intersect
                            following-sibling::tei:w[normalize-space(text())][2]/preceding-sibling::element()">
                            <xsl:if test="not(self::tei:w[not(normalize-space(.))])">
                                <!-- Condition excludes empty <w>s -->
                                <xsl:copy-of select="."/>
                            </xsl:if>
                        </xsl:for-each>
                        <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                            <xsl:value-of select="following-sibling::tei:w[normalize-space(text())][2]/text()"/>
                            <reg>
                                <xsl:text>–</xsl:text>
                            </reg>
                            <xsl:if test="following-sibling::tei:w[normalize-space(text())][2]/tei:expan">
                                <xsl:element name="expan" namespace="http://www.tei-c.org/ns/1.0">
                                    <xsl:value-of
                                        select="following-sibling::tei:w[normalize-space(text())][2]/tei:expan"/>
                                </xsl:element>
                            </xsl:if>
                        </xsl:element>
                        <xsl:apply-templates mode="final"
                            select="following-sibling::tei:w[normalize-space(text())][2]/following-sibling::element()[1]"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="."/>
                        <xsl:apply-templates mode="final" select="following-sibling::element()[1]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <!-- ezo/ezeh hi/hu-->
            <xsl:when
                test="matches(following-sibling::tei:w[normalize-space(text())][1],'ה[וי]א') and self::tei:w[contains(text(), 'איזה') or contains(text(),
                'איזו')]">
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="text()"/>
                    <reg>
                        <xsl:value-of select="tei:reg/text()"/>
                        <xsl:text>הה</xsl:text>
                    </reg>
                    <xsl:copy-of select="* except tei:reg"/>
                </xsl:element>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <reg>
                        <xsl:text>–</xsl:text>
                    </reg>
                </xsl:element>
                <xsl:for-each
                    select="following-sibling::element() intersect
                following-sibling::tei:w[normalize-space(text())][1]/preceding-sibling::element()">
                    <xsl:if test="not(self::tei:w[not(normalize-space(.))])">
                        <!-- Condition excludes empty <w>s -->
                        <xsl:copy-of select="."/>
                    </xsl:if>
                </xsl:for-each>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="following-sibling::tei:w[normalize-space(text())][1]/text()"/>
                    <reg>
                        <xsl:text>–</xsl:text>
                    </reg>
                </xsl:element>
                <xsl:apply-templates mode="final"
                    select="following-sibling::tei:w[normalize-space(text())][1]/following-sibling::element()[1]"/>
            </xsl:when>
            <!-- ezehu -->
            <xsl:when test="self::tei:w[contains(./text(), 'איזהו') or contains(./text(), 'אזהו')]">
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="text()"/>
                    <reg>אזהה</reg>
                    <xsl:copy-of select="* except tei:reg"/>
                </xsl:element>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <reg>
                        <xsl:text>–</xsl:text>
                    </reg>
                </xsl:element>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <reg>
                        <xsl:text>–</xsl:text>
                    </reg>
                </xsl:element>
                <xsl:apply-templates mode="final" select="following-sibling::element()[1]"/>
            </xsl:when>
            <!-- ezohi -->
            <xsl:when test="self::tei:w[contains(./text(), 'איזוהי') or contains(./text(), 'אזהי')]">
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="text()"/>
                    <reg>אזהה</reg>
                    <xsl:copy-of select="* except tei:reg"/>
                </xsl:element>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:text>–</xsl:text>
                    <reg>ז</reg>
                </xsl:element>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:text>–</xsl:text>
                    <reg>הה</reg>
                </xsl:element>
                <xsl:apply-templates mode="final" select="following-sibling::element()[1]"/>
            </xsl:when>
            <!-- ke-tsad. -->
            <!-- Note: have not added other variant spellings: kezeh tsad ke'e zeh tsad etc. -->
            <xsl:when
                test="self::tei:w[normalize-space(text()) = 'כי'] and
                following-sibling::tei:w[normalize-space(text())][1]/text() = 'צד'">
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="./text()"/>
                    <xsl:element name="reg" namespace="http://www.tei-c.org/ns/1.0">
                        <xsl:value-of
                            select="concat(tei:reg,
                            following-sibling::tei:w[normalize-space(text())][1]/tei:reg)"
                        />
                    </xsl:element>
                </xsl:element>
                <xsl:for-each
                    select="following-sibling::element() intersect
                    following-sibling::tei:w[normalize-space(text())][1]/preceding-sibling::element()">
                    <xsl:if test="not(self::tei:w[not(normalize-space(.))])">
                        <!-- Condition excludes empty <w>s -->
                        <xsl:copy-of select="."/>
                    </xsl:if>
                </xsl:for-each>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:copy-of select="following-sibling::tei:w[normalize-space(text())][1]/text()"/>
                    <xsl:element name="reg" namespace="http://www.tei-c.org/ns/1.0">
                        <xsl:text>–</xsl:text>
                    </xsl:element>
                    <xsl:if test="following-sibling::tei:w[normalize-space(text())][1]/tei:expan">
                        <xsl:element name="expan" namespace="http://www.tei-c.org/ns/1.0">
                            <xsl:value-of select="following-sibling::tei:w[normalize-space(text())][1]/tei:expan"/>
                        </xsl:element>
                    </xsl:if>
                </xsl:element>
                <xsl:apply-templates mode="final"
                    select="following-sibling::tei:w[normalize-space(text())][1]/following-sibling::element()[1]"/>
            </xsl:when>
            <!-- 3. regularize final alef to heh -->
            <xsl:when test="self::tei:w[substring(tei:reg/text(),string-length(tei:reg/text())) = 'א']">
                <xsl:variable name="num" select="string-length(tei:reg/text())"/>
                <xsl:element name="w" namespace="http://www.tei-c.org/ns/1.0">
                    <xsl:value-of select="text()"/>
                    <reg><xsl:value-of select="substring(tei:reg/text(),1,$num - 1)"/>ה</reg>
                    <xsl:copy-of select="* except tei:reg"/>
                </xsl:element>
                <xsl:apply-templates mode="final" select="following-sibling::element()[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
                <xsl:apply-templates mode="final" select="following-sibling::element()[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- recursively splits string into <token> elements -->
    <!-- Adapts a template from: http://www.usingxml.com/Transforms/XslTechniques -->
    <!-- Second and Third versions: one to deal with words in text nodes, another to process choice/abbr -->
    <xsl:template name="tokenize-wds">
        <xsl:param name="src"/>
        <xsl:choose>
            <xsl:when test="contains($src,' ')">
                <!-- build first token element -->
                <w>
                    <xsl:value-of select="translate(substring-before($src,' '),'?','*')"/>
                    <reg>
                        <xsl:value-of select="translate(substring-before($src,' '),'?סןוי','*שם')"/>
                    </reg>
                </w>
                <!-- recurse -->
                <xsl:call-template name="tokenize-wds">
                    <xsl:with-param name="src" select="translate(substring-after($src,' '),'?','*')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- last token, end recursion -->
                <w>
                    <xsl:value-of select="translate($src,'?','*')"/>
                    <reg>
                        <xsl:value-of select="translate($src,'?סןוי','*שם')"/>
                    </reg>
                </w>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="tokenize-abbr">
        <xsl:param name="src"/>
        <xsl:param name="abbr"/>
        <xsl:choose>
            <xsl:when test="contains($src,' ')">
                <!-- build first token element -->
                <w>
                    <xsl:value-of select="normalize-space($abbr)"/>
                    <expan>
                        <xsl:value-of select="normalize-space(translate(substring-before($src,' '),'?','*'))"/>
                    </expan>
                    <reg>
                        <xsl:value-of select="normalize-space(translate(substring-before($src,' '),'?סןוי','*שם'))"/>
                    </reg>
                </w>
                <!-- recurse -->
                <xsl:call-template name="tokenize-abbr">
                    <xsl:with-param name="src" select="translate(substring-after($src,' '),'?','*')"/>
                    <xsl:with-param name="abbr"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- last token, end recursion -->
                <w>
                    <expan>
                        <xsl:value-of select="normalize-space(translate($src,'?','*'))"/>
                    </expan>
                    <reg>
                        <xsl:value-of select="normalize-space(translate($src,'?סןוי','*שם'))"/>
                    </reg>
                </w>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Same technique used to tokenize the passed parameter data -->
    <xsl:template name="tokenize-params">
        <xsl:param name="src"/>
        <xsl:choose>
            <xsl:when test="contains($src,'&amp;')">
                <!-- build first token element -->
                <xsl:if test="not(contains(substring-before($src,'&amp;'),'mcite')) and not(contains(substring-before($src,'&amp;'),'algorithm'))">
                    <sortWit>
                        <xsl:attribute name="sortOrder">
                            <xsl:choose>
                                <xsl:when
                                    test="substring-after(substring-before($src,'&amp;'),'=')
                                =''">
                                    <xsl:value-of select="0"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="substring-after(substring-before($src,'&amp;'),'=')"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:attribute>
                        <xsl:value-of select="substring-before(substring-before($src,'&amp;'),'=')"/>
                    </sortWit>
                </xsl:if>
                <!-- recurse -->
                <xsl:call-template name="tokenize-params">
                    <xsl:with-param name="src" select="substring-after($src,'&amp;')"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <!-- last token, end recursion -->
                <sortWit>
                    <xsl:attribute name="sortOrder">
                        <xsl:choose>
                            <xsl:when test="substring-after($src,'=')
                            =''">
                                <xsl:value-of select="0"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="substring-after($src,'=')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:value-of select="substring-before($src,'=')"/>
                </sortWit>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="buildURI">
        <xsl:param name="wits"/>
        <xsl:for-each select="$witlist/tei:sortWit[@sortOrder != 0]">
            <xsl:sort select="@sortOrder"/>
            <xsl:variable name="curr-wit" select="current()/text()"/>
            <uri>
                <xsl:attribute name="n" select="$curr-wit"/>
                <xsl:text>../tei/</xsl:text>
                <xsl:value-of select="$wits[@xml:id =
                $curr-wit]/@corresp"/>
                <xsl:text>#</xsl:text>
                <xsl:value-of select="$curr-wit"/>
                <xsl:text>.</xsl:text>
                <xsl:value-of select="$cite"/>
            </uri>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>
