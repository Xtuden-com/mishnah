<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns="http://www.tei-c.org/ns/1.0" xmlns:its="http://www.w3.org/2005/11/its"
    xmlns:tei="http://www.tei-c.org/ns/1.0" exclude-result-prefixes="xd xs its tei" version="2.0">
    <xsl:output encoding="UTF-8" indent="no"/>
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Sep 24, 2011</xd:p>
            <xd:p><xd:b>Author:</xd:b> hlapin</xd:p>
            <xd:p/>
        </xd:desc>
    </xd:doc>
    
    
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="tei:body">
        <!-- Wraps whole body in div and p to create valid tei/xml on output -->
        <body>
            <div ana="temp">
                <p ana="temp">
                    <xsl:apply-templates/>
                </p>
            </div>
        </body>
    </xsl:template>
    <!-- Moves pb and cb to first position -->
    <!-- Not sure this is the best way to do this -->
    <xsl:template match="tei:div1[position()=1]">
        <pb>
            <xsl:attribute name="n">
                <xsl:value-of select=" descendant-or-self::tei:pb[1]/@n"/>
            </xsl:attribute>
        </pb>
        <xsl:if test="//tei:cb">
            <cb>
                <xsl:attribute name="n">
                    <xsl:value-of select=" descendant-or-self::tei:cb[1]/@n"/>
                </xsl:attribute>
            </cb>
        </xsl:if>
        <milestone unit="Order">
            <xsl:attribute name="xml:id">P_<xsl:value-of select="@xml:id"/></xsl:attribute>
        </milestone>
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    <xsl:template match="tei:pb[not(preceding::tei:pb)]">
    </xsl:template>
    <xsl:template match="tei:cb[not(preceding::tei:cb)]">
     </xsl:template>
    <xsl:template match="tei:div1[not(position()=1)]">
        <milestone unit="Order">
            <xsl:attribute name="xml:id">P_<xsl:value-of select="@xml:id"/></xsl:attribute>
        </milestone>
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    <xsl:template match="tei:div2">
        <milestone unit="Tractate">
            <xsl:attribute name="xml:id">P_<xsl:value-of select="@xml:id"/></xsl:attribute>
        </milestone>
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    <xsl:template match="tei:div3">
        <milestone unit="Chapter">
            <xsl:attribute name="xml:id">P_<xsl:value-of select="@xml:id"/></xsl:attribute>
        </milestone>
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    <xsl:template match="tei:ab">
        <milestone unit="ab">
            <xsl:attribute name="xml:id">P_<xsl:value-of select="@xml:id"/></xsl:attribute>
        </milestone>
        <!-- removing fw temporarily. will need to revisit -->
        <xsl:copy-of select="node() except tei:fw"/>
    </xsl:template>
    <xsl:template match="tei:head">
        <label>
            <xsl:attribute name="xml:id">P_<xsl:value-of select="@xml:id"/></xsl:attribute>
            <xsl:copy-of select="node()"/>
        </label>
    </xsl:template>
    <xsl:template match="tei:trailer">
        <label>
            <xsl:attribute name="xml:id">P_<xsl:value-of select="@xml:id"/></xsl:attribute>
            <xsl:copy-of select="node()"/>
        </label>
    </xsl:template>
    <!-- for now, removing fw. May need to be added. -->
    <xsl:template match="//tei:fw"></xsl:template>
    
    
</xsl:stylesheet>
