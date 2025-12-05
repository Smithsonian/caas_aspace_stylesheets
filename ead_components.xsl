<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:sova="http://www.myNameSpace.com/myfunctions" exclude-result-prefixes="#all" version="3.0">

    <xsl:strip-space elements="*"/>
    <xsl:output indent="yes" encoding="UTF-8"/>
    
    <xsl:variable name="countComponents">
        <xsl:value-of select="count(//ead:c)"/>
    </xsl:variable>
    
    <xsl:variable name="eadid">
        <xsl:choose>
            <xsl:when test="/ead:ead/ead:eadheader/ead:eadid/@mainagencycode = 'DSI-AI'">                   
                <xsl:variable name="filename" select="(tokenize(base-uri(.),'/'))[last()]"/>
                <xsl:value-of select="replace($filename,'-ead.xml','')"/>                    
            </xsl:when>
            <xsl:otherwise>
                <!-- older files may need a fallback to unitid-->
                <xsl:value-of select="/ead:ead/ead:archdesc/ead:did/ead:unitid[not(@audience = 'internal')][not(starts-with(@*:type,'ark'))][1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable> 
    
    <!-- Transforms EAD 2002 xml to ead_collection and ead_component documents.
         Version 3.2, created 1 May 2017; last updated 9 May 2022.
            * Created on: May 1, 2017
            * Updated on: Sept 20, 2017, to limit inherited representative images to top level records only
            * Updated on: Sept 18, 2018, to add usage flag for large EAD
            * Updated on: Nov 2, 2018, to include date, object type facets 
            * Updated on: Dec 6, 2018, to add default sort name (SI) and group object terms (avoid duplicate)
            * Updated on: April 12, 2019, to query lassb-service03 for thumbnails (solr6)
            * Updated on: Sept. 11, 2019, to add set names (resource, breadcrumbs)
            * Updated on: Oct. 15, 2019, to add MADS thumbnails in online_media.media
            * Updated on: Aug. 4, 2020, to add metadata_usage CC0
            * Updated on: Feb. 2021, to add sort position
            * Updated on: Nov. 2021, to add ARK
            * Updated on: May 9, 2022, allow all dao (not just first 8)
            * Updated on: 2023-03-13, allow nested controlaccess headings that group names, just like the process already permitted for subjects, etc.
            * Updated on: 2023-07-12, patch for MADS thumbnails. Once we fully switch to GitHub, let's stop adding these update comments.
            * Updated on: 2024-05-31, to match new URL structure in SOVA (lower-cased EADID values, plus shift from #-based references to path-based URLs)
            * See Git Commits for further updates (plus, we'll eventually switch to an EAD to EDAN JSON transformation approach) *
    -->
    
    <xsl:template match="/">          
        <xml>
            <xsl:for-each select="/ead:ead/ead:archdesc | /ead:ead/ead:archdesc/ead:dsc//ead:c">
                <!-- unitid can also hold ARKs, so figure out the user-friendly component ID here-->
                <xsl:variable name="unitid_component_id" 
                    select="ead:did/ead:unitid[not(@audience='internal')][not(starts-with(@*:type,'ark'))][normalize-space()][1]"/>
                
                <doc>
                    <xsl:attribute name="boost">
                        <xsl:call-template name="boostval"/>
                    </xsl:attribute>
                    <xsl:call-template name="component_data">
                        <xsl:with-param name="unitid_component_id" select="$unitid_component_id"/>
                    </xsl:call-template>
                    <xsl:call-template name="freetext">
                        <xsl:with-param name="unitid_component_id" select="$unitid_component_id"/>
                    </xsl:call-template>
                    <xsl:call-template name="usage_flag"/>
                    <xsl:call-template name="sort"/>
                </doc>
            </xsl:for-each>
        </xml>
    </xsl:template>

    
    <xsl:template name="component_data">  
        <xsl:param name="unitid_component_id"/>
        
        <!-- or, start prepending the unitid via ead cleanup xsl.  
            temporarily, replace here, so don't get it twice. -->
        <xsl:variable name="ead_ref_id">
            <xsl:choose>
                <xsl:when test="self::ead:archdesc">
                    <xsl:value-of select="$eadid"/>
                </xsl:when>
                <xsl:otherwise>
                    <!-- MDC:  this seems fragile to me.  
                        Why would we ever need to strip the EADID value from the ID here if the EADID is never going to be supplied by ASpace, nor SIA's process?
                        Further, if it were there (e.g. EADID_refID), couldn't that result in something like "eadid__refID" rather than "eadid_refID"?
                        Keeping as is for now, as nothing should ever be replaced anyway, but this seems like an area that we can re-write at this point 
                        That is: 
                            $eadid || '_' || $id
                        should suffice
                    -->
                    <xsl:value-of select="concat($eadid,'_',replace(@id,$eadid,''))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="guid_ark" 
            select="ead:did/ead:unitid[@*:type='ark'][1]/ead:extref/@*:href"/>
        
        <xsl:variable name="eadid_normalized" select="lower-case(normalize-space($eadid))" as="xs:string"/>
                
        <xsl:variable name="record_link_url">
            <xsl:choose>
                <!-- collection level-->
                <xsl:when test="self::ead:archdesc">
                    <xsl:choose>
                        <!-- when there is a specific url (like AAA) -->
                        <xsl:when test="/ead:ead/ead:eadheader/ead:eadid/@url">
                            <xsl:value-of select="/ead:ead/ead:eadheader/ead:eadid/@url"/>
                        </xsl:when>
                        <!-- if no specific url, use SOVA with EADID-->
                        <xsl:otherwise>
                            <xsl:value-of select="concat('https://sova.si.edu/record/',$eadid_normalized)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <!-- non-collection level: always sova/record + EADID + / + @id-->
                <xsl:otherwise>
                    <xsl:choose>
                        <!-- when there is an ARK -->
                        <xsl:when test="$guid_ark">
                            <xsl:value-of select="$guid_ark"/>
                        </xsl:when>
                        <!-- if no specific url, use SOVA with EADID-->
                        <xsl:otherwise>
                            <xsl:value-of select="concat('https://sova.si.edu/record/',$eadid_normalized,'/',@id)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <type>
            <xsl:choose>
                <xsl:when test="self::ead:archdesc">
                    <xsl:text>ead_collection</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>ead_component</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </type>

        <!-- Identifiers:
            * UNITID vs EADID: Note that unitid and eadid can be different - see SIA. Do not assume they are the same.  
        -->
        <id>
            <!-- this is a normalized id -->
            <xsl:value-of select="concat('sova.', lower-case(normalize-space($ead_ref_id)))"/>
        </id>

        <record_id>
            <!-- this is "EAD Ref ID" -->
            <xsl:value-of select="$ead_ref_id"/>
        </record_id>

        <collection_id>
            <!-- this is the top-level id, shared by all parts of the collection -->
            <!-- based on the top level UNITID and is the human readable, 
                display version (for SIA, this is the spelled-out 'Record Unit' etc) -->
            <xsl:value-of select="/ead:ead/ead:archdesc/ead:did/ead:unitid[not(@audience='internal')][not(starts-with(@*:type,'ark'))][1]"/>
        </collection_id>

        <!-- aka the edan unit_code for CSC. cannot use simple substring because NMAH is not same-as ACAH -->
        <!-- MDC:  this deserves more discussion. we should not conflate units with departments in EDAN -->
        <archival_repository>  
            <xsl:choose>
                <xsl:when test="/ead:ead/ead:archdesc[1]/ead:did[1]/ead:unitid[@repositorycode = 'DSI-AI']">
                    <xsl:text>SIA</xsl:text>
                </xsl:when>
                <xsl:when test="/ead:ead/ead:eadheader/ead:eadid/starts-with(.,'NMAH.AC.')">
                    <xsl:text>ACAH</xsl:text>
                </xsl:when>
                <xsl:when test="$eadid/starts-with(.,'NASM')">
                    <xsl:text>NASMAC</xsl:text>
                </xsl:when>
                <xsl:when test="$eadid/starts-with(.,'NMAI')">
                    <xsl:text>NMAIA</xsl:text>
                </xsl:when>
                <xsl:when test="$eadid/starts-with(.,'SAAM.NJP')">
                    <xsl:text>SAAMPAIK</xsl:text>
                </xsl:when>
                <xsl:when test="$eadid/starts-with(.,'SAAM')">
                    <xsl:text>SAAM</xsl:text>
                </xsl:when>
                
                <!-- 2018-03-13: Change code from FLP to CFCHFOLKLIFE -->
                <!-- note LIFE vs WAYS: there will be different set of records going to CSC as CFCHFOLKWAYS -->
                <xsl:when test="$eadid/starts-with(.,'CFCH')">
                    <xsl:text>CFCHFOLKLIFE</xsl:text>
                </xsl:when>
                
                <xsl:otherwise>
                    <!-- AAA.blue = AAA, SIL-CH.example = SIL -->
                    <xsl:analyze-string 
                        select="$eadid" 
                        regex="(.*?)[\-\.](.*)">
                        <xsl:matching-substring>
                            <xsl:value-of select="regex-group(1)"/>
                        </xsl:matching-substring>
                       <xsl:non-matching-substring>SI</xsl:non-matching-substring>
                    </xsl:analyze-string>
                    
                </xsl:otherwise>
            </xsl:choose>
        </archival_repository>

        <record_link>
            <xsl:value-of select="$record_link_url"/>
        </record_link>

        <filelocation>
            <xsl:variable name="filename" select="(tokenize(base-uri(.),'/'))[last()]"/>
            <xsl:value-of select="concat('https://sirismm.si.edu/EADs/', $filename)"/>
        </filelocation>

        <level>
            <xsl:value-of select="@level"/>
        </level>

        <xsl:for-each select="ancestor-or-self::ead:archdesc | ancestor-or-self::ead:c">
            <xsl:call-template name="containedIn">
                <xsl:with-param name="unitid_component_id" select="$unitid_component_id"/>
            </xsl:call-template>
        </xsl:for-each>

        <title>
            <xsl:choose>
                <xsl:when test="ead:did/ead:unittitle[normalize-space()]">
                    <xsl:apply-templates select="ead:did/ead:unittitle"/>
                </xsl:when>
                <xsl:otherwise>Untitled</xsl:otherwise>
            </xsl:choose>
        </title>

        <!-- use the langmaterial with langcode -->
        <xsl:for-each select="ead:did/ead:langmaterial/ead:language[@langcode]">
            <language>
                <xsl:value-of select="@langcode"/>
            </language>
        </xsl:for-each>

        <!-- begin digital objects -->
        <xsl:call-template name="digitalDetails">
            <xsl:with-param name="record_link_url" select="$record_link_url"/>
        </xsl:call-template>

        <!-- include related bib that are listed at this level, not descendent ead:c bibs (size issue when AAG.GCA, e.g.)-->
        <xsl:choose>
            <xsl:when test="self::ead:archdesc">
                <xsl:for-each select="/ead:ead/ead:eadheader/ead:filedesc/ead:notestmt/ead:note/ead:p/ead:num[contains(@type,'siris')]"> 
                    <related_bib_record>
                        <xsl:value-of select="concat(@type,'_',.)"/>
                    </related_bib_record>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="ead:otherfindaid//ead:num[contains(@type,'siris')]"> 
                    <related_bib_record>
                        <xsl:value-of select="concat(@type,'_',.)"/>
                    </related_bib_record>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- 2020-08-04 NCK: All EADs will be processed as metadata_usage CC0 -->
        <metadata_usage>
            <access>CC0</access>
        </metadata_usage>
        
        <!-- 2020-09-30 NCK: ASpace will provide ARKs in unitid/extref -->
        <xsl:if test="$guid_ark">
            <guid>
                <xsl:value-of select="$guid_ark"/>
            </guid>
        </xsl:if>     

    </xsl:template>

    <!--Breadcrumb list for series/subseries/file structures-->
    <xsl:template name="containedIn">
        <xsl:param name="unitid_component_id"/>
        <containedIn>
            <type>
                <xsl:value-of select="sova:capitalize-first(@level)"/>
            </type>
            
            <xsl:if test="$unitid_component_id">
                <!-- only need this for as long as we are handling both AT and aspace versions -->
                <xsl:variable name="clean_unitid" select="replace($unitid_component_id,'Series ','')"/>
                <unitid>
                    <xsl:value-of select="concat(sova:capitalize-first(@level),' ',$clean_unitid)"/>
                </unitid>
            </xsl:if>
            
            <unittitle>
                <xsl:choose>
                    <xsl:when test="ead:did/ead:unittitle[normalize-space()]">
                        <xsl:value-of select="ead:did/ead:unittitle"/>
                    </xsl:when>
                    <xsl:otherwise>Untitled</xsl:otherwise>
                </xsl:choose>
            </unittitle>
            
            <url>
                <!-- with the next iteration, we need to paramertize this URL so that we can switch between environments.
                    but, we can keep this as a PROD-only value for now, since that all it's been (mdc) -->
                <xsl:text>https://sova.si.edu/</xsl:text>
                <xsl:choose>
                    <xsl:when test="self::ead:archdesc">
                        <xsl:value-of select="concat('record/',$eadid)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of
                            select="concat('record/',$eadid,'/',replace(@id,$eadid,''))"/>
                        
                    </xsl:otherwise>
                </xsl:choose>
            </url>
        </containedIn>
    </xsl:template>
    
    <!--Set details for digital object facets and online_media. Digital assets available includes:
        * any descendent digital objects, 
        * excluding representative-images-->
    <xsl:template name="digitalDetails">
        <xsl:param name="record_link_url"/>
        <digital_assets_available>
            <xsl:choose>
                <xsl:when test=".//ead:dao[not(lower-case(@*:role) = 'representative-image')]">true</xsl:when>
                <xsl:when test=".//ead:daogrp/ead:daoloc[@xlink:role = 'web-resource-link']">true</xsl:when>
                <xsl:otherwise>false</xsl:otherwise>
            </xsl:choose>
        </digital_assets_available>
        
        <!-- at this point, should we just re-write this?  anyhow, for ASpace, at least, the dao and daogrp will always be within the did -->
        <xsl:if test="self::ead:archdesc or ead:dao or ead:did/ead:dao or ead:did/ead:daogrp">

            <online_media>
                <!-- not sure what the media count is used for, but keeping these as-is, for now
                    * Media count includes number of dao at current level 
                    * +1 for the FA record link, when at top level only
                    * +1 for representative-image, when inherited from other level -->
                <mediaCount>
                    <xsl:value-of select="count(ead:dao) + count(ead:did/ead:dao)  + count(ead:did/ead:daogrp)
                        + count(self::ead:archdesc) 
                        + count(self::ead:archdesc[not(ead:dao)]/descendant::ead:dao[contains(lower-case(@*:role),'image')][1])"/>
                </mediaCount>

                <!-- build rep image: only for collection level ; prev: did this for all current level -->
                <!-- will continue to NOT create a representative image for a daogrp. we will udpate this process once we switch to EAD4 or RiC, right? -->
                <xsl:if test="self::ead:archdesc[not(ead:dao)][not(ead:did/ead:dao)]/descendant::ead:dao[contains(lower-case(@*:role),'image')][1]">
                    <xsl:for-each select="descendant::ead:dao[contains(lower-case(@*:role),'image')][1]">
                        <xsl:call-template name="media">
                            <xsl:with-param name="flag" select="'inherited'"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:if>

                <!-- prior to 9 May 2022, we used to limit to first 8 -->
                <!-- <xsl:for-each select="ead:dao[position() &lt;= 8] | ead:did/ead:dao[position() &lt;= 8]">-->
                <xsl:for-each select="ead:dao | ead:did/ead:dao">
                    <xsl:call-template name="media"/>
                </xsl:for-each>
                
                <xsl:for-each select="ead:did/ead:daogrp">
                    <xsl:call-template name="daogrp-media"/>
                </xsl:for-each>
                
                

                <!-- prior to 9 May 2022, we used to limit to first 8, and if more than 8, link to SOVA -->
                <!--<xsl:if test="ead:dao[position() &gt; 8]">
                    <media>
                        <type>Electronic resource</type>
                        <indexedType>Electronic resource</indexedType> 
                        <thumbnail>https://sirismm.si.edu/siris/SeeMoreInSOVA.gif</thumbnail>
                        <caption>See more Digital Content</caption>
                        <content>
                            <xsl:value-of select="$record_link_url"/>
                        </content>
                    </media>
                </xsl:if>-->

                <!-- this carries forward a 'finding aid' media, for *all* EAD. Unclear usage, so continuing to include, but could be reviewed-->
                <!-- Last: finding aid url (aka same as record link. is this needed? provides specific thumbnail) -->
                <xsl:for-each select="self::ead:archdesc">
                    <media>
                        <type>Finding aids</type>
                        <indexedType>Finding aids</indexedType>
                        <thumbnail>https://sirismm.si.edu/siris/findingaid.gif</thumbnail>
                        <caption>Finding aid</caption>
                        <content>
                            <xsl:value-of select="$record_link_url"/>
                        </content>
                    </media>
                </xsl:for-each>
            </online_media>


        </xsl:if>
    </xsl:template>

    <!-- Media details (types, caption, thumbnail, content -->
    <xsl:template name="media">
        <xsl:param name="flag"/>
        <media>
            <xsl:variable name="mime-types">
                <mime type="application/epub+zip" ext="epub"/>
                <mime type="application/javascript" ext="js"/>
                <mime type="application/json" ext="json"/>
                <mime type="application/msword" ext="doc"/>
                <mime type="application/oebps-package+xml" ext="opf"/>
                <mime type="application/pdf" ext="pdf"/>
                <mime type="application/pls+xml" ext="pls"/>
                <mime type="application/smil+xml" ext="smil"/>
                <mime type="application/vnd.adobe-page-template+xml" ext="xpgt"/>
                <mime type="application/vnd.cinderella" ext="cdy"/>
                <mime type="application/vnd.ms-fontobject" ext="eot"/>
                <mime type="application/vnd.ms-opentype" ext="otf"/>
                <mime type="application/vnd.openxmlformats-officedocument.wordprocessingml.document" ext="docx"/>
                <mime type="application/vnd.openxmlformats-officedocument.wordprocessingml.template" ext="dotx"/>
                <mime type="application/vnd.ms-word.document.macroEnabled.12" ext="docm"/>
                <mime type="application/vnd.ms-word.template.macroEnabled.12" ext="dotm"/>
                <mime type="application/vnd.ms-excel" ext="xls"/>
                <mime type="application/vnd.ms-excel" ext="xlt"/>
                <mime type="application/vnd.ms-excel" ext="xla"/>
                <mime type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" ext="xlsx"/>
                <mime type="application/vnd.openxmlformats-officedocument.spreadsheetml.template" ext="xltx"/>
                <mime type="application/vnd.ms-excel.sheet.macroEnabled.12" ext="xlsm"/>
                <mime type="application/vnd.ms-excel.template.macroEnabled.12" ext="xltm"/>
                <mime type="application/vnd.ms-excel.addin.macroEnabled.12" ext="xlam"/>
                <mime type="application/vnd.ms-excel.sheet.binary.macroEnabled.12" ext="xlsb"/>
                <mime type="application/vnd.ms-powerpoint" ext="ppt"/>
                <mime type="application/vnd.ms-powerpoint" ext="pot"/>
                <mime type="application/vnd.ms-powerpoint" ext="pps"/>
                <mime type="application/vnd.ms-powerpoint" ext="ppa"/>
                <mime type="application/vnd.openxmlformats-officedocument.presentationml.presentation" ext="pptx"/>
                <mime type="application/vnd.openxmlformats-officedocument.presentationml.template" ext="potx"/>
                <mime type="application/vnd.openxmlformats-officedocument.presentationml.slideshow" ext="ppsx"/>
                <mime type="application/vnd.ms-powerpoint.addin.macroEnabled.12" ext="ppam"/>
                <mime type="application/vnd.ms-powerpoint.presentation.macroEnabled.12" ext="pptm"/>
                <mime type="application/vnd.ms-powerpoint.template.macroEnabled.12" ext="potm"/>
                <mime type="application/vnd.ms-powerpoint.slideshow.macroEnabled.12" ext="ppsm"/>
                <mime type="application/vnd.ms-access" ext="mdb"/>
                <mime type="application/x-dtbncx+xml" ext="ncx"/>
                <mime type="application/xml" ext="xsl"/> 
                <mime type="application/xhtml+xml" ext="html xhtml"/>
                <mime type="application/rtf" ext="rtf"/>
                <mime type="application/zip" ext="zip"/>
                <mime type="audio/aac" ext="aac"/>
                <mime type="audio/mp4" ext="m4a"/>
                <mime type="audio/mpeg" ext="mp3"/>
                <mime type="audio/webm" ext="weba"/>
                <mime type="audio/x-ms-wma" ext="wma"/>
                <mime type="audio/wav" ext="wav"/>
                <mime type="font/ttf" ext="ttf"/>
                <mime type="font/woff" ext="woff"/>
                <mime type="font/woff" ext="woff2"/>
                <mime type="image/bmp" ext="bmp"/>
                <mime type="image/gif" ext="gif"/>
                <mime type="image/jpeg" ext="jpg jpeg"/>
                <mime type="image/png" ext="png"/>
                <mime type="image/svg+xml" ext="svg"/>
                <mime type="image/tiff" ext="tif tiff"/>
                <mime type="image/vnd.adobe.photoshop" ext="psd"/>
                <mime type="image/x-eps" ext="eps"/>
                <mime type="image/x-emf" ext="emf"/>
                <mime type="text/css" ext="css"/>
                <mime type="text/csv" ext="csv"/>
                <mime type="text/xml" ext="xml"/>
                <mime type="text/plain" ext="txt"/>
                <mime type="video/mp4" ext="mp4 mpg"/>
                <mime type="video/mpeg" ext="mpeg"/>
                <mime type="video/quicktime" ext="mov"/>
                <mime type="video/x-m4v" ext="m4v"/>
                <mime type="video/x-ms-wmv" ext="wmv"/>
                <mime type="video/x-msvideo" ext="avi"/>
                <mime type="video/webm" ext="webm"/>
            </xsl:variable>
            
            <xsl:variable name="fn">
                <xsl:value-of select="tokenize(@*:href, '/')[last()]"/>
            </xsl:variable>
            <xsl:variable name="ext">
                <xsl:choose>
                    <xsl:when test="contains($fn,'.')">
                    <xsl:value-of select="tokenize($fn, '\.')[last()]"/>
                    </xsl:when>
                    <xsl:otherwise/>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="ext_type">
                <xsl:value-of select="$mime-types/mime[tokenize(@ext, '\s') = lower-case($ext)]/@type"/>
            </xsl:variable>
            
            <type>
                <xsl:choose>
                    <xsl:when test="matches(lower-case(@*:href), 'slideshow' ) and 
                        (matches(lower-case(@*:href), 'edan.si.edu') or 
                        matches(lower-case(@*:href),'collections.si.edu/search/slideshow_embedded'))">slideshowHTML</xsl:when>
                    
                    <!-- limit this to IDS , sirismm images because the CSC viewer -->
                    <xsl:when test="matches(lower-case(@*:href),'ids.si.edu')">Images</xsl:when>
                    <xsl:when test="matches(lower-case(@*:role),'image') 
                        and  matches(lower-case(@*:href),'sirismm.si.edu')">Images</xsl:when>
                    
                    <xsl:when test="matches(lower-case(@*:role),'audio')">Sound recordings</xsl:when>
                    <xsl:when test="matches(lower-case(@*:role),'video')">Video recordings</xsl:when>
                    <xsl:when test="matches(lower-case(@*:role),'pdf')">PDF</xsl:when>
                    
                    <!-- if all else fails, try by ext. type-->
                    <xsl:when test="matches($ext_type,'image')">Images</xsl:when>
                    <xsl:when test="matches($ext_type,'audio')">Sound recordings</xsl:when>
                    <xsl:when test="matches($ext_type,'video')">Video recordings</xsl:when>
                    
                    <xsl:otherwise>Electronic resource</xsl:otherwise>
                </xsl:choose>
            </type>
            <indexedType>
                <xsl:choose>
                    <!-- is this the only difference from "type"?  If so, why?  Also, what are the definitions of type and indexedType? -->
                    <xsl:when test="matches(lower-case(@*:href),'slideshow')">Images</xsl:when>
                    <!-- limit this to IDS , sirismm images -->
                    <xsl:when test="matches(lower-case(@*:href),'ids.si.edu')">Images</xsl:when>
                    <xsl:when test="matches(lower-case(@*:role),'image') and  matches(lower-case(@*:href),'sirismm.si.edu')">Images</xsl:when>
                    <xsl:when test="matches(lower-case(@*:role),'image') and  matches(lower-case(@*:href),'.jpg')">Images</xsl:when>
                    
                    <xsl:when test="matches(lower-case(@*:role),'audio')">Sound recordings</xsl:when>
                    <xsl:when test="matches(lower-case(@*:role),'video')">Video recordings</xsl:when>
                    <xsl:when test="matches(lower-case(@*:role),'pdf')">PDF</xsl:when>
                    
                    <!-- if all else fails, try by ext. type-->
                    <xsl:when test="matches($ext_type,'image')">Images</xsl:when>
                    <xsl:when test="matches($ext_type,'audio')">Sound recordings</xsl:when>
                    <xsl:when test="matches($ext_type,'video')">Video recordings</xsl:when>
                    
                    <xsl:otherwise>Electronic resource</xsl:otherwise>
                </xsl:choose>
            </indexedType>
            
            <!-- 2022-05-10: Thumbnails:
                * EDAN loader will attempt update thumbnail for edan slideshows, such as eadrefid or damspath. 
                * SelectedImages.gif is a fallback, should a thumb not be available.
                * Typically, thumbnail has been first image from the slideshow (sort=p.damsmdm.order_number asc, url asc) -->
            
            <!-- Updates for MADS, plus a tiny refactor -->
            <xsl:variable name="normalized-href" select="normalize-space(lower-case(@*:href))"/>
            <xsl:variable name="thumbnail-uri">
                <xsl:choose>
                    <!-- new patch, for the MADS convention of using '/poster' URLs for thumbnails-->
                    <!-- Update:  only match the current-style MADS links, not the old-school ones... also, no need to keep "mads-internal" as part of the match-->
                    <xsl:when test="matches($normalized-href, 'mads.si.edu/mads/view/')">
                        <xsl:value-of select="replace(@*:href, '/mads/view/', '/mads/id/') || '/poster'"/>
                    </xsl:when>
                    <!-- and, to continue supporitng the old-school MADS links until those are switched over -->
                    <xsl:when test="matches($normalized-href, 'mads.si.edu/assets/player')">
                        <xsl:variable name="old_mads_uri" select="normalize-space(substring-after(@*:href,'name='))"/>
                        <xsl:variable name="old_mads_path" select="tokenize($old_mads_uri,'/')[last()]"/>
                        <xsl:variable name="old_mads_filename" select="substring-after(replace($old_mads_path,'/',''),'-')"/>                     
                        <xsl:value-of select="$old_mads_uri || '/' || $old_mads_path || '/' || $old_mads_filename || '.jpg'"/>
                    </xsl:when>
                    <!-- combining a few when statements into one... also adding the option that the href could end in .jpeg, just in case -->
                    <!-- why don't we use a IIIF thumbnail here???  instead, we're just grabbing the full size image for the URL, and then IDS and/or SOVA has to do the shrinkin' -->
                    <xsl:when test="matches($normalized-href, 'ids.si.edu|.jp(e?)g$|.gif$')">
                        <xsl:value-of select="@*:href"/>
                    </xsl:when>
                    <!-- revisit this, once a review of the URLs is done.  it's not immediately clear why this test is written this way, or why it would come first. -->
                    <xsl:when test="matches($normalized-href, 'slideshow') and (matches($normalized-href, 'edan.si.edu')  or matches($normalized-href,'collections.si.edu/search/slideshow_embedded'))
                        or matches(@*:role, 'image', 'i')">
                        <xsl:text>https://sirismm.si.edu/siris/SelectedImages.gif</xsl:text>
                    </xsl:when>
                    <!-- going with a case-insenstive match rather than the function... but should test and see if either approach is more performant -->
                    <xsl:when test="matches(@*:role, 'audio', 'i')">
                        <xsl:text>https://sirismm.si.edu/siris/sound.gif</xsl:text>
                    </xsl:when>
                    <xsl:when test="matches(@*:role, 'video', 'i')">
                        <xsl:text>https://sirismm.si.edu/siris/video.gif</xsl:text>
                    </xsl:when>
                    <xsl:when test="matches(@*:role, 'georeference', 'i')">
                        <xsl:text>https://sirismm.si.edu/siris/map.gif</xsl:text>
                    </xsl:when>
                    <!-- if we can upgrade Saxon and add http://expath.org/spec/file, then we should remove this otherwise statement and only add this value if the file:exists($thumbnail-uri) equals false()-->
                    <xsl:otherwise>
                        <xsl:text>https://sirismm.si.edu/siris/electronicresource.gif</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <!-- here's where we add the value, with a final backup option (not checked right now, but assumed to be online) -->
            <thumbnail>
                <xsl:value-of select="$thumbnail-uri"/>
            </thumbnail>

            
            <caption>
                <xsl:choose>
                    <xsl:when test="ead:daodesc">
                        <xsl:value-of select="ead:daodesc"/>
                    </xsl:when>
                    <xsl:when test="@*:title">
                        <xsl:value-of select="@*:title"/>
                    </xsl:when>
                    <xsl:when test="ancestor::ead:c[1]/ead:did/ead:unittitle">
                        <xsl:value-of select="ancestor::ead:c[1]/ead:did/ead:unittitle"/>
                    </xsl:when>
                    <xsl:otherwise>Digital content</xsl:otherwise>
                </xsl:choose>
            </caption>
            <content>
                <xsl:value-of select="@*:href"/>
            </content>
            <xsl:if test="$flag='inherited' or lower-case(@*:role) = 'representative-image'">
                <flag>inherited</flag>
            </xsl:if>
        </media>
    </xsl:template>
    
    <!-- yes, we need to start this from scratch. but for now, here's how we'll handle ASpace digital objects with more than one file URI, which result in daogrp elements when serilaized to EAD2002 -->
    <xsl:template name="daogrp-media">
        <!-- might need to update ASpace to export the DAO type, and start using that field, if needed -->
        <xsl:variable name="typeAndIndexedType" select="'Electronic resource'" as="xs:string"/>
        <media>            
            <type>
                <xsl:value-of select="$typeAndIndexedType"/>
            </type>
            <indexedType>
                <xsl:value-of select="$typeAndIndexedType"/>
            </indexedType>
            <!-- being explicit in the system of record sure has its benefits -->
            <thumbnail>
                <xsl:value-of select="if (ead:daoloc[@xlink:role eq 'image-thumbnail']) then ead:daoloc[@xlink:role eq 'image-thumbnail']/@xlink:href else 'https://sirismm.si.edu/siris/electronicresource.gif'"/>
            </thumbnail>
           <caption>
                <xsl:value-of select="ead:daodesc"/>
            </caption>
            <content>
                <xsl:value-of select="ead:daoloc[@xlink:role eq 'web-resource-link']/@xlink:href"/>
            </content>
        </media>
    </xsl:template>
      
    <!-- BEGIN DESCRIPTIVE DETAILS, NOTES, ACCESS TERMS etc -->
    <!-- Descriptive details: include all freetext fields (notes, access terms, setNames)-->
    <xsl:template name="freetext">
        <xsl:param name="unitid_component_id"/>
        <freetext>
            <xsl:call-template name="didDetails">
                <xsl:with-param name="unitid_component_id" select="$unitid_component_id"/>
            </xsl:call-template>
            <xsl:call-template name="containers"/>
            <xsl:call-template name="eadheaderNotes"/>
            <xsl:call-template name="narrativeNotes"/>
            <xsl:call-template name="inheritedNotes"/>
            <xsl:call-template name="accessTerms"/>
            <xsl:call-template name="categories"/>
        </freetext>
    </xsl:template>

    <!-- Basic Descriptive info from the ead:did, includes: titles, creators, dates -->
    <xsl:template name="didDetails">
        <xsl:param name="unitid_component_id"/>
        <xsl:for-each select="ead:did/ead:origination[lower-case(@label)='creator']/*[normalize-space()]">
            <creator>
                <xsl:call-template name="noteDetails"/>
            </creator>
        </xsl:for-each>

        <!-- add date flags -->
        <xsl:for-each select="ead:did/ead:unitdate[normalize-space()]">
            <xsl:element name="{name()}">
                <xsl:call-template name="noteDetails"/>
                <indexedContent>
                    <xsl:apply-templates select="@normal"/>
                </indexedContent>
                <xsl:for-each select="@*">
                    <flag>
                        <xsl:value-of select="name()"/>
                        <xsl:value-of select="concat(':',replace(.,':',''))"/>
                    </flag>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>

        <xsl:for-each select="ead:did/ead:physdesc[normalize-space()]">
            <physdesc>
                <!--ead:extent | ead:dimensions | ead:physfacet | .[text()]-->
                    <xsl:call-template name="noteDetails">
                        <xsl:with-param name="physDetails" select="count(child::*)"/>
                    </xsl:call-template>
              
            </physdesc>
        </xsl:for-each>

        <xsl:for-each select="ead:did/ead:materialspec[normalize-space()]
            | ead:did/ead:physloc[normalize-space()]">
            <xsl:element name="{name()}">
                <xsl:call-template name="noteDetails"/>
            </xsl:element>
        </xsl:for-each>
        
        <xsl:for-each select="ead:did/ead:abstract[normalize-space()]">
            <xsl:element name="{name()}">
                <xsl:call-template name="noteDetails"/>
            </xsl:element>
        </xsl:for-each>
        
        <xsl:for-each select="$unitid_component_id"> 
            <identifier>
                <xsl:call-template name="noteDetails">
                    <xsl:with-param name="identifier" select="'true'"/>
                    <xsl:with-param name="level" select="ancestor::ead:c[1]/@level"/>
                </xsl:call-template>
            </identifier>
        </xsl:for-each>
        
    </xsl:template>
    
    <!-- Build out entries for the box/folder containers. Repeatable , not required-->
    <xsl:template name="containers">
        <xsl:for-each-group select="ead:did/ead:container" group-by="@id|@parent">
            <xsl:element name="{name()}">
                <label>
                    <xsl:value-of select="sova:capitalize-first(sova:tagName(.))"/>
                </label>
                <content>
                    <xsl:for-each select="current-group()">
                        <xsl:value-of select="concat(@type,' ',normalize-space(.))"/>
                        <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                    </xsl:for-each>
                   <!-- <xsl:if test="@label">
                        <xsl:value-of select="concat(' (',@label,')')"/>
                    </xsl:if>-->
                </content>
            </xsl:element>
        </xsl:for-each-group>
    </xsl:template>

    <!-- NOTES -->
    <!-- A small number of notes from the top level finding aid data should be included:
            * sponsor note -->
    <xsl:template name="eadheaderNotes">
        <xsl:for-each select="/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:sponsor">
            <xsl:element name="{name()}">
                <xsl:call-template name="noteDetails"/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <!-- Most notes are at the specific descriptive level and are repeatable. -->
    <xsl:template name="narrativeNotes">
        <xsl:for-each
            select="child::*[not(self::ead:dsc)][not(self::ead:c)]
            [not(self::ead:did)][not(self::ead:controlaccess)]
            [not(self::ead:dao)]
            [child::*[not(self::ead:head)][normalize-space()]]">
            <!--<xsl:sort select="name()"/>-->

            <xsl:element name="{name()}">
                <xsl:call-template name="noteDetails"/>
            </xsl:element>

        </xsl:for-each>
    </xsl:template>

    <!-- Some notes inherit from the collection level, if-and-only-if not found at this level (i.e. ancestor-or-self[1])
        * Citation
        * Use conditions
        * Access conditions
    -->
    <xsl:template name="inheritedNotes">
        <!-- inherit citation or restriction notes data if-and-only-if a more specific note is not found at this level.-->

        <xsl:if test="not(child::ead:accessrestrict)">
            <xsl:for-each select="ancestor::ead:*[ead:accessrestrict][1]/ead:accessrestrict">
                <xsl:element name="{name()}">
                    <xsl:call-template name="noteDetails">
                        <xsl:with-param name="level" select="parent::*/@level"/>
                        <xsl:with-param name="flag" select="'inherited'"/>
                    </xsl:call-template>
                </xsl:element>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="not(child::ead:userestrict)">
            <xsl:for-each select="ancestor::ead:*[ead:userestrict][1]/ead:userestrict">
                <xsl:element name="{name()}">
                    <xsl:call-template name="noteDetails">
                        <xsl:with-param name="level" select="parent::*/@level"/>
                        <xsl:with-param name="flag" select="'inherited'"/>
                    </xsl:call-template>
                </xsl:element>
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="not(child::ead:prefercite)">
            <xsl:for-each select="ancestor::ead:*[ead:prefercite][1]/ead:prefercite">
                <xsl:element name="{name()}">
                    <xsl:call-template name="noteDetails">
                        <xsl:with-param name="level" select="parent::*/@level"/>
                        <xsl:with-param name="flag" select="'inherited'"/>
                    </xsl:call-template>
                </xsl:element>
            </xsl:for-each>
        </xsl:if>

    </xsl:template>

    <!-- This section builds out basic parts of all notes. Nearly all notes work the same way in EAD documents -->
    <xsl:template name="noteDetails">
        <xsl:param name="flag"/>
        <xsl:param name="level"/>
        <xsl:param name="physDetails"/>
        <xsl:param name="identifier"/>

        <label>
            <xsl:if test="$flag = 'inherited'">
                <xsl:value-of select="concat(sova:capitalize-first($level),' ')"/>
            </xsl:if>
            <xsl:value-of select="sova:capitalize-first(sova:tagName(.))"/>
        </label>
        
        <content>
            <xsl:choose>
                <xsl:when test="number($physDetails) gt 1">
                    <!-- print phys details in one line, following ISAD(G): General International Standard Archival Description -->
                    <xsl:apply-templates select="ead:extent[1]"/>
                    <xsl:text> (</xsl:text>
                    <xsl:value-of select="ead:extent[2] | ead:physfacet | ead:dimensions" separator=", "/>
                    <xsl:text>)</xsl:text>
                </xsl:when>
                <!-- TO DO: review this -->
                <xsl:when test="$identifier = 'true' and $level">
                    <xsl:value-of select="concat(ancestor::ead:archdesc/ead:did/ead:unitid[not(@audience='internal')][not(starts-with(@*:type,'ark'))][1], ', ')"/>
                    <xsl:if test="not(starts-with(lower-case(.),$level))">
                        <xsl:value-of select="concat(sova:capitalize-first($level),' ')"/>
                    </xsl:if>
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </content>
        
        <xsl:if test="$flag = 'inherited'">
            <flag>inherited</flag>
        </xsl:if>
    </xsl:template>

    <!-- BEGIN ACCESS TERMS -->
    <!-- Access terms can be found at any level, generally all work the same way -->
    <xsl:template name="accessTerms">
        <!-- names -->
        <!-- lots of "for-each" loopin' going on.  Anyhow, the patch here is to make sure that nested controlaccess sections with names are picked up, just as they are for topics, etc. 
            looks like a simple oversight due to all the for-eaches :) -->
        <xsl:for-each select="ead:did/ead:origination[lower-case(@label)='creator'] | ead:controlaccess[ead:corpname | ead:famname | ead:name | ead:persname] | ead:controlaccess//ead:controlaccess[ead:corpname | ead:famname | ead:name | ead:persname]"> 
            <xsl:for-each select="ead:corpname | ead:famname | ead:name | ead:persname">
                <xsl:sort select="parent::*" order="descending"/>
                <xsl:sort select="name()" order="ascending"/>
                <xsl:sort select="."/>
                
                <xsl:call-template name="accessDetails"/>
            </xsl:for-each>
        </xsl:for-each>

        <!-- now, inherit collection creators to components -->
        <xsl:if test="self::ead:c">
            <xsl:for-each select="/ead:ead/ead:archdesc/ead:did/ead:origination[lower-case(@label)='creator']">
                <xsl:for-each select="ead:corpname | ead:famname | ead:name | ead:persname">
                    <xsl:sort select="parent::*" order="descending"/>
                    <xsl:sort select="name()" order="ascending"/>
                    <xsl:sort select="."/>

                    <xsl:call-template name="accessDetails">
                        <xsl:with-param name="flag" select="'inherited'"/>
                        <xsl:with-param name="level" select="ancestor::ead:*[@level]/@level"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:for-each>
        </xsl:if>

        <!-- controlaccess subject terms -->
        <xsl:for-each select="ead:controlaccess[ead:function | ead:genreform | ead:geogname | ead:occupation | ead:subject | ead:title]
            | ead:controlaccess//ead:controlaccess[ead:function | ead:genreform | ead:geogname | ead:occupation | ead:subject | ead:title]">

            <xsl:for-each select="ead:function | ead:genreform | ead:geogname | ead:occupation | ead:subject | ead:title">
                <xsl:sort select="parent::*" order="descending"/>
                <xsl:sort select="name()" order="ascending"/>

                <xsl:call-template name="accessDetails"/>

            </xsl:for-each>

        </xsl:for-each>

    </xsl:template>

    <!-- Some special handling for culture terms -->
    <xsl:template name="accessDetails">
        <xsl:param name="flag"/>
        <xsl:param name="level"/>
        <xsl:variable name="accessTerm">
            <xsl:choose>
                <xsl:when test="self::ead:corpname | self::ead:famname | self::ead:name | self::ead:persname">
                    <xsl:text>name</xsl:text>
                </xsl:when>
                <xsl:when test="self::ead:subject[@altrender = 'culture']
                    | self::ead:subject[@altrender = 'cultural_context']
                    | self::ead:subject[contains(.,'^^695')]">
                    <xsl:text>culture</xsl:text>
                </xsl:when>
                <xsl:when test="self::ead:geogname">
                    <xsl:text>place</xsl:text>
                </xsl:when>
                <xsl:when test="self::ead:occupation | self::ead:subject[not(@altrender = 'culture')]
                    | self::ead:subject[not(@altrender = 'cultural_context')]">
                    <xsl:text>topic</xsl:text>
                </xsl:when>
                <xsl:when test="self::ead:genreform">
                    <xsl:text>genre_format</xsl:text>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:value-of select="name()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="nameType">
            <xsl:choose>
                <xsl:when test="name() = 'persname'">
                    <xsl:text>personal</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'corpname'">
                    <xsl:text>corporate</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'famname'">
                    <xsl:text>family</xsl:text>
                </xsl:when>
                <xsl:when test="name() = 'name'">
                    <xsl:text>name</xsl:text>
                </xsl:when>
                <xsl:otherwise/>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="nameRole">
            <xsl:choose>
                <xsl:when test="parent::ead:origination">
                    <xsl:text>main</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>subject</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:element name="{$accessTerm}">
            <label>
                <xsl:if test="$flag = 'inherited'">
                    <xsl:value-of select="concat(sova:capitalize-first($level),' ')"/>
                </xsl:if>
                <xsl:value-of select="sova:capitalize-first(sova:tagName(.))"/>
            </label>
            
            <content>
                <xsl:apply-templates/>
            </content>
            
            <indexedContent>
                <xsl:apply-templates select="."/>
            </indexedContent>
            <xsl:if test="$nameType[normalize-space()]">
                <flag>
                    <xsl:value-of select="concat($nameType,'_','name')"/>
                </flag>
                <flag>
                    <xsl:value-of select="concat($nameType,'_',$nameRole)"/>
                </flag>
            </xsl:if>

            <xsl:if test="$flag='inherited'">
                <flag>inherited</flag>
            </xsl:if>

        </xsl:element>
    </xsl:template>

    <!-- Some leftover special handling from AT. Keep this around, for older files, but can deprecate down the line -->
    <xsl:template name="subject-string" match="ead:subject | ead:genreform | ead:geogname 
        | ead:occupation | ead:function | ead:title
        | ead:persname | ead:corpname | ead:famname | ead:name">
        <xsl:choose>
            <xsl:when test="contains(., ' **')">
                <xsl:value-of select="normalize-space(substring-before(., ' **'))"/>
            </xsl:when>
            <xsl:when test="contains(., ' ##')">
                <xsl:value-of select="normalize-space(substring-before(., ' ##'))"/>
            </xsl:when>
            <xsl:when test="contains(., ' ^^')">
                <xsl:value-of select="normalize-space(substring-before(., ' ^^'))"/>
            </xsl:when>
            <xsl:when test="matches(., '--')">
                <xsl:value-of select="normalize-space(substring-before(., '--'))"/>
            </xsl:when>

            <xsl:when test="ends-with(name(),'name') and matches(.,', \d{4}-\d{4}')">
                <xsl:analyze-string select="." regex="(.*), \d\d\d\d-\d\d\d\d, [a-z]*$">
                    <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="(.*), \d\d\d\d-\d\d\d\d$">
                            <xsl:matching-substring>
                                <xsl:value-of select="regex-group(1)"/>
                            </xsl:matching-substring>
                            <xsl:non-matching-substring>
                                <xsl:value-of select="."/>
                            </xsl:non-matching-substring>
                        </xsl:analyze-string>

                    </xsl:non-matching-substring>

                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <!-- BEGIN CATEGORIES 
        * dataSource
        * setNames (overall collection, and breadcrumb sets)
        * object types (generic types for all records, plus types from extent, genre etc.
    -->
    <xsl:template name="categories">
        <dataSource>
            <label>Archival Repository</label>
            <content>
                <xsl:value-of select="//ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:publisher"/>
            </content>
            <indexedContent>
                <xsl:value-of select="//ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:publisher"/>
            </indexedContent>
        </dataSource>
        
        <!-- SetNames:  
            1. first set name is the toplevel resource title, if collection has an inventory 
            2. then any breadcrumb path, if hierarchy present (i.e. skip if flat)
        -->
        
        <xsl:if test="//ead:ead/ead:archdesc/ead:dsc[normalize-space()]">
            <!-- 1. resource title: return everything from this collection -->
            <setName>
                <label>See more items in</label>
                <content>
                    <xsl:value-of select="//ead:ead/ead:archdesc/ead:did/ead:unittitle"/>
                </content>
                <indexedContent>
                    <xsl:value-of select="//ead:ead/ead:archdesc/ead:did/ead:unittitle"/>
                </indexedContent>
            </setName>
            
            <!-- 2. breadcrumb setName   -->
            <xsl:if test="ancestor::ead:c">
                <!-- i.e. a file has parent series
                    given = Series 1: Ohio / Photographs / you-are-here 
                    returns = Series 1: Ohio / Photographs -->
                <xsl:variable name="breadcrumb">
                    <xsl:value-of select="//ead:ead/ead:archdesc/ead:did/ead:unittitle"/>
                    <xsl:for-each select="ancestor::ead:c"> 
                        <xsl:text> / </xsl:text>
                        <xsl:if test="ead:did/ead:unitid[not(@audience = 'internal')][not(starts-with(@*:type,'ark'))][normalize-space()][1]">
                            <xsl:value-of select ="ead:did/ead:unitid[not(@audience = 'internal')][not(starts-with(@*:type,'ark'))][1]"/>
                            <xsl:text>: </xsl:text>
                        </xsl:if>
                        <xsl:value-of select="ead:did/ead:unittitle[normalize-space()]"/>
                    </xsl:for-each>
                </xsl:variable>
                <setName>
                    <label>See more items in</label>
                    <content> <xsl:value-of select="$breadcrumb"/> </content>
                    <indexedContent> <xsl:value-of select="$breadcrumb"/> </indexedContent>
                </setName>
            </xsl:if>
        </xsl:if>
        
        <!-- resource level gets Collection Descriptions -->
        <xsl:if test="self::ead:archdesc">
            <xsl:call-template name="objectType">
                <xsl:with-param name="term" select="'Collection descriptions'"/>
                <xsl:with-param name="objectType" select="'Collection descriptions'"/>
            </xsl:call-template>           
        </xsl:if>
        
        <!-- all resource and archival objects get 'Archival Materials' -->
        <xsl:call-template name="objectType">
            <xsl:with-param name="term" select="'Archival materials'"/>
            <xsl:with-param name="objectType" select="'Archival materials'"/>
        </xsl:call-template>   
        
        <!-- instance types, extent types, genreform can be passed to flipping tables for objectTypes -->
        <xsl:for-each-group select="ead:did/ead:container" group-by="@label">
           <xsl:if test="not(contains(lower-case(current-grouping-key()),'mixed')
               or contains(lower-case(current-grouping-key()),'box')) ">
               <xsl:call-template name="objectType">
                    <xsl:with-param name="term" select="current-grouping-key()"/>
                    <xsl:with-param name="objectType" select="current-grouping-key()"/>
                </xsl:call-template>
           </xsl:if>
        </xsl:for-each-group>
        
        <xsl:for-each-group 
            select="ead:did/ead:physdesc/ead:extent[1]/@type 
            | ead:controlaccess/ead:genreform 
            | ead:controlaccess/ead:controlaccess/ead:genreform" 
            group-by="normalize-space(replace(lower-case(.), ' -\-.*',''))">
            <xsl:if test="not(
                        contains(lower-case(current-grouping-key()),'feet')
                        or contains(lower-case(current-grouping-key()),'foot')
                        or contains(lower-case(current-grouping-key()),'inch')
                        or contains(lower-case(current-grouping-key()),'box')
                        or contains(lower-case(current-grouping-key()),'folder')
                        or contains(lower-case(current-grouping-key()),'item')
                        )">
                <xsl:call-template name="objectType">
                    <xsl:with-param name="term" select="current-grouping-key()"/>
                    <xsl:with-param name="objectType" select="current-grouping-key()"/>
                </xsl:call-template>
            </xsl:if>
        </xsl:for-each-group>
     
    </xsl:template>
    
    <!-- General building block for object type facet for CSC-->
    <xsl:template name="objectType">
       <xsl:param name="term"/>
       <xsl:param name="objectType"/>
        <objectType>
            <label>Type</label>
            <content>
                <xsl:value-of select="sova:capitalize-first($term)"/>
            </content>
            <indexedContent>
                <xsl:value-of select="normalize-space(sova:capitalize-first($objectType))"/>
            </indexedContent>
        </objectType>
    </xsl:template>

    <!-- USAGE FLAGS: Usage flag to support specific local needs.  
        * Flag very large EAD, to try to address load time issues.
    -->
    <xsl:template name="usage_flag">
        <xsl:if test="$countComponents > 1000">
            <usage_flag>Large EAD</usage_flag>
        </xsl:if>      
    </xsl:template>
    
    <!-- SORT:
        * Supply limited sort fields for CSC / EDAN. 
        * per AG: Casing is not important as we actually lower case everything and remove any char not in 0-9a-z   
    -->
    <xsl:template name="sort">
        <sort>
            <name>
                <xsl:choose>
                    <xsl:when test="ead:did/ead:origination[lower-case(@role)='creator'][1]/normalize-space()">
                        <xsl:value-of select="normalize-space(ead:did/ead:origination[1])"/>
                    </xsl:when>
                    <xsl:when test="/ead:ead/ead:archdesc/ead:did/ead:origination[lower-case(@role)='creator'][1]/normalize-space()">
                        <xsl:value-of select="normalize-space(/ead:ead/ead:archdesc/ead:did/ead:origination[1])"/>
                    </xsl:when>
                    <xsl:when test="/ead:ead/ead:archdesc/ead:did/ead:repository[1]/normalize-space()">
                        <xsl:value-of select="normalize-space(/ead:ead/ead:archdesc/ead:did/ead:repository[1])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>Smithsonian Institution</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </name>
            
            <!-- sort title -->
            <xsl:variable name="filingTitle" select="/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper[@type='filing'][1]"/>
            <xsl:variable name="cleanTitle" select="replace(normalize-space(ead:did/ead:unittitle[1]),'^(A |An |The )','')"/>
            
            <xsl:choose>
                <xsl:when test="self::ead:archdesc">
                    <xsl:choose>
                        <xsl:when test="$filingTitle">
                            <title><xsl:value-of select="$filingTitle"/></title>
                        </xsl:when>
                        <xsl:otherwise>
                            <title><xsl:value-of select="$cleanTitle"/></title>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                
                <!-- components don't have a filing title field -->
                <xsl:otherwise>
                    
                    <xsl:choose>
                        <xsl:when test="ead:did/ead:unittitle[normalize-space()]">
                            <title><xsl:value-of select="$cleanTitle"/></title>
                        </xsl:when>
                        <xsl:otherwise>
                            <title>Untitled</title>
                        </xsl:otherwise>
                    </xsl:choose>
                    
                </xsl:otherwise>
                
            </xsl:choose>
            
           <!-- sort document order -->
            <doc_number>
                <xsl:number count="ead:c | ead:archdesc" level="any"/>
            </doc_number>
                        
        </sort>
    </xsl:template>

    
    <!-- NOTE content details
        * Omit ead:head from the content
        * Flatten complex ead note strucures such as chron
    -->
    <!-- Don't include the head elements in content block -->
    <xsl:template match="ead:head"/>

    <!-- Flatten out complex note part structures -->
    <xsl:template match="ead:p[normalize-space()]">
        <xsl:apply-templates/>
        <xsl:if test="following-sibling::*">
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        
    </xsl:template>
    
    <!-- Flatten out complex chronology structures -->
    <xsl:template match="ead:list[normalize-space()] | ead:chronlist[normalize-space()]">
        <xsl:if test="ead:head">
            <xsl:value-of select="ead:head"/>
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:apply-templates/>
        <xsl:if test="following-sibling::*">
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <!-- Flatten out complex list/item structures -->
    <xsl:template match="ead:item | ead:indexentry | ead:bibref | ead:defitem">
        <xsl:if test="preceding-sibling::*[1]/name() = name(.)">
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:choose>
                <xsl:when test="parent::ead:list/@numeration = 'arabic'">
                    <xsl:number value="position()"/>
                    <xsl:text>. </xsl:text> 
                </xsl:when>
                <xsl:when test="parent::ead:list/@numeration = 'upperroman'">
                    <xsl:number value="position()" format="I"/>
                    <xsl:text>. </xsl:text> 
                </xsl:when> 
                <xsl:when test="parent::ead:list/@numeration = 'lowerroman'">
                    <xsl:number value="position()" format="i"/>
                    <xsl:text>. </xsl:text> 
                </xsl:when>
                <xsl:when test="parent::ead:list/@numeration = 'upperalpha'">
                    <xsl:number value="position()" format="A"/>
                    <xsl:text>. </xsl:text> 
                </xsl:when>
                <xsl:when test="parent::ead:list/@numeration = 'loweralpha'">
                    <xsl:number value="position()" format="a"/>
                    <xsl:text>. </xsl:text> 
                </xsl:when>
                
            </xsl:choose>
        
        <xsl:value-of select="node()" separator=" -- "/>
    </xsl:template>

    <!-- Flatten out complex chron item structures -->
    <xsl:template match="ead:chronitem">
        <xsl:if test="preceding-sibling::*[1]/name() = name(.)">
            <xsl:text>&#10;&#10;</xsl:text>
        </xsl:if>
        <xsl:value-of select="concat(ead:date,' -- ')"/>
        <xsl:value-of select="ead:eventgrp/ead:event | ead:event" separator=" "/>
    </xsl:template>
   
   
    <!-- BOOSTS -->
    <!-- Add boosts to force digitized results to higher in CSC results -->
    <xsl:template name="boostval">
        <!--<xsl:if test="ead:dao[not(lower-case(@*:role) = 'representative-image')]
            or /ead:ead/ead:eadheader/ead:eadid/@url">-->
        <xsl:choose>
            <!-- if THIS level has a dao, boost -->
            <xsl:when test="ead:dao[not(lower-case(@*:role) = 'representative-image')]
                | ead:did/ead:dao[not(lower-case(@*:role) = 'representative-image')]">
                <xsl:text>6.4</xsl:text>
            </xsl:when>
            <!-- if a collection, boost. consider boost to 6.4? 
                consider digitized collections, but dao at lower levels. -->
            <xsl:when test="@level = 'collection'">
                <xsl:text>6</xsl:text>
            </xsl:when>
            <xsl:when test="ead:controlaccess">
                <xsl:text>3</xsl:text>
            </xsl:when>
            <!-- check for presence of other descriptive notes, beyond the basic ead:did -->
            <!-- this is also boosting to 2 when there are ead:c children
                ...so something with children would be higher than a leaf node .  If a note should out-rank a child (probably) we can adjust this by including [not(self::ead:c)]-->
            <xsl:when test="child::*[not(self::ead:did)]">
                <xsl:text>2</xsl:text>
            </xsl:when>

            <!-- has a ead:did with something other than the id/title/date -->
            <xsl:when test="ead:did/child::*[not(self::ead:unitid)][not(self::ead:unittitle)][not(self::ead:unitdate)]">
                <xsl:text>1.4</xsl:text>
            </xsl:when>

            <!-- demote 'shell' only components. i.e. only a title-->
            <xsl:otherwise>.5</xsl:otherwise>
        </xsl:choose>

    </xsl:template>


    <!-- Control all tag names and labels here -->
    <xsl:function name="sova:tagName">
        <!-- element node as parameter -->
        <xsl:param name="elementNode"/>
        <!-- Name of element -->
        <xsl:variable name="tag" select="name($elementNode)"/>
        <!-- Find element name -->
        <xsl:choose>
            <!-- did/origination: label is role ('donor'), then orig label (creator or subject), then default Names -->
            <xsl:when test="$elementNode/@role[normalize-space()]">
                <xsl:value-of select="replace( replace($elementNode/@role,' \(.*',''), '_',' ')"/>
            </xsl:when>
            <xsl:when test="$elementNode/parent::ead:origination/@label[normalize-space()]">
                <xsl:value-of select="$elementNode/parent::ead:origination/@label"/>
            </xsl:when>
            <!-- sometimes origination has no specific role label -->
            <xsl:when test="$elementNode/parent::ead:origination">Creator</xsl:when>

            <!-- did other -->
            <xsl:when test="$tag = 'unitdate'">Date</xsl:when>
            <xsl:when test="$tag = 'physdesc'">Extent</xsl:when>
            <xsl:when test="$tag = 'extent'">Extent</xsl:when>
            <xsl:when test="$tag = 'physfacet'">Physical Details</xsl:when>
            <xsl:when test="$tag = 'dimensions'">Dimensions</xsl:when>
            <xsl:when test="$tag = 'abstract'">Summary</xsl:when>
            <xsl:when test="$tag = 'unitid'">Identifier</xsl:when>
            <xsl:when test="$tag = 'container'">Container</xsl:when>
            <!-- notes -->
            <xsl:when test="$tag = 'sponsor'">Sponsor</xsl:when>
            <xsl:when test="$tag = 'userestrict'">Rights</xsl:when>
            <xsl:when test="$tag = 'accessrestrict'">Restrictions</xsl:when>
            <xsl:when test="$tag = 'prefercite'">Citation</xsl:when>
            <xsl:when test="$tag = 'acqinfo'">Provenance</xsl:when>
            <!-- access -->
            <xsl:when test="$tag = 'persname'">Names</xsl:when>
            <xsl:when test="$tag = 'corpname'">Names</xsl:when>
            <xsl:when test="$tag = 'famname'">Names</xsl:when>
            <xsl:when test="$tag = 'name'">Names</xsl:when>
            
            <xsl:when test="$tag = 'geogname' and contains($elementNode,'^^695')">Culture</xsl:when>
            <xsl:when test="$tag = 'geogname' and $elementNode/@altrender='culture'">Culture</xsl:when>
            <xsl:when test="$tag = 'geogname' and $elementNode/@altrender='cultural_context'">Culture</xsl:when>
            
            <xsl:when test="$tag = 'subject' and contains($elementNode,'^^695')">Culture</xsl:when>
            <xsl:when test="$tag = 'subject' and $elementNode/@altrender='culture'">Culture</xsl:when>
            <xsl:when test="$tag = 'subject' and $elementNode/@altrender='cultural_context'">Culture</xsl:when>
            
            <xsl:when test="$tag = 'geogname'">Place</xsl:when>
            <xsl:when test="$tag = 'subject'">Topic</xsl:when>
            
            <xsl:when test="$tag = 'title'">Topic</xsl:when>
            <xsl:when test="$tag = 'genreform'">Genre/Form</xsl:when>
            <xsl:when test="$tag = 'function'">Function</xsl:when>
            <xsl:when test="$tag = 'occupation'">Occupation</xsl:when>
            

            <!-- anything else gets its own header -->
            <xsl:when test="$elementNode/ead:head or $elementNode/@label">
                <xsl:value-of select="$elementNode/ead:head | $elementNode/@label"/>
            </xsl:when>

            <!-- or if none, then Note -->
            <xsl:otherwise>Note</xsl:otherwise>

        </xsl:choose>
    </xsl:function>

    <!-- A general function to help with capitals throughout the finding aid (mainly the attributes)-->
    <xsl:function name="sova:capitalize-first" as="xs:string?">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:sequence
            select="concat(upper-case(substring($arg,1,1)),
            substring($arg,2))"/>

    </xsl:function>

</xsl:stylesheet>