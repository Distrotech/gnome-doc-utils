<?xml version='1.0' encoding='utf-8'?><!-- -*- indent-tabs-mode: nil -*- -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:doc="http://www.gnome.org/~shaunm/xsldoc"
                exclude-result-prefixes="doc"
                version="1.0">

<doc:title>Automatic Tables of Contents</doc:title>


<!-- == db2html.autotoc.label ============================================== -->

<template xmlns="http://www.gnome.org/~shaunm/xsldoc">
  <name>db2html.autotoc.label</name>
  <purpose>
    Generate a label for an entry in a table of contents
  </purpose>
  <parameter>
    <name>node</name>
    <purpose>
      The element for which to generate a label
    </purpose>
  </parameter>
</template>

<xsl:template name="db2html.autotoc.label">
  <xsl:param name="node" select="."/>
  <xsl:apply-templates mode="db2html.autotoc.label.mode" select="$node"/>
</xsl:template>


<!-- == db2html.autotoc.label.mode ========================================= -->

<xsl:template mode="db2html.autotoc.label.mode" match="*">
  <!-- FIXME -->
  <span class="label">
    <xsl:call-template name="db.label"/>
    <xsl:text> </xsl:text>
  </span>
</xsl:template>


<!-- == db2html.autotoc ==================================================== -->

<template xmlns="http://www.gnome.org/~shaunm/xsldoc">
  <name>db2html.autotoc.flat</name>
  <purpose>
    Create a table of contents
  </purpose>
  <parameter>
    <name>node</name>
    <purpose>
      The node for which to create a table of contents
    </purpose>
  </parameter>
  <parameter>
    <name>info</name>
    <purpose>
      The info child element of <parameter>node</parameter>
    </purpose>
  </parameter>
  <parameter>
    <name>divisions</name>
    <purpose>
      The division-level child elements of <parameter>node</parameter>
    </purpose>
  </parameter>
  <parameter>
    <name>toc_depth</name>
    <purpose>
      How deep to create table of content entries
    </purpose>
  </parameter>
  <parameter>
    <name>depth_of_chunk</name>
    <purpose>
      The depth of the containing chunk in the document
    </purpose>
  </parameter>
</template>

<xsl:template name="db2html.autotoc">
  <xsl:param name="node" select="."/>
  <xsl:param name="info"/>
  <xsl:param name="divisions"/>
  <xsl:param name="toc_depth" select="1"/>
  <xsl:param name="depth_of_chunk">
    <xsl:call-template name="db.chunk.depth-of-chunk">
      <xsl:with-param name="node" select="$node"/>
    </xsl:call-template>
  </xsl:param>
  <!-- FIXME: fix up, do stuff with $info, etc. -->
  <div class="autotoc">
    <ul>
      <xsl:apply-templates mode="db2html.autotoc.mode" select="$divisions">
        <xsl:with-param name="toc_depth" select="$toc_depth - 1"/>
      </xsl:apply-templates>
    </ul>
  </div>
</xsl:template>


<!-- == db2html.autotoc.mode =============================================== -->

<xsl:template mode="db2html.autotoc.mode" match="*">
  <xsl:param name="toc_depth" select="0"/>
  <!-- FIXME -->
  <li>
    <a>
      <xsl:attribute name="href">
        <xsl:call-template name="db.xref.target">
          <xsl:with-param name="linkend" select="@id"/>
          <xsl:with-param name="target" select="."/>
        </xsl:call-template>
      </xsl:attribute>
      <xsl:call-template name="db2html.autotoc.label"/>
      <xsl:apply-templates select="title/node()"/>
    </a>
    <xsl:if test="$toc_depth &gt; 0">
      <xsl:call-template name="db2html.autotoc">
        <xsl:with-param name="toc_depth" select="$toc_depth"/>
      </xsl:call-template>
    </xsl:if>
  </li>
</xsl:template>

</xsl:stylesheet>
