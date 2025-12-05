<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns="urn:isbn:1-931666-22-9"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:xlink="http://www.w3.org/1999/xlink" 
    xmlns:local="http://some.local.functions"
    exclude-result-prefixes="#all" version="2.0">
    
    <!--Version: 3.3.1 -->
    <!-- Author: kennedyn + etc
         Transforms ASpace EAD to SI EAD -->
    <!-- Created on: 2017-11-17, to clean issues in EAD exported from ArchivesSpace.
            Updated on: 2018-09-17, to support ArchivesSpace 2.5 exports (DAO attributes).
            Updated on: 2018-10-15, 2020-07-10 to adjust extent types.
            Updated on: 2020-10-09, to adjust pluralization
            Updated on: 2021-11-12, to support ARKs in unitid.
            Updated on: 2023-07-05, to adjust plurlization + remove sorting of DAOs, since ASpace can handle that now.
            Updated on: 2025-12-24, to normalize xlink:role attribute on DAOs, for new MADS links
    -->
    
    <!--
        *******************************************************************
        *                                                                 *
        * VERSION:          Tested for ASpace Version 3.3.1               *
        *                                                                 *
        * DATE:             2025-12-24                                    *
        *                                                                 *
        * ABOUT:            This file has been created for use with       *
        *                   EAD xml files exported from the               *
        *                   ArchivesSpace.                                *
        *                                                                 *
        *******************************************************************
    -->
    
    
    <xsl:output method="xml" encoding="utf-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <!--  identity transformation -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:variable name="base-uri" select="base-uri(.)"/>
    <xsl:variable name="document-uri" select="document-uri(.)"/>
    <xsl:variable name="filename" select="replace((tokenize($document-uri,'/'))[last()],'.xml','')"/>
    
<!-- STEP 1: Basic Display fixes - plurals, extra tags that we don't really want to display, but are harmless -->    
    <!-- display fix: plural extent types.
        1. Adjust the 1st extent element ouput for each physdesc (because 1st is the structured input, 2nd is container summary). 
        2. Do not display extent numbers when number is 0 -->
    <xsl:template match="ead:extent[1][@type]
                                    [matches(., '^\d')]
                                    [not(matches(.,'-$'))]
                                    [not(matches(lower-case(@type),'undetermined'))]">
                                    
        <xsl:variable name="extent-type" select="@type"/>
        <xsl:if test="$extent-type">
            <xsl:variable name="extent-number" 
                select="number(replace(normalize-space(.),$extent-type,''))"/>
            
            <extent>
            <xsl:copy-of select="@*"/>
            <xsl:choose>               
                <xsl:when test="$extent-number = 0">
                    <xsl:value-of select="$extent-type"/>
                </xsl:when>
                <xsl:when test="$extent-number gt 0">
                    <xsl:value-of select="format-number($extent-number, '#,##0.###')"/>
                    <xsl:text> </xsl:text>
                    <xsl:choose>
                        <!--changes feet to foot for singular extents-->
                        <xsl:when test="$extent-number eq 1 and contains($extent-type, 'feet')">
                            <xsl:value-of select="replace($extent-type, 'feet', 'foot')"/>
                        </xsl:when>
                        <!--changes boxes to box for singular extents-->
                        <xsl:when test="$extent-number eq 1 and contains($extent-type, 'boxes')">
                            <xsl:value-of select="replace($extent-type, 'boxes', 'box')"/>
                        </xsl:when>
                        <!--the following should not be an extent type, but until that's changed in the AT-->
                        <xsl:when test="$extent-number eq 1 and contains($extent-type, 'inches')">
                            <xsl:value-of select="replace($extent-type, 'inches', 'inch')"/>
                        </xsl:when>
                        <!-- change sketches to sketch for singular extents... but we need to re-do this whole process since we have issues, now, with captilizations that we needn't have.-->
                        <xsl:when test="$extent-number eq 1 and contains($extent-type, 'Sketches')">
                            <xsl:value-of select="replace($extent-type, 'Sketches', 'Sketch')"/>
                        </xsl:when>
                        <!--changes works to work for the "Works of art" extent type, if this is used-->
                        <xsl:when test="$extent-number eq 1 and contains($extent-type, 'works of art')">
                            <xsl:value-of select="replace($extent-type, 'works', 'work')"/>
                        </xsl:when>
                        <!--updates the trailing 'ies' for singular extents-->
                        <xsl:when test="$extent-number eq 1 and ends-with($extent-type, 'ies')">
                            <xsl:value-of select="replace($extent-type, 'ies$', 'y')"/>
                        </xsl:when>
                        <!--chops off the trailing 's' for singular extents-->
                        <xsl:when test="$extent-number eq 1 and ends-with($extent-type, 's')">
                            <xsl:variable name="sl" select="string-length($extent-type)"/>
                            <xsl:value-of select="substring($extent-type, 1, $sl - 1)"/>
                        </xsl:when>
                        <!--chops off the trailing 's' for singular extents that are in AAT form, with a paranthetical qualifer-->
                        <xsl:when test="$extent-number eq 1 and ends-with($extent-type, ')')">
                            <xsl:value-of select="replace($extent-type, 's \(', ' (')"/>
                        </xsl:when>
                        
                        <!--any other irregular singular/plural extent type names???-->
                        
                        <!-- yes, we also have:
                            Cartes-de-viste (card photographs)
                            
                            carte-de-viste (card photograph)
                            
                            to handle
                        
                        But before we do that, update the EAD export process to make sure that we serialize the database value into EAD's attribute value
                        rather than the YML translation value (which only belongs in the text node)
                        
                        And we also need to move toward URI-based controlled value lists....
                        
                        -->
                        
                        <!--otherwise, just print out the childless text node as is-->
                        <xsl:otherwise>
                            <xsl:value-of select="$extent-type"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </extent>
        </xsl:if>
    </xsl:template>
    
    <!-- display fix: drop titleproper num tag -->
    <xsl:template match="/ead:ead/ead:eadheader[1]/ead:filedesc[1]/ead:titlestmt[1]/ead:titleproper/ead:num"/>
        
    <!-- display fix: remove ASpace generated internal unitid with AT database id -->
    <xsl:template match="ead:unitid[@audience='internal']
        [starts-with(@type,'Archivists Toolkit Database')]"/>

 <!-- STEP 1.b: Basic Display sorting, 
     until / unless aspace export can provide sort ordering. 
     Sorting for DAOs now removed, since sorting can be managed by ArchivesSpace
 -->
    <!-- except for the new AAA daogrp link pairs.  ideally these should be sorted in ASpace, but since right now they are not, we can sort by URL here before finalizing the EAD output -->
    <!--
        xlink:href web-resource-link
        tokenize(., '-')[last()]
        cast as int
        sort
    -->


<!-- STEP 2:  TEMPORARY fixes (until we have time to adjust downstream EDAN, CSC, SOVA)-->
    <!-- TEMP - remove 'aspace_eadid_' prefix -->
    <xsl:template match="ead:c">
        <xsl:copy>
            <xsl:variable name="component_prefix" select="concat('aspace_',/ead:ead/ead:eadheader/ead:eadid,'_')"/>
            
            <xsl:for-each select="@*[not(local-name() = 'id')]">
                <xsl:attribute name="{local-name()}" 
                    select="."/>
            </xsl:for-each>
            <xsl:choose> 
                <xsl:when test="starts-with(@id,'aspace')">
                    <xsl:attribute name="id">
                        <xsl:value-of select="replace(lower-case(@id),lower-case($component_prefix),'')"/>
                    </xsl:attribute>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="@id"/>
                </xsl:otherwise>
            </xsl:choose>
            
            <xsl:apply-templates/>
            
        </xsl:copy>
        
        
    </xsl:template>
    
    <!-- TEMP - remove 'URL:" text inserted into the address line -->
    <xsl:template match="ead:addressline[starts-with(.,'URL:')]">
        <xsl:copy>
            <xsl:apply-templates select="ead:extptr"/>
        </xsl:copy>
    </xsl:template>
    
    <!-- TEMP - till SOVA updates for unitid level -->
    <xsl:template match="ead:c[@level='series']/ead:did/ead:unitid
        [not(@audience='internal')][not(starts-with(@type,'ark'))]
        [not(starts-with(.,local:uppercase-first-word(ancestor::ead:c[1]/@level)))]">
        <xsl:copy>
            <xsl:value-of select="concat(
                local:uppercase-first-word( ancestor::ead:c[1]/@level),
                ' ',
                .)"/>
        </xsl:copy>
    </xsl:template>

    
    <!-- TEMP - align containers with AT model - temporary / shortterm -->
    <xsl:template match="ead:container"> 
        <xsl:variable name="top_container">
            <xsl:choose>
                <xsl:when test="@label">
                    <xsl:value-of select="@id"></xsl:value-of>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="preceding-sibling::ead:container[@label][1]/@id"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable> 
        
        <xsl:copy>
            <xsl:if test="@id[not(../@parent)]">
                <xsl:attribute name="id" select="$top_container"/>
            </xsl:if>
            <xsl:if test="@parent">
                <xsl:attribute name="parent"
                    select="$top_container"/>
            </xsl:if>
            <xsl:if test="@type">
                <xsl:attribute name="type" select="local:uppercase-first-word(@type)"/>
            </xsl:if>
            <xsl:if test="@label">
                <xsl:attribute name="label" select="local:uppercase-first-word(@label)"/>
            </xsl:if>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    
    <!-- TEMP - align name @role with AT model - temporary / shortterm.  And, replace underscores -->
    <!-- https://github.com/archivesspace/archivesspace/blob/80952a89220c2eabdf33e3ba257a9992e1c7823c/backend/app/exporters/serializers/ead.rb#L336 -->
    <xsl:template match="ead:persname[@role] | ead:corpname[@role] | ead:famname[@role] | ead:name[@role]">
        <xsl:copy>
            <xsl:attribute name="role">
                <xsl:choose>
                    <xsl:when test="@role = 'acp'">Art copyist (acp)</xsl:when>
                    <xsl:when test="@role = 'act'">Actor (act)</xsl:when>
                    <xsl:when test="@role = 'adp'">Adapter (adp)</xsl:when>
                    <xsl:when test="@role = 'aft'">Author of afterword, colophon, etc. (aft)</xsl:when>
                    <xsl:when test="@role = 'anl'">Analyst (anl)</xsl:when>
                    <xsl:when test="@role = 'anm'">Animator (anm)</xsl:when>
                    <xsl:when test="@role = 'ann'">Annotator (ann)</xsl:when>
                    <xsl:when test="@role = 'ant'">Bibliographic antecedent (ant)</xsl:when>
                    <xsl:when test="@role = 'app'">Applicant (app)</xsl:when>
                    <xsl:when test="@role = 'aqt'">Author in quotations or text abstracts (aqt)</xsl:when>
                    <xsl:when test="@role = 'arc'">Architect (arc)</xsl:when>
                    <xsl:when test="@role = 'ard'">Artistic director (ard)</xsl:when>
                    <xsl:when test="@role = 'arr'">Arranger (arr)</xsl:when>
                    <xsl:when test="@role = 'art'">Artist (art)</xsl:when>
                    <xsl:when test="@role = 'asg'">Assignee (asg)</xsl:when>
                    <xsl:when test="@role = 'asn'">Associated name (asn)</xsl:when>
                    <xsl:when test="@role = 'att'">Attributed name (att)</xsl:when>
                    <xsl:when test="@role = 'auc'">Auctioneer (auc)</xsl:when>
                    <xsl:when test="@role = 'aud'">Author of dialog (aud)</xsl:when>
                    <xsl:when test="@role = 'aui'">Author of introduction, etc. (aui)</xsl:when>
                    <xsl:when test="@role = 'aus'">Author of screenplay, etc. (aus)</xsl:when>
                    <xsl:when test="@role = 'aut'">Author (aut)</xsl:when>
                    <xsl:when test="@role = 'bdd'">Binding designer (bdd)</xsl:when>
                    <xsl:when test="@role = 'bjd'">Bookjacket designer (bjd)</xsl:when>
                    <xsl:when test="@role = 'bkd'">Book designer (bkd)</xsl:when>
                    <xsl:when test="@role = 'bkp'">Book producer (bkp)</xsl:when>
                    <xsl:when test="@role = 'blw'">Blurb writer (blw)</xsl:when>
                    <xsl:when test="@role = 'bnd'">Binder (bnd)</xsl:when>
                    <xsl:when test="@role = 'bpd'">Bookplate designer (bpd)</xsl:when>
                    <xsl:when test="@role = 'bsl'">Bookseller (bsl)</xsl:when>
                    <xsl:when test="@role = 'ccp'">Conceptor (ccp)</xsl:when>
                    <xsl:when test="@role = 'chr'">Choreographer (chr)</xsl:when>
                    <xsl:when test="@role = 'clb'">Collaborator (clb)</xsl:when>
                    <xsl:when test="@role = 'cli'">Client (cli)</xsl:when>
                    <xsl:when test="@role = 'cll'">Calligrapher (cll)</xsl:when>
                    <xsl:when test="@role = 'clr'">Colorist (clr)</xsl:when>
                    <xsl:when test="@role = 'clt'">Collotyper (clt)</xsl:when>
                    <xsl:when test="@role = 'cmm'">Commentator (cmm)</xsl:when>
                    <xsl:when test="@role = 'cmp'">Composer (cmp)</xsl:when>
                    <xsl:when test="@role = 'cmt'">Compositor (cmt)</xsl:when>
                    <xsl:when test="@role = 'cnd'">Conductor (cnd)</xsl:when>
                    <xsl:when test="@role = 'cng'">Cinematographer (cng)</xsl:when>
                    <xsl:when test="@role = 'cns'">Censor (cns)</xsl:when>
                    <xsl:when test="@role = 'coe'">Contestant-appellee (coe)</xsl:when>
                    <xsl:when test="@role = 'col'">Collector (col)</xsl:when>
                    <xsl:when test="@role = 'com'">Compiler (com)</xsl:when>
                    <xsl:when test="@role = 'con'">Conservator (con)</xsl:when>
                    <xsl:when test="@role = 'cos'">Contestant (cos)</xsl:when>
                    <xsl:when test="@role = 'cot'">Contestant-appellant (cot)</xsl:when>
                    <xsl:when test="@role = 'cov'">Cover designer (cov)</xsl:when>
                    <xsl:when test="@role = 'cpc'">Copyright claimant (cpc)</xsl:when>
                    <xsl:when test="@role = 'cpe'">Complainant-appellee (cpe)</xsl:when>
                    <xsl:when test="@role = 'cph'">Copyright holder (cph)</xsl:when>
                    <xsl:when test="@role = 'cpl'">Complainant (cpl)</xsl:when>
                    <xsl:when test="@role = 'cpt'">Complainant-appellant (cpt)</xsl:when>
                    <xsl:when test="@role = 'cre'">Creator (cre)</xsl:when>
                    <xsl:when test="@role = 'crp'">Correspondent (crp)</xsl:when>
                    <xsl:when test="@role = 'crr'">Corrector (crr)</xsl:when>
                    <xsl:when test="@role = 'csl'">Consultant (csl)</xsl:when>
                    <xsl:when test="@role = 'csp'">Consultant to a project (csp)</xsl:when>
                    <xsl:when test="@role = 'cst'">Costume designer (cst)</xsl:when>
                    <xsl:when test="@role = 'ctb'">Contributor (ctb)</xsl:when>
                    <xsl:when test="@role = 'cte'">Contestee-appellee (cte)</xsl:when>
                    <xsl:when test="@role = 'ctg'">Cartographer (ctg)</xsl:when>
                    <xsl:when test="@role = 'ctr'">Contractor (ctr)</xsl:when>
                    <xsl:when test="@role = 'cts'">Contestee (cts)</xsl:when>
                    <xsl:when test="@role = 'ctt'">Contestee-appellant (ctt)</xsl:when>
                    <xsl:when test="@role = 'cur'">Curator of an exhibition (cur)</xsl:when>
                    <xsl:when test="@role = 'cwt'">Commentator for written text (cwt)</xsl:when>
                    <xsl:when test="@role = 'dbp'">Distribution place (dbp)</xsl:when>
                    <xsl:when test="@role = 'dfd'">Defendant (dfd)</xsl:when>
                    <xsl:when test="@role = 'dfe'">Defendant-appellee (dfe)</xsl:when>
                    <xsl:when test="@role = 'dft'">Defendant-appellant (dft)</xsl:when>
                    <xsl:when test="@role = 'dgg'">Degree grantor (dgg)</xsl:when>
                    <xsl:when test="@role = 'dis'">Dissertant (dis)</xsl:when>
                    <xsl:when test="@role = 'dln'">Delineator (dln)</xsl:when>
                    <xsl:when test="@role = 'dnc'">Dancer (dnc)</xsl:when>
                    <xsl:when test="@role = 'dnr'">Donor (dnr)</xsl:when>
                    <xsl:when test="@role = 'dpc'">Depicted (dpc)</xsl:when>
                    <xsl:when test="@role = 'dpt'">Depositor (dpt)</xsl:when>
                    <xsl:when test="@role = 'drm'">Draftsman (drm)</xsl:when>
                    <xsl:when test="@role = 'drt'">Director (drt)</xsl:when>
                    <xsl:when test="@role = 'dsr'">Designer (dsr)</xsl:when>
                    <xsl:when test="@role = 'dst'">Distributor (dst)</xsl:when>
                    <xsl:when test="@role = 'dtc'">Data contributor (dtc)</xsl:when>
                    <xsl:when test="@role = 'dte'">Dedicatee (dte)</xsl:when>
                    <xsl:when test="@role = 'dtm'">Data manager (dtm)</xsl:when>
                    <xsl:when test="@role = 'dto'">Dedicator (dto)</xsl:when>
                    <xsl:when test="@role = 'dub'">Dubious author (dub)</xsl:when>
                    <xsl:when test="@role = 'edt'">Editor (edt)</xsl:when>
                    <xsl:when test="@role = 'egr'">Engraver (egr)</xsl:when>
                    <xsl:when test="@role = 'elg'">Electrician (elg)</xsl:when>
                    <xsl:when test="@role = 'elt'">Electrotyper (elt)</xsl:when>
                    <xsl:when test="@role = 'eng'">Engineer (eng)</xsl:when>
                    <xsl:when test="@role = 'etr'">Etcher (etr)</xsl:when>
                    <xsl:when test="@role = 'evp'">Event place (evp)</xsl:when>
                    <xsl:when test="@role = 'exp'">Appraiser (exp)</xsl:when>
                    <xsl:when test="@role = 'fac'">Facsimilist (fac)</xsl:when>
                    <xsl:when test="@role = 'fld'">Field director (fld)</xsl:when>
                    <xsl:when test="@role = 'flm'">Film editor (flm)</xsl:when>
                    <xsl:when test="@role = 'fmo'">Former owner (fmo)</xsl:when>
                    <xsl:when test="@role = 'fnd'">Funder (fnd)</xsl:when>
                    <xsl:when test="@role = 'fpy'">First party (fpy)</xsl:when>
                    <xsl:when test="@role = 'frg'">Forger (frg)</xsl:when>
                    <xsl:when test="@role = 'gis'">Geographic information specialist (gis)</xsl:when>
                    <xsl:when test="@role = 'grt'">Graphic technician (grt)</xsl:when>
                    <xsl:when test="@role = 'hnr'">Honoree (hnr)</xsl:when>
                    <xsl:when test="@role = 'hst'">Host (hst)</xsl:when>
                    <xsl:when test="@role = 'ill'">Illustrator (ill)</xsl:when>
                    <xsl:when test="@role = 'ilu'">Illuminator (ilu)</xsl:when>
                    <xsl:when test="@role = 'ins'">Inscriber (ins)</xsl:when>
                    <xsl:when test="@role = 'inv'">Inventor (inv)</xsl:when>
                    <xsl:when test="@role = 'itr'">Instrumentalist (itr)</xsl:when>
                    <xsl:when test="@role = 'ive'">Interviewee (ive)</xsl:when>
                    <xsl:when test="@role = 'ivr'">Interviewer (ivr)</xsl:when>
                    <xsl:when test="@role = 'lbr'">Laboratory (lbr)</xsl:when>
                    <xsl:when test="@role = 'lbt'">Librettist (lbt)</xsl:when>
                    <xsl:when test="@role = 'ldr'">Laboratory director (ldr)</xsl:when>
                    <xsl:when test="@role = 'led'">Lead (led)</xsl:when>
                    <xsl:when test="@role = 'lee'">Libelee-appellee (lee)</xsl:when>
                    <xsl:when test="@role = 'lel'">Libelee (lel)</xsl:when>
                    <xsl:when test="@role = 'len'">Lender (len)</xsl:when>
                    <xsl:when test="@role = 'let'">Libelee-appellant (let)</xsl:when>
                    <xsl:when test="@role = 'lgd'">Lighting designer (lgd)</xsl:when>
                    <xsl:when test="@role = 'lie'">Libelant-appellee (lie)</xsl:when>
                    <xsl:when test="@role = 'lil'">Libelant (lil)</xsl:when>
                    <xsl:when test="@role = 'lit'">Libelant-appellant (lit)</xsl:when>
                    <xsl:when test="@role = 'lsa'">Landscape architect (lsa)</xsl:when>
                    <xsl:when test="@role = 'lse'">Licensee (lse)</xsl:when>
                    <xsl:when test="@role = 'lso'">Licensor (lso)</xsl:when>
                    <xsl:when test="@role = 'ltg'">Lithographer (ltg)</xsl:when>
                    <xsl:when test="@role = 'lyr'">Lyricist (lyr)</xsl:when>
                    <xsl:when test="@role = 'mcp'">Music copyist (mcp)</xsl:when>
                    <xsl:when test="@role = 'mdc'">Metadata contact (mdc)</xsl:when>
                    <xsl:when test="@role = 'mfp'">Manufacture place (mfp)</xsl:when>
                    <xsl:when test="@role = 'mfr'">Manufacturer (mfr)</xsl:when>
                    <xsl:when test="@role = 'mod'">Moderator (mod)</xsl:when>
                    <xsl:when test="@role = 'mon'">Monitor (mon)</xsl:when>
                    <xsl:when test="@role = 'mrb'">Marbler (mrb)</xsl:when>
                    <xsl:when test="@role = 'mrk'">Markup editor (mrk)</xsl:when>
                    <xsl:when test="@role = 'msd'">Musical director (msd)</xsl:when>
                    <xsl:when test="@role = 'mte'">Metal-engraver (mte)</xsl:when>
                    <xsl:when test="@role = 'mus'">Musician (mus)</xsl:when>
                    <xsl:when test="@role = 'nrt'">Narrator (nrt)</xsl:when>
                    <xsl:when test="@role = 'opn'">Opponent (opn)</xsl:when>
                    <xsl:when test="@role = 'org'">Originator (org)</xsl:when>
                    <xsl:when test="@role = 'orm'">Organizer of meeting (orm)</xsl:when>
                    <xsl:when test="@role = 'oth'">Other (oth)</xsl:when>
                    <xsl:when test="@role = 'own'">Owner (own)</xsl:when>
                    <xsl:when test="@role = 'pat'">Patron (pat)</xsl:when>
                    <xsl:when test="@role = 'pbd'">Publishing director (pbd)</xsl:when>
                    <xsl:when test="@role = 'pbl'">Publisher (pbl)</xsl:when>
                    <xsl:when test="@role = 'pdr'">Project director (pdr)</xsl:when>
                    <xsl:when test="@role = 'pfr'">Proofreader (pfr)</xsl:when>
                    <xsl:when test="@role = 'pht'">Photographer (pht)</xsl:when>
                    <xsl:when test="@role = 'plt'">Platemaker (plt)</xsl:when>
                    <xsl:when test="@role = 'pma'">Permitting agency (pma)</xsl:when>
                    <xsl:when test="@role = 'pmn'">Production manager (pmn)</xsl:when>
                    <xsl:when test="@role = 'pop'">Printer of plates (pop)</xsl:when>
                    <xsl:when test="@role = 'ppm'">Papermaker (ppm)</xsl:when>
                    <xsl:when test="@role = 'ppt'">Puppeteer (ppt)</xsl:when>
                    <xsl:when test="@role = 'prc'">Process contact (prc)</xsl:when>
                    <xsl:when test="@role = 'prd'">Production personnel (prd)</xsl:when>
                    <xsl:when test="@role = 'prf'">Performer (prf)</xsl:when>
                    <xsl:when test="@role = 'prg'">Programmer (prg)</xsl:when>
                    <xsl:when test="@role = 'prm'">Printmaker (prm)</xsl:when>
                    <xsl:when test="@role = 'pro'">Producer (pro)</xsl:when>
                    <xsl:when test="@role = 'prp'">Production place (prp)</xsl:when>
                    <xsl:when test="@role = 'prt'">Printer (prt)</xsl:when>
                    <xsl:when test="@role = 'prv'">Provider (prv)</xsl:when>
                    <xsl:when test="@role = 'pta'">Patent applicant (pta)</xsl:when>
                    <xsl:when test="@role = 'pte'">Plaintiff-appellee (pte)</xsl:when>
                    <xsl:when test="@role = 'ptf'">Plaintiff (ptf)</xsl:when>
                    <xsl:when test="@role = 'pth'">Patentee (pth)</xsl:when>
                    <xsl:when test="@role = 'ptt'">Plaintiff-appellant (ptt)</xsl:when>
                    <xsl:when test="@role = 'pup'">Publication place (pup)</xsl:when>
                    <xsl:when test="@role = 'rbr'">Rubricator (rbr)</xsl:when>
                    <xsl:when test="@role = 'rcd'">Recordist (rcd)</xsl:when>
                    <xsl:when test="@role = 'rce'">Recording engineer (rce)</xsl:when>
                    <xsl:when test="@role = 'rcp'">Recipient (rcp)</xsl:when>
                    <xsl:when test="@role = 'red'">Redaktor (red)</xsl:when>
                    <xsl:when test="@role = 'ren'">Renderer (ren)</xsl:when>
                    <xsl:when test="@role = 'res'">Researcher (res)</xsl:when>
                    <xsl:when test="@role = 'rev'">Reviewer (rev)</xsl:when>
                    <xsl:when test="@role = 'rps'">Repository (rps)</xsl:when>
                    <xsl:when test="@role = 'rpt'">Reporter (rpt)</xsl:when>
                    <xsl:when test="@role = 'rpy'">Responsible party (rpy)</xsl:when>
                    <xsl:when test="@role = 'rse'">Respondent-appellee (rse)</xsl:when>
                    <xsl:when test="@role = 'rsg'">Restager (rsg)</xsl:when>
                    <xsl:when test="@role = 'rsp'">Respondent (rsp)</xsl:when>
                    <xsl:when test="@role = 'rst'">Respondent-appellant (rst)</xsl:when>
                    <xsl:when test="@role = 'rth'">Research team head (rth)</xsl:when>
                    <xsl:when test="@role = 'rtm'">Research team member (rtm)</xsl:when>
                    <xsl:when test="@role = 'sad'">Scientific advisor (sad)</xsl:when>
                    <xsl:when test="@role = 'sce'">Scenarist (sce)</xsl:when>
                    <xsl:when test="@role = 'scl'">Sculptor (scl)</xsl:when>
                    <xsl:when test="@role = 'scr'">Scribe (scr)</xsl:when>
                    <xsl:when test="@role = 'sds'">Sound designer (sds)</xsl:when>
                    <xsl:when test="@role = 'sec'">Secretary (sec)</xsl:when>
                    <xsl:when test="@role = 'sgn'">Signer (sgn)</xsl:when>
                    <xsl:when test="@role = 'sht'">Supporting host (sht)</xsl:when>
                    <xsl:when test="@role = 'sng'">Singer (sng)</xsl:when>
                    <xsl:when test="@role = 'spk'">Speaker (spk)</xsl:when>
                    <xsl:when test="@role = 'spn'">Sponsor (spn)</xsl:when>
                    <xsl:when test="@role = 'spy'">Second party (spy)</xsl:when>
                    <xsl:when test="@role = 'srv'">Surveyor (srv)</xsl:when>
                    <xsl:when test="@role = 'std'">Set designer (std)</xsl:when>
                    <xsl:when test="@role = 'stg'">Setting (stg)</xsl:when>
                    <xsl:when test="@role = 'stl'">Storyteller (stl)</xsl:when>
                    <xsl:when test="@role = 'stm'">Stage manager (stm)</xsl:when>
                    <xsl:when test="@role = 'stn'">Standards body (stn)</xsl:when>
                    <xsl:when test="@role = 'str'">Stereotyper (str)</xsl:when>
                    <xsl:when test="@role = 'tcd'">Technical director (tcd)</xsl:when>
                    <xsl:when test="@role = 'tch'">Teacher (tch)</xsl:when>
                    <xsl:when test="@role = 'ths'">Thesis advisor (ths)</xsl:when>
                    <xsl:when test="@role = 'trc'">Transcriber (trc)</xsl:when>
                    <xsl:when test="@role = 'trl'">Translator (trl)</xsl:when>
                    <xsl:when test="@role = 'tyd'">Type designer (tyd)</xsl:when>
                    <xsl:when test="@role = 'tyg'">Typographer (tyg)</xsl:when>
                    <xsl:when test="@role = 'uvp'">University place (uvp)</xsl:when>
                    <xsl:when test="@role = 'vdg'">Videographer (vdg)</xsl:when>
                    <xsl:when test="@role = 'voc'">Vocalist (voc)</xsl:when>
                    <xsl:when test="@role = 'wam'">Writer of accompanying material (wam)</xsl:when>
                    <xsl:when test="@role = 'wdc'">Woodcutter (wdc)</xsl:when>
                    <xsl:when test="@role = 'wde'">Wood engraver (wde)</xsl:when>
                    <xsl:when test="@role = 'wit'">Witness (wit)</xsl:when>
                    <xsl:when test="@role = 'abr'">Abridger (abr)</xsl:when>
                    <xsl:when test="@role = 'adi'">Art director (adi)</xsl:when>
                    <xsl:when test="@role = 'ape'">Appellee (ape)</xsl:when>
                    <xsl:when test="@role = 'apl'">Appellant (apl)</xsl:when>
                    <xsl:when test="@role = 'ato'">Autographer (ato)</xsl:when>
                    <xsl:when test="@role = 'brd'">Broadcaster (brd)</xsl:when>
                    <xsl:when test="@role = 'brl'">Braille embosser (brl)</xsl:when>
                    <xsl:when test="@role = 'cas'">Caster (cas)</xsl:when>
                    <xsl:when test="@role = 'cor'">Collection registrar (cor)</xsl:when>
                    <xsl:when test="@role = 'cou'">Court governed (cou)</xsl:when>
                    <xsl:when test="@role = 'crt'">Court reporter (crt)</xsl:when>
                    <xsl:when test="@role = 'dgs'">Degree supervisor (dgs)</xsl:when>
                    <xsl:when test="@role = 'edc'">Editor of compilation (edc)</xsl:when>
                    <xsl:when test="@role = 'edm'">Editor of moving image work (edm)</xsl:when>
                    <xsl:when test="@role = 'enj'">Enacting jurisdiction (enj)</xsl:when>
                    <xsl:when test="@role = 'fds'">Film distributor (fds)</xsl:when>
                    <xsl:when test="@role = 'fmd'">Film director (fmd)</xsl:when>
                    <xsl:when test="@role = 'fmk'">Filmmaker (fmk)</xsl:when>
                    <xsl:when test="@role = 'fmp'">Film producer (fmp)</xsl:when>
                    <xsl:when test="@role = 'his'">Host institution (his)</xsl:when>
                    <xsl:when test="@role = 'isb'">Issuing body (isb)</xsl:when>
                    <xsl:when test="@role = 'jud'">Judge (jud)</xsl:when>
                    <xsl:when test="@role = 'jug'">Jurisdiction governed (jug)</xsl:when>
                    <xsl:when test="@role = 'med'">Medium (med)</xsl:when>
                    <xsl:when test="@role = 'mtk'">Minute taker (mtk)</xsl:when>
                    <xsl:when test="@role = 'osp'">Onscreen presenter (osp)</xsl:when>
                    <xsl:when test="@role = 'pan'">Panelist (pan)</xsl:when>
                    <xsl:when test="@role = 'pra'">Praeses (pra)</xsl:when>
                    <xsl:when test="@role = 'pre'">Presenter (pre)</xsl:when>
                    <xsl:when test="@role = 'prn'">Production company (prn)</xsl:when>
                    <xsl:when test="@role = 'prs'">Production designer (prs)</xsl:when>
                    <xsl:when test="@role = 'rdd'">Radio director (rdd)</xsl:when>
                    <xsl:when test="@role = 'rpc'">Radio producer (rpc)</xsl:when>
                    <xsl:when test="@role = 'rsr'">Restorationist (rsr)</xsl:when>
                    <xsl:when test="@role = 'sgd'">Stage director (sgd)</xsl:when>
                    <xsl:when test="@role = 'sll'">Seller (sll)</xsl:when>
                    <xsl:when test="@role = 'tld'">Television director (tld)</xsl:when>
                    <xsl:when test="@role = 'tlp'">Television producer (tlp)</xsl:when>
                    <xsl:when test="@role = 'vac'">Voice actor (vac)</xsl:when>
                    <xsl:when test="@role = 'wac'">Writer of added commentary (wac)</xsl:when>
                    <xsl:when test="@role = 'wal'">Writer of added lyrics (wal)</xsl:when>
                    <xsl:when test="@role = 'wat'">Writer of added text (wat)</xsl:when>
                    <xsl:when test="@role = 'win'">Writer of introduction (win)</xsl:when>
                    <xsl:when test="@role = 'wpr'">Writer of preface (wpr)</xsl:when>
                    <xsl:when test="@role = 'wst'">Writer of supplementary textual content (wst)</xsl:when>
                    
                    <xsl:otherwise>
                        <xsl:value-of select="local:uppercase-first-word(replace(@role,'_',' '))"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:for-each select="@*[not(local-name() = 'role')]">
                <xsl:attribute name="{local-name()}" 
                    select="."/>
            </xsl:for-each>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    
<!-- STEP 3:  These are EAD fixes for INVALID ArchivesSpace EAD exports -->
    <!-- ref, extref, extptr attributes were fixed (ANW-669) -->
    <!-- dao audience attributes were fixed (ANW-805)-->
      
    
<!-- STEP 4: Fix data entry and workarounds. Buy us time for cleanup or for ongoing goofups-->
    
    <!-- work around for missing extent statements 
        (don't display type undetermined in edan applications;
        and omit physdesc that only contains an undetermined type)-->
    <xsl:template match="ead:physdesc/ead:extent[lower-case(@type) ='undetermined']"/>
    <xsl:template match="ead:physdesc[count(child::*) = 1][ead:extent[lower-case(@type) ='undetermined']]"/>
       
    
    <!-- add render for title or emph, assuming italic if unstated-->
    <xsl:template match="ead:title[not(@render)][not(parent::ead:title)] | ead:emph[not(@render)]">
        <xsl:copy>
            <xsl:attribute name="render" select="'italic'"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    
    <!-- add untitled if blank (so there's something to click on..) -->
    <xsl:template match="ead:unittitle[not(normalize-space())]">
        <unittitle>
            <xsl:text>Untitled</xsl:text>
        </unittitle>
    </xsl:template>
    
    <!-- add ead url if blank/ omitted -->
    <xsl:template match="ead:ead/ead:eadheader/ead:eadid[not(@url)]">
        <xsl:choose>
            <xsl:when test="@mainagencycode ='DSI-AI'">               
                <xsl:copy>
                    <xsl:apply-templates select="@*"/>
                    <xsl:attribute name="url" select="concat('https://sova.si.edu/record/','SIA.',replace($filename,'-ead.xml',''))"/>
                    <xsl:apply-templates select="node()"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy>
                     <xsl:apply-templates select="@*"/>
                     <xsl:attribute name="url" select="concat('https://sova.si.edu/record/',normalize-space(.))"/>
                     <xsl:apply-templates select="node()"/>
                 </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>       
    </xsl:template>
    
    <!--maybe do something about auto note headers ? -->
    
    <!-- display fix: inserts 'bulk ' text in expression 
        (this is to retro-fit/match AT style. could change, 
        but requires data coordination)-->
    <xsl:template match="ead:unitdate[@type='bulk'][not(matches(.,'^bulk'))]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:value-of select="concat('bulk ',.)"/>
        </xsl:copy>
    </xsl:template>
             
       
    <xsl:function name="local:uppercase-first-word" as="xs:string?">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:sequence
            select="concat(upper-case(substring($arg,1,1)),
            substring($arg,2))"/>       
    </xsl:function>
    
    <!-- new, to address Issue 18: https://github.com/Smithsonian/lassb-transformations/issues/18 -->
    <xsl:template match="ead:dao/@xlink:role[matches(., 'pdf', 'i')]">
        <xsl:attribute name="role" namespace="http://www.w3.org/1999/xlink">
            <xsl:value-of select="'application-pdf'"/>
        </xsl:attribute>
    </xsl:template>
    
</xsl:stylesheet>