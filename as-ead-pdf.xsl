<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xlink="http://www.w3.org/1999/xlink" 	xmlns:ns2="http://www.w3.org/1999/xlink"
	xmlns:local="http://some.local.functions" xmlns:xs="http://www.w3.org/2001/XMLSchema" 
	xmlns:ead="urn:isbn:1-931666-22-9" xmlns:fo="http://www.w3.org/1999/XSL/Format" version="2.0" exclude-result-prefixes="#all">
	
	<!--
        *******************************************************************
        *                                                                 *
        * VERSION:          4.1.0  Tested for ASpace Version 4.1.0        *
        *                                                                 *
        * DATE:             2025-09-23                                    *
        *                                                                 *
        * ABOUT:            This file has been created for use with       *
        *                   EAD xml files exported from the               *
        *                   ArchivesSpace.                                *
        *                                                                 *
        *******************************************************************
    -->
	
	<xsl:output method="xml" indent="yes"/>
	
	<!-- Sets SI-unit-acronym.  Used for selecting appropriate pdf logo -->
	<xsl:variable name="SI-unit-acronym">
		<xsl:choose>
			<xsl:when test="/ead:ead/ead:archdesc[1]/ead:did[1]/ead:unitid[@repositorycode = 'DSI-AI']">
				<xsl:text>SIA</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of
					select="substring-before(/ead:ead/ead:archdesc[1]/ead:did[1]/ead:unitid[1], '.')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<!-- Calls a stylesheet with cleanup template (same xsl as used to clean ead for sova) -->
	<xsl:include href="ASpaceCleanup.xsl"/>

	<xsl:param name="image-location"/>
	
	<xsl:variable name="logo-location" select="($image-location[normalize-space()], 'logos')[1]"/>
	
	<!-- Document considered internal if any element other than unitid have audience='internal'
		 Unitid may contain siris_arc or other alternate identifiers -->
	<xsl:param name="audience">
		<xsl:if test="ead:ead//*[not(name()='unitid')][@audience = 'internal']">internal</xsl:if>
	</xsl:param>
	
	<xsl:variable name="archive-logo">
		<xsl:choose>						
			<xsl:when test="$SI-unit-acronym = 'AAA'">si_AAA_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'AAG'">si_SG_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'ACMA'">si_ACM_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'CFCH'">si_CFCH_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'EEPA'">si_NMAA_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'FSA'">2022 NMAA SI logo_two lines_black.svg</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'HSFA'">si_NMNH_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'NAA'">si_NMNH_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'NASM'">si_NASM_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'NMAAHC'">si_NMAAHC_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'NMAH'">si_NMAHKEBC_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'NMAI'">si_NMAI_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'NPG'">si_NPG-f3xcbw0.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SAAM'">si_AAM_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIA'">si_SIA_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-AA'">si_Libraries_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-AAPG'">si_Libraries_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-CH'">si_CH_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-CL'">si_Libraries_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-DL'">si_Libraries_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-FSMC'">si_Libraries_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-NPM'">si_NPM_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-RA'">si_Libraries_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:when test="$SI-unit-acronym = 'SIL-RR'">si_Libraries_cmyk_horizontal_b&amp;w.png</xsl:when>
			<xsl:otherwise>si-logo.png</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:template match="/">		
		<!-- Call the template to be extended here and store the result in a variable-->
		<!-- This is used to achieve multi-pass processing (cleanup, then second transform for pdf) 
			especially when both phases use templates that match the same nodes. -->
		<xsl:variable name="clean_ead">
			<xsl:apply-templates/>
		</xsl:variable>

		<!-- Node set for first pass-->
		<!-- To add more fonts, see also the fop config -->
		<fo:root xmlns:fo="http://www.w3.org/1999/XSL/Format"
			font-family="Arial,Arial Unicode MS,KurintoText,KurintoTextJP,KurintoTextKR,KurintoTextSC,NotoSerif,sans-serif">
			<xsl:apply-templates mode="step2_pdf" select="$clean_ead"/>
		</fo:root>
		
	</xsl:template>

	<!-- don't include ARKs into dsc contents listing display -->
	<xsl:template match="ead:unitid[starts-with(@type,'ark')]"/>
	
	<!--  Start main page design and layout -->
	<xsl:template match="ead:ead" mode="step2_pdf">
		<!-- Set up page types and page layouts -->
		<fo:layout-master-set>
			<!-- Page master for Cover Page -->
			<!-- The margins you set for the region-body must be greater than or equal to the extents of the the region-before and after -->
			<fo:simple-page-master master-name="cover-page" page-width="8.5in" page-height="11in" margin="0.75in">
				<fo:region-body margin-top=".5in" margin-bottom=".25in"/>
				<fo:region-before extent="0.5in"/>
				<fo:region-after extent="1in"/>		
			</fo:simple-page-master>
			<!-- Page master for Table of Contents -->
			<fo:simple-page-master master-name="toc" page-width="8.5in" page-height="11in" margin=".75in">
				<fo:region-body margin-top=".5in" margin-bottom=".25in"/>
				<fo:region-before extent="0.5in"/>
				<fo:region-after extent="0.25in"/>
			</fo:simple-page-master>
			<!-- Page master for Finding Aid Contents -->
			<fo:simple-page-master master-name="contents" page-width="8.5in" page-height="11in" margin=".75in">
				<fo:region-body margin-top=".5in" margin-bottom=".25in"/>
				<fo:region-before extent="0.5in"/>
				<fo:region-after extent="0.25in"/>
			</fo:simple-page-master>
		</fo:layout-master-set>

		<!-- Builds PDF bookmarks for all major sections  -->
		<xsl:apply-templates select="/ead:ead/ead:archdesc" mode="bookmarks"/>
		
		<!-- The fo:page-sequence establishes headers, footers and the body of the page.-->
		<!-- Sequence: Cover page layout -->
		<fo:page-sequence master-reference="cover-page">
			<fo:title>
				<xsl:value-of select="ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper[not(@type='filing')]"/>
			</fo:title>	
			<fo:static-content flow-name="xsl-region-after">
					<xsl:apply-templates select="/ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt" mode="coverPage"/>
					<!-- internal footer -->
					<xsl:if test="$audience = 'internal'">
						<xsl:call-template name="collection-internal"/>	
					</xsl:if>	
			</fo:static-content>			
			<fo:flow flow-name="xsl-region-body">
				<fo:block keep-together.within-page="always" text-align="center">
					<xsl:call-template name="logo"/>
					<xsl:apply-templates select="/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt" mode="coverPage"/>
					<xsl:call-template name="representative-image"/>
					
				</fo:block>
			</fo:flow>
		</fo:page-sequence>
		
		<!-- Sequence: Table of Contents layout -->
		<fo:page-sequence master-reference="toc"  force-page-count="no-force">		
			
			<!-- Page footer -->
			<xsl:if test="$audience = 'internal'">
				<fo:static-content flow-name="xsl-region-after">
					<xsl:call-template name="collection-internal"/>	
				</fo:static-content>
			</xsl:if>
			
			<!-- Content of page -->
			<fo:flow flow-name="xsl-region-body">
				<xsl:apply-templates select="/ead:ead/ead:archdesc" mode="toc"/>
			</fo:flow>
		</fo:page-sequence>
		
		<!-- Sequence: All the rest -->
		<fo:page-sequence master-reference="contents" initial-page-number="1" id="DocumentBody">	
			<!-- Page header -->
			<fo:static-content flow-name="xsl-region-before" margin-top=".15in">					
					<fo:table table-layout="fixed" width="100%" font-size="8pt"> 
						<fo:table-column column-number="1" column-width="50%"/>
							<fo:table-column column-number="2" column-width="50%"/>
						<fo:table-body>
							<fo:table-row>
								<fo:table-cell column-number="1" display-align="before">
									<fo:block>
										<fo:retrieve-marker retrieve-class-name="Series-Level1"
											retrieve-position="first-including-carryover"
											retrieve-boundary="page-sequence"/>
									</fo:block>
								</fo:table-cell>
								<fo:table-cell column-number="2" display-align="before">
									<fo:block text-align="end">
										<xsl:apply-templates
											select="ead:archdesc/ead:did[1]/ead:unittitle[1]"
											mode="step2_pdf"/>
									</fo:block>
									<fo:block text-align="end">
										<xsl:value-of select="ead:eadheader/ead:eadid"/>
									</fo:block>
	
								</fo:table-cell>
							</fo:table-row>
						</fo:table-body>
					</fo:table>
			</fo:static-content>
	
			<!-- Page footer-->
			<fo:static-content flow-name="xsl-region-after">
					<fo:block-container padding="2mm">
						<fo:block font-size="8pt" text-align="center" >
							<xsl:text>Page </xsl:text>
							<fo:page-number/> of <fo:page-number-citation ref-id="last-page"/>
						</fo:block>
						
						<xsl:if test="$audience = 'internal'">
							<xsl:call-template name="collection-internal"/>
						</xsl:if>
					</fo:block-container>
					
						
				</fo:static-content>
	
				<!-- body -->
				<fo:flow flow-name="xsl-region-body">
					<xsl:apply-templates select="ead:archdesc/ead:did" mode="step2_pdf"/>
	
					<!-- archdesc admin info -->
						<xsl:if test="ead:archdesc/ead:acqinfo/* or ead:archdesc/ead:custodhist/*
							or ead:archdesc/ead:separatedmaterial/*
							or ead:archdesc/ead:originalsloc/*
							or ead:archdesc/ead:relatedmaterial/*
							or ead:archdesc/ead:otherfindaid/*
							or ead:archdesc/ead:altformavail/*
							or ead:archdesc/ead:processinfo/*
							or ead:archdesc/ead:prefercite/*
							or ead:archdesc/ead:accessrestrict/*
							or ead:archdesc/ead:userestrict/*
							or ead:archdesc/ead:appraisal/*
							or ead:archdesc/ead:accruals/*">
							<fo:block xsl:use-attribute-sets="h3" font-weight="bold" id="adminInfo">
								<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
								<xsl:text>Administrative Information</xsl:text>
							</fo:block>
							
							<xsl:apply-templates select="ead:archdesc/ead:acqinfo, 
								ead:archdesc/ead:custodhist,ead:archdesc/ead:separatedmaterial,
								ead:archdesc/ead:originalsloc,ead:archdesc/ead:relatedmaterial,
								ead:archdesc/ead:otherfindaid,ead:archdesc/ead:altformavail,
								ead:archdesc/ead:processinfo,ead:archdesc/ead:prefercite,
								ead:archdesc/ead:accessrestrict,ead:archdesc/ead:userestrict,
								ead:archdesc/ead:appraisal,ead:archdesc/ead:accruals" mode="step2_pdf"/>
						</xsl:if>
	
					<!-- archdesc notes -->
					<xsl:apply-templates mode="step2_pdf" select="ead:archdesc/ead:bioghist,
							ead:archdesc/ead:scopecontent,
							ead:archdesc/ead:arrangement,
							ead:archdesc/ead:phystech,
							ead:archdesc/ead:fileplan,
							ead:archdesc/ead:bibliography,
							ead:archdesc/ead:odd,
							ead:archdesc/ead:note,
							ead:archdesc/ead:controlaccess, 
							ead:archdesc/ead:index"/>
					
					<xsl:if test="ead:archdesc/ead:dsc/*">
						<xsl:apply-templates select="ead:archdesc/ead:dsc" mode="step2_pdf"/>
					</xsl:if>
					
					<fo:block id="last-page"/>
				</fo:flow>
			</fo:page-sequence>		
	</xsl:template>
	
	<!-- Cover page templates -->
	<xsl:template match="ead:titlestmt" mode="coverPage">
		<fo:block-container id="cover-page" >
			<fo:block xsl:use-attribute-sets="h1">
				<xsl:apply-templates select="ead:titleproper[not(@type='filing')]" mode="step2_pdf"/>
			</fo:block>
			<xsl:if test="ead:subtitle">
				<fo:block xsl:use-attribute-sets="h4"><xsl:apply-templates select="ead:subtitle" mode="step2_pdf"/></fo:block>
			</xsl:if>
		
			<xsl:if test="$SI-unit-acronym = 'NMAH'">
				<fo:block xsl:use-attribute-sets="h4">
					<xsl:value-of select="/ead:ead/ead:eadheader/ead:eadid"/>
				</fo:block>
			</xsl:if>
		
			<fo:block xsl:use-attribute-sets="h4">
				<xsl:value-of select="ead:author"/>
			</fo:block>
					
			<fo:block xsl:use-attribute-sets="h4">
				<xsl:apply-templates select="ead:sponsor" mode="step2_pdf"/>
			</fo:block>
			
			<fo:block xsl:use-attribute-sets="h4">
				<xsl:value-of select="/ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt//ead:date"/>
			</fo:block>
			
			<!-- if we get more requests for sponsor logos, come up with a more elegant, less in situ solution
			 ...and get a field in ASpace to store the asset name
			-->
			<xsl:if test="ead:sponsor[matches(normalize-space(), 'getty foundation(.?)$', 'i')]">
				<fo:block padding-top="14pt">
					<fo:external-graphic src="url({$logo-location}/Getty_Logo_Small_Blk_RGB.png)"
						width="25%" content-height="25%" scaling="uniform" />					
				</fo:block>
			</xsl:if>
			<xsl:if test="ead:sponsor[matches(normalize-space(), 'smithsonian american women[''’]s history museum(.?)$', 'i')]">
				<fo:block padding-top="14pt">
					<fo:external-graphic src="url({$logo-location}/2x4_SAWHM_Lockup_Standard_Horizontal_RGB_Black.png)"
						width="25%" content-height="25%" scaling="uniform" />					
				</fo:block>
			</xsl:if>
			
		</fo:block-container>
	</xsl:template>
	<xsl:template match="ead:publicationstmt" mode="coverPage">
		<fo:block-container xsl:use-attribute-sets="normal-text-size">
				<fo:block>
					<xsl:apply-templates select="ead:publisher" mode="step2_pdf"/>
				</fo:block>
				<!--<xsl:apply-templates select="ead:address" mode="step2_pdf"/>-->
				<xsl:for-each select="ead:address/ead:addressline">
					<fo:block> <xsl:value-of select="normalize-space(.)"/> </fo:block>
				</xsl:for-each>
				<xsl:for-each select="ead:address/ead:addressline/ead:extptr">
					<fo:block xsl:use-attribute-sets="link">
						<fo:basic-link external-destination="url('{@*:href}')">
							<xsl:apply-templates select="@*:title" mode="step2_pdf"/>
						</fo:basic-link>
					</fo:block>
				</xsl:for-each>
			
			</fo:block-container>
	</xsl:template>
	<xsl:template name="representative-image">
		<!-- NCK 9/20/2015: adds representative images on cover page-->
		<xsl:variable name="representativeImage" select="ead:archdesc/ead:dao[matches(lower-case(@*:role),'representative')][1]/@*:href"/>
		
		<xsl:if test="$representativeImage">
			<fo:block-container space-before="15pt" space-after="15pt">
				<fo:block >
					<fo:external-graphic src="url({$representativeImage})" content-height="200pt" 
						border-color="grey" border-style="groove" border-width="medium" padding="2mm"/>
				</fo:block>
			</fo:block-container>
		</xsl:if>
		
	</xsl:template>
	<xsl:template name="logo">
		<!--LOGO: set content-width to keep new SI logos within margins, centered -->
		<xsl:choose>
			<xsl:when test="$archive-logo">
				<fo:block>
					<fo:external-graphic src="url({$logo-location}/{$archive-logo})"
						width="100%" content-height="100%" content-width="scale-to-fit" scaling="uniform" />					
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block>
					<fo:external-graphic src="si-logo.png"
						width="100%" content-height="100%" content-width="scale-to-fit" scaling="uniform" />
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:template>
	
	<!-- Named template to link back to the table of contents  -->
	<xsl:template name="return-toc">
		<fo:block font-size="8pt" margin-top="12pt" margin-bottom="18pt"
			font-style="italic" text-align="right" keep-with-previous.within-page="always">
			
			<fo:basic-link text-decoration="none" internal-destination="toc" color="#0D6CB6">
				<xsl:text>Return to Table of Contents</xsl:text>
			</fo:basic-link>
		</fo:block>
	</xsl:template>
	
	<!-- Generates PDF Bookmarks -->
	<xsl:template match="ead:archdesc" mode="bookmarks">
		<fo:bookmark-tree>
			<fo:bookmark internal-destination="cover-page">
				<fo:bookmark-title>Title Page</fo:bookmark-title>
			</fo:bookmark>
			<xsl:if test="ead:did">
				<fo:bookmark internal-destination="{local:buildID(ead:did)}">
					<fo:bookmark-title>Collection Overview</fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			<!-- Administrative Information  -->
			<xsl:if test="ead:accessrestrict or ead:userestrict or ead:custodhist or ead:accruals or ead:altformavail or ead:acqinfo or
				ead:processinfo or ead:appraisal or ead:originalsloc or ead:otherfindaid or ead:odd">
				<fo:bookmark internal-destination="adminInfo">
					<fo:bookmark-title>Administrative Information</fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			<xsl:if test="ead:bioghist">
				<fo:bookmark internal-destination="{local:buildID(ead:bioghist[1])}">
					<fo:bookmark-title><xsl:value-of select="local:tagName(ead:bioghist[1])"/></fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			<xsl:if test="ead:scopecontent">
				<fo:bookmark internal-destination="{local:buildID(ead:scopecontent[1])}">
					<fo:bookmark-title><xsl:value-of select="local:tagName(ead:scopecontent[1])"/></fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			<xsl:if test="ead:arrangement">
				<fo:bookmark internal-destination="{local:buildID(ead:arrangement[1])}">
					<fo:bookmark-title><xsl:value-of select="local:tagName(ead:arrangement[1])"/></fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			<!-- Related Materials -->
			<xsl:if test="ead:relatedmaterial or ead:separatedmaterial">
				<fo:bookmark internal-destination="relMat">
					<fo:bookmark-title>Related Materials</fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			
			<xsl:if test="ead:controlaccess">
				<fo:bookmark internal-destination="{local:buildID(ead:controlaccess[1])}">
					<fo:bookmark-title>Names and Subjects</fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			
			<xsl:if test="ead:phystech">
				<fo:bookmark internal-destination="{local:buildID(ead:phystech[1])}">
					<fo:bookmark-title><xsl:value-of select="local:tagName(ead:phystech[1])"/></fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			
			<xsl:if test="ead:bibliography">
				<fo:bookmark internal-destination="{local:buildID(ead:bibliography[1])}">
					<fo:bookmark-title><xsl:value-of select="local:tagName(ead:bibliography[1])"/></fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			<xsl:if test="ead:index">
				<fo:bookmark internal-destination="{local:buildID(ead:index[1])}">
					<fo:bookmark-title><xsl:value-of select="local:tagName(ead:index[1])"/></fo:bookmark-title>
				</fo:bookmark>
			</xsl:if>
			
			<!-- Build Container List menu and submenu -->
			<xsl:for-each select="ead:dsc">
				<xsl:if test="child::*">
					<fo:bookmark internal-destination="{local:buildID(.)}">
						<fo:bookmark-title>Container Listing</fo:bookmark-title>
					</fo:bookmark>
				</xsl:if>
				<!--Creates a submenu for collections, record groups and series and fonds-->
				<xsl:for-each select="child::*[@level = 'collection']  | child::*[@level = 'recordgrp']  | child::*[@level = 'series'] | child::*[@level = 'fonds']">
					<fo:bookmark internal-destination="{local:buildID(.)}">
						<fo:bookmark-title>
							<xsl:choose>
								<xsl:when test="ead:head">
									<xsl:apply-templates select="child::*/ead:head" mode="step2_pdf"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="ead:did/ead:unitid[not(@audience='internal')]"/>
									<xsl:text>: </xsl:text>
									<xsl:value-of select="ead:did/ead:unittitle"/>
								</xsl:otherwise>
							</xsl:choose>
						</fo:bookmark-title>
					</fo:bookmark>
					<!-- Creates a submenu for subfonds, subgrp or subseries -->
					<xsl:for-each select="child::*[@level = 'subfonds'] | child::*[@level = 'subgrp']  | child::*[@level = 'subseries']">
						<fo:bookmark internal-destination="{local:buildID(.)}">
							<fo:bookmark-title>
								<xsl:choose>
									<xsl:when test="ead:head">
										<xsl:apply-templates select="child::*/ead:head" mode="step2_pdf"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="local:capitalize-first-word(@level)"/>
										<xsl:value-of select="ead:did/ead:unitid[not(@audience='internal')]"/>
										<xsl:text>: </xsl:text>
										<xsl:value-of select="ead:did/ead:unittitle"/>
									</xsl:otherwise>
								</xsl:choose>
							</fo:bookmark-title>
						</fo:bookmark>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:for-each>
		</fo:bookmark-tree>
	</xsl:template>
	
	<!-- Table of Contents -->
	<xsl:template match="ead:archdesc" mode="toc">
		<fo:block line-height="18pt">
			<fo:block font-size="16pt" id="toc" text-align="center">Table of Contents</fo:block>
			
			<fo:block-container xsl:use-attribute-sets="section" 
				text-align="justify" text-indent="0in"
				text-align-last="justify" last-line-end-indent=".25in">
				
				<xsl:if test="ead:did">					
					<fo:block>
						<fo:basic-link internal-destination="{local:buildID(ead:did)}">Collection Overview</fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="{local:buildID(ead:did)}"/>
					</fo:block>
				</xsl:if>
				<!-- Administrative Information  -->
				<xsl:if test="ead:accessrestrict or ead:userestrict or ead:custodhist or ead:accruals or ead:altformavail or ead:acqinfo or
					ead:processinfo or ead:appraisal or ead:originalsloc
					or ead:prefercite or ead:relatedmaterial or ead:separatedmaterial">
					<fo:block>
						<fo:basic-link internal-destination="adminInfo">Administrative Information</fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="adminInfo"/>
					</fo:block>
				</xsl:if>
				<xsl:if test="ead:bioghist">
					<fo:block>
						<fo:basic-link internal-destination="{local:buildID(ead:bioghist[1])}"><xsl:value-of select="local:tagName(ead:bioghist[1])"/></fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="{local:buildID(ead:bioghist[1])}"/>
					</fo:block>
				</xsl:if>
				<xsl:if test="ead:scopecontent">
					<fo:block>
						<fo:basic-link internal-destination="{local:buildID(ead:scopecontent[1])}"><xsl:value-of select="local:tagName(ead:scopecontent[1])"/></fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="{local:buildID(ead:scopecontent[1])}"/>
					</fo:block>
				</xsl:if>
				<xsl:if test="ead:arrangement">
					<fo:block>
						<fo:basic-link internal-destination="{local:buildID(ead:arrangement[1])}"><xsl:value-of select="local:tagName(ead:arrangement[1])"/></fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="{local:buildID(ead:arrangement[1])}"/>
					</fo:block>
				</xsl:if>
				<xsl:if test="ead:controlaccess">
					<fo:block>
						<fo:basic-link internal-destination="{local:buildID(ead:controlaccess[1])}">Names and Subjects</fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="{local:buildID(ead:controlaccess[1])}"/>
					</fo:block>
				</xsl:if>
				<xsl:if test="ead:phystech">
					<fo:block>
						<fo:basic-link internal-destination="{local:buildID(ead:phystech[1])}"><xsl:value-of select="local:tagName(ead:phystech[1])"/></fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="{local:buildID(ead:phystech[1])}"/>
					</fo:block>
				</xsl:if>
				<xsl:if test="ead:bibliography">
					<fo:block>
						<fo:basic-link internal-destination="{local:buildID(ead:bibliography[1])}"><xsl:value-of select="local:tagName(ead:bibliography[1])"/></fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="{local:buildID(ead:bibliography[1])}"/>
					</fo:block>
				</xsl:if>
				<xsl:if test="ead:index">
					<fo:block>
						<fo:basic-link internal-destination="{local:buildID(ead:index[1])}"><xsl:value-of select="local:tagName(ead:index[1])"/></fo:basic-link>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:leader leader-pattern="dots"/>
						<xsl:text>&#160;&#160;</xsl:text>
						<fo:page-number-citation ref-id="{local:buildID(ead:index[1])}"/>
					</fo:block>
				</xsl:if>
				
				<!-- Build Container List menu and submenu -->
				<xsl:for-each select="ead:dsc">
					<xsl:if test="child::*">
						<fo:block >
							<fo:basic-link internal-destination="{local:buildID(.)}">Container Listing</fo:basic-link>
							<xsl:text>&#160;&#160;</xsl:text>
							<fo:leader leader-pattern="dots"/>
							<xsl:text>&#160;&#160;</xsl:text>
							<fo:page-number-citation ref-id="{local:buildID(.)}"/>
						</fo:block>
					</xsl:if>
					<!--Creates a submenu for collections, record groups and series and fonds-->
					<xsl:for-each select="child::*[@level='series' or @level='subseries'or @level='subgrp'	or @level='subcollection']" >
						<!-- |  ead:*/ead:index" -->
						
						<xsl:if test="ead:did">
							<fo:block margin-left=".5in">
								<fo:basic-link internal-destination="{local:buildID(.)}">
									<xsl:call-template name="toc_unitid-title-date"/>
								</fo:basic-link>
								<xsl:text>&#160;&#160;</xsl:text>
								<fo:leader leader-pattern="dots"/>
								<xsl:text>&#160;&#160;</xsl:text>
								<fo:page-number-citation ref-id="{local:buildID(.)}"/>
							</fo:block>
						</xsl:if>
							
						<!-- a contents level index (series, subseries, subgrp) -->
						<!--<xsl:if test="ead:index">
							<fo:block  margin-left="1in" margin-right="0in">
								<fo:basic-link internal-destination="{ead:index/@id}">
									<xsl:value-of select="normalize-space(ead:index/ead:head)"/>
									<fo:leader leader-pattern="dots"/>
									<fo:page-number-citation ref-id="{ead:index/@id}"/>
								</fo:basic-link>
							</fo:block>
						</xsl:if>-->
						
					</xsl:for-each>
				</xsl:for-each>
			</fo:block-container>
		</fo:block>
	</xsl:template>
	
	<!-- Internal warning -->
	<xsl:template name="collection-internal">
		<fo:block font-size="10pt" text-align="center" font-weight="bold" color="red"
			border-color="gray" border-style="groove" border-width="medium" padding="2mm"> This
			document contains unpublished, internal-only information. Do not disseminate.
		</fo:block>
	</xsl:template>

	<xsl:template name="toc_unitid-title-date">
		<xsl:if test="ead:did/ead:unitid[not(@audience='internal')]">
			<xsl:if test="@level = 'series'">
				<xsl:value-of select="local:capitalize-first-word(@level)"/>
				<xsl:text> </xsl:text>
			</xsl:if>
			<xsl:if test="@level = 'subseries'">
				<xsl:value-of select="local:capitalize-first-word(@level)"/>
				<xsl:text> </xsl:text>
			</xsl:if>
			<xsl:value-of select="replace(ead:did/ead:unitid[not(@audience='internal')][1],
				local:uppercase-first-word(@level),'')"/>
			<xsl:text>: </xsl:text>
		</xsl:if>
		
		<!-- Add Title -->
		<xsl:apply-templates select="ead:did/ead:unittitle" mode="step2_pdf"/>
		
		
		<xsl:if test="ead:did/ead:unitdate">
			<xsl:text>, </xsl:text>
			<!-- Add the inclusive dates first -->
			<xsl:apply-templates select="ead:did/ead:unitdate[not(contains(., 'undated'))][not(@type='bulk')]" mode="step2_pdf"/>
			<!-- Separator for undated -->
			<xsl:if test="ead:did/ead:unitdate[preceding-sibling::ead:unitdate][(contains(., 'undated'))] or ead:did/ead:unitdate[following-sibling::ead:unitdate][(contains(., 'undated'))]">
				<xsl:text>, </xsl:text>
			</xsl:if>
			<!-- Add any undated -->
			<xsl:apply-templates select="ead:did/ead:unitdate[(contains(., 'undated'))]" mode="step2_pdf"/>
			<!-- Add bulk dates last -->
			<xsl:apply-templates select="ead:did/ead:unitdate[@type = 'bulk']" mode="step2_pdf"/> 
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="dscSection_unitid">
		<xsl:if test="ead:did/ead:unitid[not(@audience='internal')]">
			
			<xsl:if test="@level = 'series'">
				<xsl:value-of select="local:capitalize-first-word(@level)"/>
				<xsl:text> </xsl:text>
			</xsl:if>
			
			<xsl:if test="@level = 'subseries'">
				<xsl:value-of select="local:capitalize-first-word(@level)"/>
				<xsl:text> </xsl:text>
			</xsl:if>
			
			<xsl:value-of select="replace(ead:did/ead:unitid[not(@audience='internal')][1],
				local:uppercase-first-word(@level),'')"/>
			<xsl:text>: </xsl:text>
		</xsl:if>
	</xsl:template>
	
	
	
	<!--This template creates a table for the Overview, inserts the head and then
		each of the other did and collection-level dao elements. -->
	<xsl:template mode="step2_pdf" match="ead:archdesc/ead:did" name="collectionOverview">
		<fo:table table-layout="fixed" width="100%"> <!-- width="166mm" -->
			<fo:table-column column-width="20%"/>
			<fo:table-column column-width="80%" padding-left="5pt"/>
			
			<fo:table-body>
				<fo:table-row>
					<fo:table-cell number-columns-spanned="2">
						<fo:block xsl:use-attribute-sets="h3" font-weight="bold" id="{generate-id(.)}">
							<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
							<xsl:text>Collection Overview</xsl:text>
						</fo:block>
					</fo:table-cell>
				</fo:table-row>

				<!--create a table row for each note type, force repo to display 1st, and dao to display last-->
				<xsl:for-each-group select="ead:repository" group-by="name()">
					<xsl:sort select="current-grouping-key()"/>
						<fo:table-row>	
							<xsl:call-template name="collectionOverviewTable"/>
						</fo:table-row>	
				</xsl:for-each-group>
				
				<xsl:for-each-group select="ead:unittitle" group-by="name()">
					<fo:table-row>	
						<xsl:call-template name="collectionOverviewTable"/>
					</fo:table-row>	
				</xsl:for-each-group>
				
				<xsl:for-each-group select="ead:unitdate" group-by="name()">
					<fo:table-row>	
						<xsl:call-template name="collectionOverviewTable"/>
					</fo:table-row>	
				</xsl:for-each-group>
				
				<xsl:for-each-group select="ead:unitid[not(@audience='internal')]" group-by="name()">
					<fo:table-row>	
						<xsl:call-template name="collectionOverviewTable"/>
					</fo:table-row>	
				</xsl:for-each-group>
				
				<xsl:for-each-group select="ead:origination" group-by="@label">
					<fo:table-row>	
						<xsl:call-template name="collectionOverviewTable"/>
					</fo:table-row>	
				</xsl:for-each-group>
				
				<xsl:for-each-group select="ead:physdesc | ead:physloc | ead:materialspec 
					| ead:langmaterial | ead:abstract" group-by="name()">
					<xsl:sort select="current-grouping-key()" order="descending"/>
					<fo:table-row>	
						<xsl:call-template name="collectionOverviewTable"/>
					</fo:table-row>	
				</xsl:for-each-group>
				
				<xsl:for-each-group select="ead:dao[not(lower-case(@*:role) = 'representative-image')]
					| following-sibling::ead:dao[not(lower-case(@*:role) = 'representative-image')]" 
					group-by="name()">
					<xsl:sort select="current-grouping-key()" order="descending"/>
					<fo:table-row>	
						<xsl:call-template name="collectionOverviewTable"/>
					</fo:table-row>	
					
				</xsl:for-each-group>
				
				<xsl:for-each-group select="ead:container" group-by="@id|@parent">
					<fo:table-row>	
						<xsl:call-template name="collectionOverviewTable"/>
					</fo:table-row>	
					
				</xsl:for-each-group>
				
			
			</fo:table-body>
	
		</fo:table>
	</xsl:template>
	
	<xsl:template name="collectionOverviewTable">
		<fo:table-cell display-align="before" padding-bottom="5pt" padding-top="5pt">
			<fo:block text-indent="-0pt" start-indent="25pt"  font-size="10pt">
				<fo:inline font-weight="bold">
					<xsl:choose>
						<xsl:when test="self::ead:origination">
							<xsl:value-of select="local:capitalize-first-word(@label)"/><xsl:text>: </xsl:text>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="local:capitalize-first-word(local:tagName(.))"/><xsl:text>: </xsl:text> 
						</xsl:otherwise>
					</xsl:choose>
				</fo:inline>
			</fo:block>
		</fo:table-cell>
		
		<fo:table-cell display-align="before" 
			padding-bottom="5pt"  padding-top="5pt">
			<xsl:for-each select="current-group()">
				<fo:block margin-left="60pt" font-size="10pt">
					<xsl:apply-templates mode="step2_pdf" select=".[not(self::ead:container or self::ead:langmaterial)]"/>
					
					<xsl:if test="self::ead:origination/*[@role]">
						<xsl:value-of select="concat(' (',local:tagName(.), ')')"/>
					</xsl:if>
					
					<xsl:if test="matches(current-grouping-key(),'dao')">
						<xsl:call-template name="digital_content"/>
					</xsl:if>
					
					<!-- i'm not accustomed to this approach yet, but mimicking it for now -->
					<!-- removed this bit, since we are not going to permit daogrp link pairs at the collection level.
					<xsl:if test="matches(current-grouping-key(),'daogrp')">
						<xsl:call-template name="daogrp_content"/>
					</xsl:if>
					-->
					
					<xsl:if test="matches(name(),'container')">
						<xsl:call-template name="container_details"/>
					</xsl:if>

					<xsl:if test="matches(name(),'langmaterial')">
						<xsl:call-template name="langmaterial"/>
					</xsl:if>
					
				</fo:block>
			</xsl:for-each>
		</fo:table-cell>
	</xsl:template>
	


	<!--This template formats the top-level controlaccess element.
	It begins by testing to see if there is any controlled access element with content. 
	It then invokes one of two templates for the children of controlaccess.  -->	
	<xsl:template match="ead:archdesc/ead:controlaccess[normalize-space()]" mode="step2_pdf">
		<fo:block  xsl:use-attribute-sets="h3" id="{generate-id(.)}">
			<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
			<xsl:text>Names and Subject Terms</xsl:text>
		</fo:block>
		<fo:block xsl:use-attribute-sets="normal-text-size">
			<xsl:text>This collection is indexed in the online catalog of the Smithsonian Institution under the following terms:</xsl:text>
		</fo:block>

		<xsl:if test="ead:subject[not(matches(@altrender,'culture'))] or ead:subject[not(matches(@altrender,'cultural'))]">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Subjects:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:subject[not(matches(@altrender,'culture'))] | ead:subject[not(matches(@altrender,'cultural'))]">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
		<xsl:if test="ead:subject[matches(@altrender,'culture')] or ead:subject[matches(@altrender,'cultural')]">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Cultures:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:subject[matches(@altrender,'culture')] | ead:subject[matches(@altrender,'cultural')]">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:genreform">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Types of Materials:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:genreform">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:corpname or ead:famname or ead:persname or ead:name">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Names:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:corpname | ead:famname | ead:persname | ead:name">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:occupation">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Occupations:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:occupation">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:function">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Functions:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:function">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:geogname">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Places:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:geogname">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:title">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Preferred Titles:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:title">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>

			<xsl:if test="ead:controlaccess/ead:subject[not(matches(@altrender,'culture'))] or ead:controlaccess/ead:subject[not(matches(@altrender,'cultural'))]">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Subjects:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:controlaccess/ead:subject[not(matches(@altrender,'culture'))] | ead:controlaccess/ead:subject[not(matches(@altrender,'cultural'))]">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:controlaccess/ead:subject[matches(@altrender,'culture')] or ead:controlaccess/ead:subject[matches(@altrender,'cultural')]">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Cultures:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:controlaccess/ead:subject[matches(@altrender,'culture')] | ead:controlaccess/ead:subject[matches(@altrender,'cultural')]">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:controlaccess/ead:genreform">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Types of Materials:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:controlaccess/ead:genreform">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:controlaccess/ead:corpname or ead:controlaccess/ead:famname or ead:controlaccess/ead:persname or ead:controlaccess/ead:name">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Names:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each
						select="ead:controlaccess/ead:corpname | ead:controlaccess/ead:famname | ead:controlaccess/ead:persname | ead:controlaccess/ead:name">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:controlaccess/ead:occupation">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Occupations:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:occupation">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:controlaccess/ead:function">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Functions:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:controlaccess/ead:function">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:controlaccess/ead:geogname">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Places:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:controlaccess/ead:geogname">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
			<xsl:if test="ead:controlaccess/ead:title">
				<fo:block xsl:use-attribute-sets="h5">
					<xsl:text>Preferred Titles:</xsl:text>
				</fo:block>
				<fo:list-block xsl:use-attribute-sets="list">
					<xsl:for-each select="ead:controlaccess/ead:title">
						<xsl:sort select="." data-type="text" order="ascending"/>
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:apply-templates select="." mode="step2_pdf"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:for-each>
				</fo:list-block>
			</xsl:if>
		
	</xsl:template>
	
	<!-- Administrative Information -->
	<xsl:template match="ead:archdesc/ead:acqinfo | ead:archdesc/ead:custodhist |
		ead:archdesc/ead:separatedmaterial | ead:archdesc/ead:originalsloc | ead:archdesc/ead:relatedmaterial | ead:archdesc/ead:otherfindaid |
		ead:archdesc/ead:altformavail | ead:archdesc/ead:processinfo |
		ead:archdesc/ead:prefercite | ead:archdesc/ead:accessrestrict |
		ead:archdesc/ead:userestrict | ead:archdesc/ead:appraisal |
		ead:archdesc/ead:accruals " mode="step2_pdf">
		<fo:block margin-left="25pt" xsl:use-attribute-sets="h4" id="{@id}">
			<fo:inline> <xsl:value-of select="local:tagName(.)"/> </fo:inline>
		</fo:block>
		<fo:block>
			<xsl:attribute name="font-size">10pt</xsl:attribute>
			<xsl:attribute name="margin-left">50pt</xsl:attribute>
			<xsl:attribute name="space-before">5pt</xsl:attribute>
			<xsl:attribute name="space-after">5pt</xsl:attribute>
			<!-- <xsl:attribute name="keep-together.within-page">always</xsl:attribute> -->
			<xsl:apply-templates select="*[not(self::ead:head)]" mode="step2_pdf"/>
		</fo:block>
	</xsl:template>

	<!-- Descriptive notes (non-administrative information) -->
	<xsl:template match="ead:archdesc/ead:bibliography | ead:archdesc/ead:phystech" mode="step2_pdf" >
		<fo:block xsl:use-attribute-sets="h3" id="{@id}">
			<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
			<fo:inline>
				<xsl:apply-templates select="ead:head" mode="step2_pdf"/>
			</fo:inline>
		</fo:block>
		<fo:block font-size="10pt">
			<xsl:apply-templates select="*[not(self::ead:head)]" mode="step2_pdf"/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ead:archdesc/ead:arrangement | ead:archdesc/ead:bioghist | ead:archdesc/ead:scopecontent" mode="step2_pdf">
		<fo:block xsl:use-attribute-sets="h3" id="{@id}" font-weight="bold">
			<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
			<xsl:value-of select="local:tagName(.)"/>
			<!-- check header  -->
		</fo:block>
		<fo:block font-size="10pt">
			<xsl:apply-templates select="*[not(self::ead:head)]" mode="step2_pdf"/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ead:archdesc/ead:odd" mode="step2_pdf">
		<fo:block xsl:use-attribute-sets="h3" id="{@id}">			
			<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
			<xsl:apply-templates select="local:tagName(.)" mode="step2_pdf"/>
		</fo:block>
		<fo:block font-size="10pt">
			<xsl:apply-templates select="*[not(self::ead:head)]" mode="step2_pdf"/>
		</fo:block>
	</xsl:template>
	
	<xsl:template match="ead:archdesc/ead:note" mode="step2_pdf">
		<fo:block xsl:use-attribute-sets="h3" id="{@id}">
			<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
			<xsl:apply-templates select="local:tagName(.)" mode="step2_pdf"/>
		</fo:block>
		<fo:block font-size="10pt">
			<xsl:apply-templates select="*[not(self::ead:head)]" mode="step2_pdf"/>
		</fo:block>
	</xsl:template>

	<!-- Formats collection level index and child elements; could consider grouping indexentry elements by type (i.e. corpname, subject...) -->
	<xsl:template match="ead:archdesc/ead:index" mode="step2_pdf">
		<fo:block xsl:use-attribute-sets="h3" id="{@id}">
			<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
			<xsl:apply-templates select="ead:head" mode="step2_pdf"/>
		</fo:block>
		<fo:block xsl:use-attribute-sets="paragraph" font-size="10pt">
			<xsl:apply-templates select="ead:p" mode="step2_pdf"/>
		</fo:block>

		<xsl:for-each select="ead:indexentry">
			<xsl:choose>
				<xsl:when test="./ead:ref">
					<fo:block font-size="10pt" space-before="5pt" space-after="5pt"
						margin-left="30pt" text-align="left" text-align-last="justify"
						text-indent="-10pt">

						<xsl:apply-templates select="./*[1]" mode="step2_pdf"/>
						<fo:leader leader-pattern="dots"/>
						<fo:inline keep-together.within-line="always">
							<xsl:apply-templates select="./ead:ref" mode="step2_pdf"/>
						</fo:inline>
					</fo:block>
				</xsl:when>

				<xsl:otherwise>
					<fo:block font-size="10pt" space-before="5pt" space-after="5pt"
						margin-left="30pt" text-indent="-10pt">
						<xsl:apply-templates select="./*[1]" mode="step2_pdf"/>
					</fo:block>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<!--</fo:list-block>-->

	</xsl:template>

	<!-- Formats dsc level index and child elements; -->
	<!-- could consider grouping indexentry elements by type (i.e. corpname, subject...) -->
	<xsl:template mode="step2_pdf" match="ead:c/ead:index">
		<fo:block xsl:use-attribute-sets="h3" id="{ead:c/ead:index/@id}">
			<xsl:apply-templates select="ead:head" mode="step2_pdf"/>
		</fo:block>
		<fo:block xsl:use-attribute-sets="paragraph" font-size="10pt">
			<xsl:apply-templates select="ead:p" mode="step2_pdf"/>
		</fo:block>

		<xsl:for-each select="ead:indexentry">
			<xsl:choose>
				<xsl:when test="./ead:ref">
					<fo:block font-size="10pt" space-before="5pt" space-after="5pt"
						margin-left="30pt" text-align="justify" text-align-last="justify"
						text-indent="-10pt">

						<xsl:apply-templates select="./*[1]" mode="step2_pdf"/>
						<fo:leader leader-pattern="dots"/>
						<fo:inline keep-together.within-line="always">
							<xsl:apply-templates select="./ead:ref" mode="step2_pdf"/>
						</fo:inline>
					</fo:block>
				</xsl:when>

				<xsl:otherwise>
					<fo:block font-size="10pt" space-before="5pt" space-after="5pt"
						margin-left="30pt" text-indent="-10pt">
						<xsl:apply-templates select="./*[1]" mode="step2_pdf"/>
					</fo:block>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>

	</xsl:template>


	
	<!-- Container listing -->
	<xsl:template mode="step2_pdf" match="ead:dsc">
		<fo:block id="{generate-id()}" page-break-before="always" xsl:use-attribute-sets="h3" font-weight="bold">
			<xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
			<xsl:text>Container Listing</xsl:text>
		</fo:block>
		<xsl:call-template name="dscRouter_sectionVtable"/>
	</xsl:template>
	
	<!-- build the container listing (ead:dsc) -->
	<xsl:template name="dscRouter_sectionVtable">
		
		<!-- current node can = DSC or any c-level -->
		<xsl:param name="seriesIndentLevel" select="0" as="xs:double"/>
		<xsl:param name="indentLevel" select="0" as="xs:double"/>
		<xsl:variable name="seriesIndentStyle">
			<xsl:value-of select="number($seriesIndentLevel) * 5"/>
			<xsl:text>pt</xsl:text>
		</xsl:variable>
		
		<xsl:for-each select="ead:c">			
			
			<xsl:choose>
				<!-- for the series, subseries and subgroup, no columns -->
				<xsl:when test="self::*[@level='series'] or self::*[@level='subseries'] or self::*[@level='subgrp']">
					
					<fo:block padding-after="2mm" font-size="10pt" space-after="6pt">
						<xsl:if test="@level='subseries'">
							<xsl:attribute name="border-bottom-style">dotted</xsl:attribute>
							<xsl:attribute name="border-color">grey</xsl:attribute>
							<xsl:attribute name="border-width">small</xsl:attribute>
						</xsl:if>
						
						<!-- heading for series and subgrps-->
						<xsl:if test="@level='series' or @level='subgrp'">
							<fo:marker marker-class-name="Series-Level1">
								<xsl:call-template name="dscSection_unitid"/>
								<xsl:apply-templates select="ead:did/ead:unittitle" mode="step2_pdf"/>
							</fo:marker>
							
							<fo:block xsl:use-attribute-sets="h3" id="{@id}">
								<!--  test to ensure a page break isn't started for the 1st series/subgrp within the DSC-->
								<!-- also... only break before if the previous has components? -->
								<xsl:if test="not(position() = 1)"> <!--preceding-sibling::ead:c[1]-->
									<xsl:attribute name="page-break-before">always</xsl:attribute>
								</xsl:if>
								<xsl:apply-templates select="ead:did/ead:head" mode="step2_pdf"/>
								
								<xsl:call-template name="dscSection_unitid"/>
								<xsl:call-template name="combine-that-title-and-date"/>
							</fo:block>
						</xsl:if>
						
						<!-- heading subseries section -->
						<xsl:if test="@level='subseries'">
							<fo:block space-before="5mm" space-after="2mm" id="{@id}"
								xsl:use-attribute-sets="h4">
								<xsl:apply-templates select="ead:did/ead:head" mode="step2_pdf"/>
								<xsl:call-template name="dscSection_unitid"/>
								<xsl:call-template name="combine-that-title-and-date"/>
							</fo:block>
						</xsl:if>
						
						<!-- phys desc -->
						<xsl:for-each select="ead:did/ead:physdesc | ead:did/ead:materialspec">
							<fo:block font-style="italic" keep-with-next.within-page="always" space-after="5pt">
								<xsl:apply-templates mode="step2_pdf"/>
							</fo:block>
						</xsl:for-each>
						
						<xsl:for-each-group select="ead:did/ead:container" group-by="@id|@parent">
							<fo:block font-style="italic" keep-with-next.within-page="always">									
								<xsl:for-each select="current-group()">
									<xsl:value-of select="concat(@type,' ',normalize-space(.))"/>
									<xsl:if test="position() != last()">
										<xsl:text>, </xsl:text>
									</xsl:if>
								</xsl:for-each>
								
								<xsl:if test="lower-case(@label) ne 'mixed materials' and last() gt 1">
									<xsl:value-of select="concat(' (', lower-case(@label), ')')"/>
								</xsl:if>

							</fo:block>
						</xsl:for-each-group>
							
						<!-- phys location -->
						<xsl:for-each select="ead:did/ead:physloc">
							<fo:block font-style="italic" keep-with-next.within-page="always">
								<xsl:apply-templates mode="step2_pdf"/>
							</fo:block>
						</xsl:for-each>
						
						<xsl:for-each-group select="ead:did/ead:dao[not(@*:role = 'Representative-Image')] | ead:dao[not(@*:role = 'Representative-Image')]" group-by="@*:role">
							<fo:block keep-with-next.within-page="always">
								<xsl:for-each select="current-group()">
									<xsl:call-template name="digital_content"/>
								</xsl:for-each>
							</fo:block>
						</xsl:for-each-group>
						
						<xsl:for-each-group select="ead:did/ead:daogrp" group-by="local-name()">
							<fo:block keep-with-next.within-page="always">
								<xsl:for-each select="current-group()">
									<xsl:call-template name="daogrp_content"/>
								</xsl:for-each>
							</fo:block>
						</xsl:for-each-group>
						
						<xsl:for-each-group select="ead:did/ead:origination" 
							group-by="local:tagName(.)">
							<xsl:call-template name="details_list">
								<xsl:with-param name="indent" select="$seriesIndentStyle"/>
							</xsl:call-template>
						</xsl:for-each-group>
							
						<!-- Notes: series, subseries, subgroups: display order controlled by the apply-templates -->
						
						<xsl:for-each-group select="ead:did/ead:abstract | ead:did/ead:langmaterial |ead:note" 
							group-by="local:tagName(.)">
							<xsl:call-template name="details_list">
								<xsl:with-param name="indent" select="$seriesIndentStyle"/>
							</xsl:call-template>
						</xsl:for-each-group>
						
						<!-- other notes, labeled -->
						<xsl:for-each-group select="ead:scopecontent | ead:bioghist|  ead:arrangement| 
							ead:acqinfo| ead:custodhist| ead:appraisal| ead:accruals| 
							ead:separatedmaterial| ead:relatedmaterial| ead:otherfindaid| ead:altformavail| ead:originalsloc| 
							ead:processinfo| ead:prefercite| ead:accessrestrict| ead:userestrict| 
							ead:fileplan| ead:phystech| ead:odd | ead:bibliography" 
							group-by="local:tagName(.)"> 
							<xsl:call-template name="details_list">
								<xsl:with-param name="indent" select="$seriesIndentStyle"/>
							</xsl:call-template>
						</xsl:for-each-group>
						
						<!-- use pipe stems to follow document order. use comma separated list to set the order here instead -->
						<!--<xsl:for-each select="ead:bioghist| ead:scopecontent| ead:arrangement| 
							ead:acqinfo| ead:custodhist| ead:appraisal| ead:accruals| 
							ead:separatedmaterial| ead:relatedmaterial| ead:otherfindaid| ead:altformavail| ead:originalsloc| 
							ead:processinfo| ead:prefercite| ead:accessrestrict| ead:userestrict| 
							ead:fileplan| ead:phystech| ead:odd| ead:note| ead:bibliography">
							<fo:block space-before="5pt">
								<xsl:apply-templates mode="step2_pdf">
									<xsl:with-param name="level" select="'dsc-level'" tunnel="yes"/>
								</xsl:apply-templates>
							</fo:block>
						</xsl:for-each>-->
						
						<!-- access points details - summary list -->
						<xsl:if test="ead:controlaccess">								
							<xsl:for-each-group select="ead:controlaccess/ead:persname | ead:controlaccess/ead:corpname | ead:controlaccess/ead:famname | ead:controlaccess/ead:name" 
										group-by="local:tagName(.)">
								<xsl:call-template name="details_list">
									<xsl:with-param name="indent" select="$seriesIndentStyle"/>
								</xsl:call-template>
							</xsl:for-each-group>
							<xsl:for-each-group select="ead:controlaccess/ead:geogname | ead:controlaccess/*[not(matches(name(),'name'))]" 
										group-by="local:tagName(.)">
								<xsl:call-template name="details_list">
									<xsl:with-param name="indent" select="$seriesIndentStyle"/>
								</xsl:call-template>
							</xsl:for-each-group>
						</xsl:if>
						
						
						<!-- Group & Next levels: call template again to go through the next level of components -->
						<xsl:if test="ead:c">
							<!--<fo:block space-after="6pt"/> -->
							<xsl:call-template name="dscRouter_sectionVtable">
								<xsl:with-param name="seriesIndentLevel" select="$seriesIndentLevel + 1"/>
							</xsl:call-template>
						</xsl:if>
						
						<!-- should an index appear at the end of the component .. or back-of-volume .. with a link directing users to the index?-->
						<!-- dsc-level index appears after the containers for that component -->
						<xsl:apply-templates select="ead:index" mode="step2_pdf">
							<xsl:with-param name="level" select="'dsc-level'" tunnel="yes"/>
						</xsl:apply-templates>
						
						<!-- 'return to tc' if end of top c, level series or subgrp-->
						<xsl:if test="self::ead:c[parent::ead:dsc]">
							<xsl:call-template name="return-toc"/>
								
							
						</xsl:if>
						
					</fo:block>
				</xsl:when>
				
				<!-- everything else gets a table layout -->
				<xsl:otherwise>
					<xsl:call-template name="dscRouter_table">
						<xsl:with-param name="indentLevel" select="$indentLevel"/>
					</xsl:call-template>
					
					<xsl:if test="ead:c">
						<xsl:call-template name="dscRouter_sectionVtable">
							<xsl:with-param name="indentLevel" select="$indentLevel + 1"/>
						</xsl:call-template>
					</xsl:if>
					
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="dscRouter_table">
		<xsl:param name="indentLevel" as="xs:double"/>
		<fo:table table-layout="fixed" width="100%" space-before="3pt" >
			<fo:table-column column-width="23%"/>
			<fo:table-column column-width="1%"/>
			<fo:table-column column-width="76%"/>

			<fo:table-body font-size="10pt" border-separation="3pt" >
				<!-- This once had a margin-bottom , and a keep-together value, but this led to really bad output -->
				
				<fo:table-row>
					<xsl:variable name="indentStyle" 
						select="concat(number($indentLevel) * 10, 'pt')"/>

					<!-- banding -->
					<xsl:variable name="absolute-c-count"> <xsl:number count="ead:c" level="any"/> </xsl:variable>
						<xsl:if test="$absolute-c-count mod 2">
									<xsl:attribute name="background-color" select="'#ecf1f7'"/><!-- warm blue -->
										<!-- #EEF0F2 light grey blue -->
								</xsl:if>

					<!-- container column-->
					<fo:table-cell padding="2mm">
						<xsl:choose>
							<xsl:when test="ead:did/ead:container">
								<fo:list-block provisional-distance-between-starts="2mm"
									provisional-label-separation="2mm">
									
									<xsl:for-each-group select="ead:did/ead:container" group-by="@id | @parent">
										<fo:list-item space-after="2mm">
											<fo:list-item-label end-indent="label-end()">
												<fo:block/>
											</fo:list-item-label>
											<fo:list-item-body start-indent="body-start()">
												<fo:block>
												<xsl:call-template name="container_details"/>
												</fo:block>
											</fo:list-item-body>
										</fo:list-item>
									</xsl:for-each-group>
								</fo:list-block>
							</xsl:when>
							<xsl:otherwise>
								<fo:block/>
							</xsl:otherwise>
						</xsl:choose>

					</fo:table-cell>

					<!-- could have 3 columns, with dates ... -->
					<fo:table-cell>
						<fo:block/>
					</fo:table-cell>

					<!-- description column -->
					<fo:table-cell padding="2mm">
						<fo:block-container margin-left="{$indentStyle}">
							<!-- Displays the title, with date, and physical description with proper indents -->

							<xsl:variable name="title-and-date">
								<xsl:call-template name="combine-that-title-and-date"/>
							</xsl:variable>
							<xsl:variable name="title" select="ead:did/ead:unittitle"/>

							<fo:block id="{@id}">
								<xsl:call-template name="dscSection_unitid"/>

								<!-- <xsl:call-template name="combine-that-title-and-date"/> -->
								<xsl:choose>
									<xsl:when test="ead:did/ead:dao[2] or ead:dao[2] or ead:did/ead:daogrp[2]">
										<xsl:value-of select="$title-and-date"/>
									</xsl:when>
									<xsl:when
										test="
											ead:did/ead:dao[normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title, '.,:;[]', ' '))]
											or ead:did/ead:dao[normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title-and-date, '.,:;[]', ' '))]
											or ead:dao[normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title, '.,:;[]', ' '))]
											or ead:dao[normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title-and-date, '.,:;[]', ' '))]
											">
										<fo:inline xsl:use-attribute-sets="link">
											<fo:basic-link
												external-destination="url('{ead:did/ead:dao[1]/@*:href}')">
												<xsl:value-of select="$title-and-date"/>
											</fo:basic-link>
										</fo:inline>
									</xsl:when>
									<!-- oh geez -->
									<xsl:when
										test="
										ead:did/ead:daogrp[normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title, '.,:;[]', ' '))]
										or ead:did/ead:daogrp[normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title-and-date, '.,:;[]', ' '))]
										">
										<fo:inline xsl:use-attribute-sets="link">
											<fo:basic-link external-destination="url('{ead:did/ead:daogrp[1]/ead:daoloc[@xlink:role eq 'web-resource-link'][1]/@xlink:href}')">
												<xsl:value-of select="$title-and-date"/>
											</fo:basic-link>
										</fo:inline>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$title-and-date"/>
									</xsl:otherwise>
								</xsl:choose>
							</fo:block>

							<!-- phys desc -->
							<xsl:for-each select="ead:did/ead:physdesc | ead:did/ead:materialspec">
								<fo:block keep-with-next.within-page="always">
									<xsl:apply-templates mode="step2_pdf"/>
								</fo:block>
							</xsl:for-each>

							<!-- phys location -->
							<xsl:for-each select="ead:did/ead:physloc">
								<fo:block xsl:use-attribute-sets="normal-text-size">
									<xsl:attribute name="keep-with-next.within-page"
										>always</xsl:attribute>
									<xsl:apply-templates mode="step2_pdf"/>
								</fo:block>
							</xsl:for-each>

							<xsl:if test="ead:dao or ead:did/ead:dao">
								<xsl:choose>
									<!-- multiple dao -->
									<xsl:when test="ead:did/ead:dao[2] or ead:dao[2]">
										<xsl:for-each-group
											select="
												ead:did/ead:dao[not(@*:role = 'Representative-Image')]
												| ead:dao[not(@*:role = 'Representative-Image')]"
											group-by="string(@*:role)">
											<!-- NCK: need group-by to include a group for null 'role'. 
												The simplest solution is to use string() in the group-by attribute,
												otherwise when dao does not have @role would have no grouping key 
												 -->
											<fo:block>
												<xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
												<xsl:for-each select="current-group()">
													<xsl:call-template name="digital_content"/>
												</xsl:for-each>
											</fo:block>
										</xsl:for-each-group>
									</xsl:when>

									<xsl:otherwise>
										<!-- single dao -->
										<xsl:for-each select="ead:did/ead:dao | ead:dao">
											<fo:block xsl:use-attribute-sets="link">
												<fo:basic-link external-destination="url('{@*:href}')">
												<xsl:if test="
															not(normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title, '.,:;[]', ' '))
															or normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title-and-date, '.,:;[]', ' ')))">
												<xsl:call-template name="digital_content_type"/>
												<xsl:text>: </xsl:text>
												<xsl:value-of
												select="ead:daodesc/ead:p/normalize-space()"/>
												</xsl:if>
												</fo:basic-link>
											</fo:block>

										</xsl:for-each>
									</xsl:otherwise>
									<!-- single dao, matches unittitle -->
								</xsl:choose>
								<!-- single dao, matches unittitle, cleaned -->
								<!--<xsl:when test="ead:dao[normalize-space(translate(ead:daodesc/ead:p,'.,:;[]',' ')) = normalize-space(translate($title,'.,:;[]',' '))]"/>																									
												<xsl:when test="ead:dao[normalize-space(translate(ead:daodesc/ead:p,'.,:;[]',' ')) = normalize-space(translate($title-and-date,'.,:;[]',' '))]"/>
												<xsl:when test="ead:did/ead:dao[normalize-space(translate(ead:daodesc/ead:p,'.,:;[]',' ')) = normalize-space(translate($title,'.,:;[]',' '))]"/>
												<xsl:when test="ead:did/ead:dao[normalize-space(translate(ead:daodesc/ead:p,'.,:;[]',' ')) = normalize-space(translate($title-and-date,'.,:;[]',' '))]"/>
												-->
								<!-- single dao, not matches unittitle -->
							</xsl:if>
							
							<!-- oh, geez -->
							<xsl:if test="ead:did/ead:daogrp">
								<!-- there's a better way to do this, but following the previous patterns for now-->
								<xsl:choose>
									<xsl:when test="ead:did/ead:daogrp[2]">
										<xsl:for-each-group
											select="ead:did/ead:daogrp" group-by="local-name()">
											<fo:block>
												<xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
												<xsl:for-each select="current-group()">
													<xsl:call-template name="daogrp_content"/>
												</xsl:for-each>
											</fo:block>
										</xsl:for-each-group>
									</xsl:when>
									<!-- single daogrp -->
									<xsl:otherwise>
										<xsl:for-each select="ead:did/ead:daogrp">
											<fo:block xsl:use-attribute-sets="link">
												<fo:basic-link
													external-destination="url('{ead:daoloc[@xlink:role eq 'web-resource-link']/@xlink:href}')">
													<xsl:if
														test="
														not(normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title, '.,:;[]', ' '))
														or normalize-space(translate(ead:daodesc/ead:p, '.,:;[]', ' ')) = normalize-space(translate($title-and-date, '.,:;[]', ' ')))">
														<xsl:text>Digital Content: </xsl:text>
														<xsl:value-of
															select="ead:daodesc/ead:p/normalize-space()"/>
													</xsl:if>
												</fo:basic-link>
											</fo:block>
										</xsl:for-each>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:if>

							<xsl:for-each select="ead:did/ead:abstract">
								<fo:block xsl:use-attribute-sets="normal-text-size" keep-with-next.within-page="always">
									<xsl:apply-templates mode="step2_pdf"/>
								</fo:block>
							</xsl:for-each>

							<xsl:if test="child::*[not(self::ead:did)][not(self::ead:c)][not(self::ead:dao)][not(self::ead:daogrp)]
									or ead:did/child::*[not(self::ead:container or self::ead:dao or self::daogrp
									or self::ead:unittitle or self::ead:unitdate or self::ead:unitid
									or self::ead:physdesc or self::ead:physloc or self::ead:materialspec)]">

								<fo:block space-after="2mm">
									<!--block container?   if want a box around, for item level?
													 padding="2mm 2mm 2mm 0"
													border-width="small" border-color="grey" border-style="dotted" -->

									<xsl:for-each-group select="ead:did/*[not(self::ead:container or self::ead:dao or self::ead:daogrp
											or self::ead:unittitle or self::ead:unitdate or self::ead:unitid
											or self::ead:physdesc or self::ead:physloc)]"
										group-by="local:tagName(.)">
										<xsl:call-template name="details_list">
											<xsl:with-param name="indent" select="$indentStyle"/>
										</xsl:call-template>
									</xsl:for-each-group>

									<!--generic Notes-->
									<xsl:for-each-group select="ead:*[not(self::ead:did or self::ead:c or self::ead:controlaccess)]"
										group-by="parent::*">
										<xsl:call-template name="details_list">
											<xsl:with-param name="indent" select="$indentStyle"/>
											<xsl:with-param name="label">Notes: </xsl:with-param>
										</xsl:call-template>
									</xsl:for-each-group>

									<!--<xsl:for-each-group select="ead:*[not(self::ead:did or ead:scopecontent or self::ead:c or self::ead:controlaccess)]" 
														group-by="local:tagName(.)">
														<xsl:call-template name="dsc_list"/>
													</xsl:for-each-group>-->

									<xsl:for-each-group
										select="ead:controlaccess/ead:persname | ead:controlaccess/ead:corpname | ead:controlaccess/ead:famname | ead:controlaccess/ead:name"
										group-by="local:tagName(.)">
										
										<xsl:call-template name="details_list">
											<xsl:with-param name="indent" select="$indentStyle"/>
										</xsl:call-template>
									</xsl:for-each-group>

									<xsl:for-each-group
										select="ead:controlaccess/ead:geogname | ead:controlaccess/*[not(matches(name(), 'name'))]"
										group-by="local:tagName(.)">
										<xsl:call-template name="details_list">
											<xsl:with-param name="indent" select="$indentStyle"/>
										</xsl:call-template>
									</xsl:for-each-group>
								</fo:block>
							</xsl:if>
						</fo:block-container>

					</fo:table-cell>

				</fo:table-row>
			</fo:table-body>
		</fo:table>
	</xsl:template>
	
	
	
	<xsl:template name="details_list">
		<xsl:param name="label"/>
		<xsl:param name="indent"/>
		
		<fo:list-block display-align="before" 
			provisional-distance-between-starts="25mm"
			provisional-label-separation="1.5mm">
    		<xsl:for-each select="current-group()">		
				<xsl:choose>
					<xsl:when test="matches(../name(),'did')">
						<!-- <fo:list-item start-indent="10pt">-->
						<fo:list-item start-indent="{$indent}">	
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:call-template name="details_list_label">
										<xsl:with-param name="label" select="$label"/>
									</xsl:call-template>
								</fo:block>
							</fo:list-item-label>							
							<fo:list-item-body start-indent="body-start()">
								<fo:block><xsl:apply-templates mode="step2_pdf"/></fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:when>
					
					<xsl:when test="matches(current-grouping-key(),'dao')">
						<fo:list-item start-indent="{$indent}">	
							<fo:list-item-label end-indent="label-end()">
								<fo:block/>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<xsl:for-each select="current-group()">
									<xsl:call-template name="digital_content"/>
								</xsl:for-each>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:when>
					
					<xsl:when test="matches(../name(),'controlaccess')">
						<fo:list-item start-indent="{$indent}">	
							<fo:list-item-label end-indent="label-end()">
								<xsl:call-template name="details_list_label">
									<xsl:with-param name="label" select="$label"/>
								</xsl:call-template>
								
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block><xsl:apply-templates mode="step2_pdf"/></fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:when>
											
					<xsl:otherwise>
						<fo:list-item start-indent="{$indent}" space-after="3pt" >	
							<!--<fo:list-item start-indent="0pt" space-after="3pt" >-->
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:call-template name="details_list_label">
										<xsl:with-param name="label" select="$label"/>
									</xsl:call-template>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<xsl:apply-templates mode="step2_pdf"/>
							</fo:list-item-body>
						</fo:list-item>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
					
		</fo:list-block>
	</xsl:template>
	
	<xsl:template name="details_list_label">
		<xsl:param name="label"/>
		<xsl:choose>
			<xsl:when test="position() = 1">
				<fo:block>
					<xsl:choose>
					<xsl:when test="$label">
						<xsl:value-of select="replace($label,'_',' ')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="replace(local:capitalize-first-word(local:tagName(.)),'_',' ')"/>
						<xsl:text>: </xsl:text>
					</xsl:otherwise>
				</xsl:choose>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="combine-that-title-and-date">
		<!--test if the unittitle has content-->
		<xsl:if test="ead:did/ead:unittitle[normalize-space()]">

			<!--pass it on to the unittitle template-->
			<xsl:choose>
				<xsl:when test="ead:did/ead:unittitle/*[last()][contains(@render, 'quote')] and 
					not(ead:did/ead:unittitle/node()[last()]/self::text())">
					<xsl:choose>
						<xsl:when test="ead:did/ead:unitdate">
							<xsl:apply-templates select="ead:did/ead:unittitle" mode="step2_pdf">
								<xsl:with-param name="add-comma" select="true()" as="xs:boolean"/>
							</xsl:apply-templates>
						</xsl:when>
						
						<xsl:otherwise>
							<xsl:apply-templates select="ead:did/ead:unittitle" mode="step2_pdf"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>

				<xsl:otherwise>
					<xsl:apply-templates select="ead:did/ead:unittitle" mode="step2_pdf"/>
					<!-- test if date exists before adding the first comma-->
					<xsl:if test="ead:did/ead:unitdate">
						<xsl:text>, </xsl:text>
					</xsl:if>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
		
		<!--the rest handles the unitdates...  if a title is missing, the unitdate will stand in for the unittitle-->
		<!-- inclusive dates -->
		<xsl:apply-templates select="ead:did/ead:unitdate[not(contains(., 'undated'))][not(@type='bulk')]" mode="step2_pdf"/>
			
		<xsl:if test="ead:did/ead:unitdate[preceding-sibling::ead:unitdate][(contains(., 'undated'))] or
			ead:did/ead:unitdate[following-sibling::ead:unitdate][(contains(., 'undated'))]">
			<xsl:text>, </xsl:text>
		</xsl:if>
		<!-- undated -->
		<xsl:apply-templates select="ead:did/ead:unitdate[(contains(., 'undated'))]" mode="step2_pdf"/>
		<!-- then bulk -->
		<xsl:apply-templates select="ead:did/ead:unitdate[@type = 'bulk']" mode="step2_pdf"/>
				
	</xsl:template>

	<xsl:template match="ead:unitdate[not(@type='bulk')]" mode="step2_pdf">
		<xsl:apply-templates mode="step2_pdf"/>
		<xsl:if test="not(position() = last())">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ead:unitdate[@type='bulk']" mode="step2_pdf">
		<xsl:text> (</xsl:text>
		<xsl:apply-templates mode="step2_pdf"/>
		<xsl:if test="not(position() = last())">
			<xsl:text>, </xsl:text>
		</xsl:if>
		<xsl:text>)</xsl:text>
	</xsl:template>

	<xsl:template match="ead:unitdate" mode="step2_pdf" >
		<xsl:apply-templates mode="step2_pdf"/>
		<xsl:if test="not(position() = last())">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template name="container_details">
		<!-- formats grouped containers. set group terms and fo:block details prior to call-template -->		
		<xsl:for-each select="current-group()">
			<xsl:value-of select="concat(@type,' ',normalize-space(.))"/>
			<xsl:if test="position() != last()">
				<xsl:text>, </xsl:text>
			</xsl:if>
		</xsl:for-each>
		
		<!--<xsl:if test="lower-case(@label) ne 'mixed materials' and last() gt 1">
					<xsl:value-of select="concat(' (', lower-case(@label), ')')"/>
				</xsl:if> -->
		<xsl:if test="following-sibling::ead:container and (position() lt last())">
			<xsl:text>; </xsl:text>
			<fo:block/>
		</xsl:if>
		
	</xsl:template>
	
	<xsl:template name="langmaterial">
		<fo:block>
			<xsl:choose>
				<!-- When the langmaterial does not have any notes -->
				<xsl:when test="child::*">
					<xsl:for-each select="ead:language/text()">
						<xsl:apply-templates select="normalize-space(.)"/>
						<xsl:if test="position()!=last()">
							<xsl:text>, </xsl:text>
						</xsl:if>
					</xsl:for-each>
				</xsl:when>
				<!-- When the langmaterial has notes -->
				<xsl:otherwise>
					<xsl:apply-templates />
				</xsl:otherwise>
			</xsl:choose>
		</fo:block>
	</xsl:template>
		
	<xsl:template name="digital_content">		
		<fo:block font-size="inherit" xsl:use-attribute-sets="link">
			<fo:basic-link external-destination="url('{@*:href}')">
				<xsl:call-template name="digital_content_type"/>
				<!-- follow type with the caption, provided not just repeating the title or title-date-->
				<xsl:variable name="dates">
					<xsl:value-of select="ancestor::ead:c[1]/ead:did/ead:unitdate" separator=", "/>
				</xsl:variable>				
				<xsl:variable name="caption-clean">
					<xsl:value-of select="normalize-space(translate(ead:daodesc/ead:p,'.,:;[]',' '))"/>
				</xsl:variable>
				<xsl:variable name="title-clean">
					<xsl:value-of select="normalize-space(translate(preceding-sibling::ead:unittitle,'.,:;[]',' '))"/>
				</xsl:variable>
				<xsl:variable name="dates-clean">
					<xsl:value-of select="normalize-space(translate($dates,'.,:;[]',' '))"/>
				</xsl:variable>
				
				<xsl:choose>
					<xsl:when test="$caption-clean = $title-clean"/>
					<xsl:when test="$caption-clean = concat($title-clean,' ',$dates-clean)"/>
					
					<xsl:otherwise>
						<xsl:text>: </xsl:text>
						<xsl:value-of select="ead:daodesc/ead:p/normalize-space()"/>
					</xsl:otherwise>
				</xsl:choose>
			</fo:basic-link>
		</fo:block>
	</xsl:template>
	
	<xsl:template name="digital_content_type">
		<xsl:choose>
			<xsl:when test="matches(@*:role, 'image')">Image(s)</xsl:when>
			<xsl:when test="matches(@*:role, 'audio')">Audio</xsl:when>
			<xsl:when test="matches(@*:role, 'video')">Video</xsl:when>
			<xsl:when test="matches(@*:role, 'text')">Text</xsl:when>
			<xsl:otherwise>Digital Content</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="daogrp_content">		
		<fo:block font-size="inherit" xsl:use-attribute-sets="link">
			<fo:basic-link external-destination="url('{ead:daoloc[@xlink:role eq 'web-resource-link']/@xlink:href}')">
				<!-- follow type with the caption, provided not just repeating the title or title-date-->
				<!-- will need to udpate EAD export process to get DAO type... for now, just call these daogrp liink pairs "Digital Content"-->
				<xsl:text>Digital Content</xsl:text>
				<xsl:variable name="dates">
					<xsl:value-of select="ancestor::ead:c[1]/ead:did/ead:unitdate" separator=", "/>
				</xsl:variable>				
				<xsl:variable name="caption-clean">
					<xsl:value-of select="normalize-space(translate(ead:daodesc/ead:p,'.,:;[]',' '))"/>
				</xsl:variable>
				<xsl:variable name="title-clean">
					<xsl:value-of select="normalize-space(translate(preceding-sibling::ead:unittitle,'.,:;[]',' '))"/>
				</xsl:variable>
				<xsl:variable name="dates-clean">
					<xsl:value-of select="normalize-space(translate($dates,'.,:;[]',' '))"/>
				</xsl:variable>
				
				<xsl:choose>
					<xsl:when test="$caption-clean = $title-clean"/>
					<xsl:when test="$caption-clean = concat($title-clean,' ',$dates-clean)"/>
					
					<xsl:otherwise>
						<xsl:text>: </xsl:text>
						<xsl:value-of select="ead:daodesc/ead:p/normalize-space()"/>
					</xsl:otherwise>
				</xsl:choose>
			</fo:basic-link>
		</fo:block>
	</xsl:template>
	
	<xsl:template mode="step2_pdf" match="ead:daodesc"/>
	
	<xsl:template mode="step2_pdf" match="ead:ptr">
		<xsl:choose>
			<xsl:when test="@target">
				<fo:inline xsl:use-attribute-sets="link">
					<fo:basic-link internal-destination="{@target}">
						<!-- I should grab the "title" or "head" of the element that's linked to,
						rather than outputting the target value (which will always be refXXX)-->
						<xsl:value-of select="@target"/>
					</fo:basic-link>
				</fo:inline>
			</xsl:when>
			<xsl:when test="@*:href">
				<fo:inline xsl:use-attribute-sets="link">
					<fo:basic-link internal-destination="{@*:href}">
						<xsl:value-of select="@*:href"/>
					</fo:basic-link>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates mode="step2_pdf"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="following-sibling::ead:ptr or following-sibling::ead:ref">, </xsl:if>
	</xsl:template>
	
	<xsl:template mode="step2_pdf" match="ead:ref">
		<xsl:choose>
			<xsl:when test="@target">
				<fo:inline xsl:use-attribute-sets="link">
					<fo:basic-link internal-destination="{@target}">
						<xsl:apply-templates mode="step2_pdf"/>
					</fo:basic-link>
				</fo:inline>
			</xsl:when>
			<xsl:when test="@*:href and starts-with(@*:href , 'http')">
				<fo:inline xsl:use-attribute-sets="link">
					<fo:basic-link external-destination="{@*:href}">
						<xsl:apply-templates mode="step2_pdf"/>
					</fo:basic-link>
				</fo:inline>
			</xsl:when>
			<xsl:when test="@*:href">
				<fo:inline xsl:use-attribute-sets="link">
					<fo:basic-link internal-destination="{@*:href}">
						<xsl:apply-templates mode="step2_pdf"/>
					</fo:basic-link>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates mode="step2_pdf"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="following-sibling::ead:ptr or following-sibling::ead:ref">, </xsl:if>
	</xsl:template>	

	<!--Physdesc handling -->
	<xsl:template match="ead:physdesc" mode="step2_pdf">
		<xsl:apply-templates mode="step2_pdf"/>
		<!--MDC: adds a line break after each physdesc group-->
		<xsl:if test="position()!=last()">
			<fo:block/>
		</xsl:if>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:extent">
		
			<xsl:if test="preceding-sibling::ead:extent[normalize-space()]">
				<xsl:text> (</xsl:text>
			</xsl:if>
			<xsl:apply-templates mode="step2_pdf"/>
			
		<xsl:if test="preceding-sibling::ead:extent[normalize-space()]
			and not(following-sibling::*)">
				<xsl:text>)</xsl:text>
			</xsl:if>
			
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:physfacet">
		<xsl:choose>
			<xsl:when test="preceding-sibling::ead:extent[normalize-space()][1]
				and count(preceding-sibling::ead:*) = 1">
				<xsl:text> (</xsl:text>
				<xsl:apply-templates mode="step2_pdf"/>
				<xsl:if test="position() = last()">
					<xsl:text>)</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when test="preceding-sibling::ead:extent[normalize-space()][2]">
				<xsl:text>; </xsl:text>
				<xsl:apply-templates mode="step2_pdf"/>
				<xsl:if test="position() = last()">
					<xsl:text>)</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates mode="step2_pdf"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:dimensions">
		<xsl:choose>
			<xsl:when test="preceding-sibling::ead:extent[normalize-space()][1]
				and count(preceding-sibling::ead:*) = 1">
				<xsl:text> (</xsl:text>
				<xsl:apply-templates mode="step2_pdf"/>
				<xsl:if test="position() = last()">
					<xsl:text>)</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:when
				test="preceding-sibling::ead:extent[normalize-space()][2] | preceding-sibling::ead:physfacet[normalize-space()]">
				<xsl:text>; </xsl:text>
				<xsl:apply-templates mode="step2_pdf"/>
				<xsl:if test="position() = last()">
					<xsl:text>)</xsl:text>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates mode="step2_pdf"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	

	<!-- Notes -->	
	<xsl:template mode="step2_pdf" match="ead:abstract">
		<fo:block xsl:use-attribute-sets="paragraph">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:block>
	</xsl:template>
	
	<xsl:template mode="step2_pdf" match="ead:legalstatus">
		<fo:block xsl:use-attribute-sets="paragraph">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:block>
		
	</xsl:template>
	
	<xsl:template mode="step2_pdf" match="ead:altformavail">
		<xsl:apply-templates mode="step2_pdf"/>
	</xsl:template>
	
	<!-- format the ead:number that's now output as part of the altformavail note-->
	<xsl:template mode="step2_pdf" match="ead:num[@type='scan_count']">
		<xsl:value-of select="format-number(., '#,###')"/>
	</xsl:template>
	
	
	<xsl:template mode="step2_pdf" match="ead:extptr | ead:extref">
		<xsl:call-template name="digital_basic_links"/>
	</xsl:template>
	<!--Bibref citation  inline, if there is a parent element.-->
	<xsl:template mode="step2_pdf" match="ead:p/ead:bibref">
		<xsl:call-template name="digital_basic_links"/>
	</xsl:template>
	<!--Bibref citation on its own line, typically when it is a child of the bibliography element-->
	<xsl:template mode="step2_pdf" match="ead:bibref">
		<fo:block xsl:use-attribute-sets="list2">
			<xsl:call-template name="digital_basic_links"/>
		</fo:block>
	</xsl:template>
	
	<!-- need to fix this still.  check out nasm.xxxx.0093, appendix 1, as an example-->
	<xsl:template mode="step2_pdf" match="ead:defitem">
		<fo:list-item space-after="3pt">
			<fo:list-item-label end-indent="label-end()">
				<fo:block/>
			</fo:list-item-label>
			<fo:list-item-body start-indent="body-start()">
				<fo:block>
					<fo:inline font-style="italic">
						<xsl:apply-templates select="ead:label" mode="step2_pdf"/>
					</fo:inline>
					<xsl:text>: </xsl:text>
					<xsl:apply-templates select="ead:item" mode="step2_pdf"/>
				</fo:block>
			</fo:list-item-body>
		</fo:list-item>
	</xsl:template>

	<xsl:template mode="step2_pdf" match="ead:materialspec | ead:langmaterial | ead:physloc | ead:note" >
		<xsl:choose>
			<xsl:when test="ancestor::ead:dsc">
				<xsl:for-each-group select="." group-by="local:tagName(.)">
					<xsl:call-template name="details_list"/>
				</xsl:for-each-group>				
			</xsl:when>
			<xsl:otherwise>
				<fo:block xsl:use-attribute-sets="paragraph">					
					<xsl:apply-templates mode="step2_pdf"/>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:template name="digital_basic_links">
		<xsl:choose>
			<xsl:when test="@*:href">
				<fo:inline xsl:use-attribute-sets="link">
					<fo:basic-link external-destination="url('{@*:href}')"> <!-- warm blue  -->
						<xsl:apply-templates mode="step2_pdf"/>
					</fo:basic-link>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates mode="step2_pdf"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	

	<!--basic styles for the finding aid.-->
	<xsl:attribute-set name="normal-text-size">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
	</xsl:attribute-set>
	<xsl:attribute-set name="list">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="space-before">5pt</xsl:attribute>
		<xsl:attribute name="space-after">5pt</xsl:attribute>
		<xsl:attribute name="margin-left">30pt</xsl:attribute>
		<xsl:attribute name="provisional-distance-between-starts">0.75cm</xsl:attribute>
		<xsl:attribute name="provisional-label-separation">0.5cm</xsl:attribute>
		
	</xsl:attribute-set>
	<xsl:attribute-set name="list2">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="space-before">5pt</xsl:attribute>
		<xsl:attribute name="space-after">5pt</xsl:attribute>
		<xsl:attribute name="provisional-distance-between-starts">0.75cm</xsl:attribute>
		<xsl:attribute name="provisional-label-separation">0.5cm</xsl:attribute>
	</xsl:attribute-set>
	<xsl:attribute-set name="chronList">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="margin-left">25pt</xsl:attribute>
	</xsl:attribute-set>
	<xsl:attribute-set name="paragraph">
		<xsl:attribute name="space-after">5pt</xsl:attribute>
	</xsl:attribute-set>
	<xsl:attribute-set name="link">
		<!--<xsl:attribute name="text-decoration">underline</xsl:attribute>-->
		<xsl:attribute name="color">#4a77b4</xsl:attribute> <!-- Or, blue -->
	</xsl:attribute-set>

	<!-- The following attribute sets are reusable styles used throughout the stylesheet. -->
	<!-- Headings -->
	<xsl:attribute-set name="h1">
		<xsl:attribute name="font-size">20pt</xsl:attribute>
		<xsl:attribute name="margin-top">16pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
		<xsl:attribute name="space-before">19pt</xsl:attribute>
		<xsl:attribute name="space-after">10pt</xsl:attribute>
		
	</xsl:attribute-set>
	<xsl:attribute-set name="h2">
		<xsl:attribute name="font-size">16pt</xsl:attribute>
		<!--<xsl:attribute name="border-top">4pt solid #333</xsl:attribute>-->
		<!--<xsl:attribute name="border-bottom">1pt dotted #333</xsl:attribute>-->
		<xsl:attribute name="margin-bottom">12pt</xsl:attribute>
		<xsl:attribute name="margin-top">4pt</xsl:attribute>
		<xsl:attribute name="padding-top">8pt</xsl:attribute>
		<xsl:attribute name="padding-bottom">8pt</xsl:attribute>
		<xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
		
		<xsl:attribute name="space-before">19pt</xsl:attribute>
		<xsl:attribute name="space-after">5pt</xsl:attribute>
	</xsl:attribute-set>
	<xsl:attribute-set name="h3">
		<xsl:attribute name="font-size">14pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">4pt</xsl:attribute>
<!--		<xsl:attribute name="padding-bottom">0</xsl:attribute>-->
		<xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
		
		<xsl:attribute name="space-before">14pt</xsl:attribute>
		<xsl:attribute name="padding-top">8pt</xsl:attribute>
		<xsl:attribute name="padding-bottom">8pt</xsl:attribute>
		<xsl:attribute name="space-after">5pt</xsl:attribute>
		
		<!--<xsl:attribute name="font-size">13pt</xsl:attribute>
		<xsl:attribute name="space-before">14pt</xsl:attribute>
		<xsl:attribute name="padding-top">8pt</xsl:attribute>
		<xsl:attribute name="padding-bottom">8pt</xsl:attribute>
		<xsl:attribute name="space-after">5pt</xsl:attribute>
		<xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>-->
	</xsl:attribute-set>
	<xsl:attribute-set name="h4">
		<xsl:attribute name="font-size">12pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">4pt</xsl:attribute>
		<xsl:attribute name="padding-bottom">0</xsl:attribute>
		<xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
		
		<xsl:attribute name="space-before">5pt</xsl:attribute>
		<xsl:attribute name="space-after">5pt</xsl:attribute>
		
		<!--
		<xsl:attribute-set name="h4">
			<xsl:attribute name="font-size">12pt</xsl:attribute>
			<xsl:attribute name="space-before">5pt</xsl:attribute>
			<xsl:attribute name="space-after">5pt</xsl:attribute>
			<xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
		</xsl:attribute-set>-->
	</xsl:attribute-set>
	<xsl:attribute-set name="h5">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">4pt</xsl:attribute>
		<xsl:attribute name="padding-bottom">0</xsl:attribute>
		<xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
		
		<xsl:attribute name="space-before">10pt</xsl:attribute>
		<xsl:attribute name="space-after">5pt</xsl:attribute>
	</xsl:attribute-set>
	
	<!-- Headings with id attribute -->
	<xsl:attribute-set name="h1ID" use-attribute-sets="h1">
		<xsl:attribute name="id"><xsl:value-of select="local:buildID(.)"/></xsl:attribute>
	</xsl:attribute-set>
	<xsl:attribute-set name="h2ID" use-attribute-sets="h2">
		<xsl:attribute name="id"><xsl:value-of select="local:buildID(.)"/></xsl:attribute>
	</xsl:attribute-set>
	<xsl:attribute-set name="h3ID" use-attribute-sets="h3">
		<xsl:attribute name="id"><xsl:value-of select="local:buildID(.)"/></xsl:attribute>
	</xsl:attribute-set>
	<xsl:attribute-set name="h4ID" use-attribute-sets="h4">
		<xsl:attribute name="id"><xsl:value-of select="local:buildID(.)"/></xsl:attribute>
	</xsl:attribute-set>
	
	<!-- Linking attributes styles -->
	<xsl:attribute-set name="ref">
		<xsl:attribute name="color">#4a77b4</xsl:attribute>
		<!--<xsl:attribute name="text-decoration">underline</xsl:attribute>-->
	</xsl:attribute-set>
	
	<!-- Standard margin and padding for most fo:block elements, including paragraphs -->
	<xsl:attribute-set name="smp">
		<xsl:attribute name="margin">4pt</xsl:attribute>
		<xsl:attribute name="padding">4pt</xsl:attribute>
	</xsl:attribute-set>
	
	<!-- Standard margin and padding for elements with in the dsc table -->
	<xsl:attribute-set name="smpDsc">
		<xsl:attribute name="margin">2pt</xsl:attribute>
		<xsl:attribute name="padding">2pt</xsl:attribute>
	</xsl:attribute-set>
	
	<!-- Styles for main sections -->
	<xsl:attribute-set name="section">
		<xsl:attribute name="margin-top">4pt</xsl:attribute>
		<xsl:attribute name="padding">4pt</xsl:attribute>
	</xsl:attribute-set>
	
	<!-- Table attributes for tables with borders -->
	<xsl:attribute-set name="tableBorder">
		<xsl:attribute name="table-layout">fixed</xsl:attribute>
		<xsl:attribute name="width">100%</xsl:attribute>
		<xsl:attribute name="border">.5pt solid #dfdfdf</xsl:attribute>
		<xsl:attribute name="border-collapse">separate</xsl:attribute>
		<xsl:attribute name="space-after">12pt</xsl:attribute>
	</xsl:attribute-set>
	<!-- Table headings -->
	<xsl:attribute-set name="th">
		<xsl:attribute name="background-color">#dfdfdf</xsl:attribute>
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="text-align">left</xsl:attribute>
	</xsl:attribute-set>
	<!-- Table cells with borders -->
	<xsl:attribute-set name="tdBorder">
		<xsl:attribute name="border">.5pt solid #dfdfdf</xsl:attribute>
		<xsl:attribute name="border-collapse">separate</xsl:attribute>
	</xsl:attribute-set>
	



	<!-- MDC: previously, i had this on the entire table row (using "keep-together.within-column"),
		but that doesn't work for finding aids that have file/item levels of description 
		that go over a single page (e.g. NAA's leach.xml file). Now, this attribute should 
		only be applied if the file/item-level does NOT have any notes outside of the <did>-->
	<xsl:template name="force-same-page">
		<xsl:attribute name="keep-together.within-column">always</xsl:attribute>
	</xsl:template>
	
	<!--MDC:  formatting templates that should've been in here all along 
		(as separate templates, not bound up w/ their parents-->
	<xsl:template mode="step2_pdf" match="ead:p">
		<fo:block xsl:use-attribute-sets="paragraph" text-align="justify" >
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:block>
		
    	<!-- most notes do not display head at dsc level .. but there are some exceptions -->
		<!--<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][self::ead:head]
				[parent::ead:odd or parent::ead:index or parent::ead:bibliography]
				[not(lower-case(text()) = 'general')]
				[not(lower-case(text()) = 'general note')]
				[not(self::* = parent::ead:odd/preceding-sibling::ead:odd/ead:head)]">
				
				<fo:block margin-left="25pt" xsl:use-attribute-sets="paragraph">
					<xsl:apply-templates mode="step2_pdf"/>
				</fo:block>
			</xsl:when>
			<!-\- headless -\->
			<xsl:otherwise>
				<fo:block xsl:use-attribute-sets="paragraph">
					<xsl:apply-templates mode="step2_pdf"/>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>-->
	</xsl:template>

	<!-- The following general templates format the display of various RENDER  attributes..-->
	<xsl:template match="*[@render = 'bolddoublequote']" mode="step2_pdf">
		<xsl:param name="add-comma" select="false()" as="xs:boolean"/>
		<fo:inline font-weight="bold" font-size="inherit">
			<xsl:choose>
				<xsl:when test="$add-comma eq true()">&#x201c;<xsl:apply-templates mode="step2_pdf"
				/>,&#x201d; </xsl:when>
				<xsl:otherwise> &#x201c;<xsl:apply-templates mode="step2_pdf"/>&#x201d;
				</xsl:otherwise>
			</xsl:choose>
		</fo:inline>
	</xsl:template>
	<xsl:template match="*[@render = 'boldsinglequote']" mode="step2_pdf">
		<xsl:param name="add-comma" select="false()" as="xs:boolean"/>
		<fo:inline font-weight="bold" font-size="inherit">
			<xsl:choose>
				<xsl:when test="$add-comma eq true()">&#x2018;<xsl:apply-templates mode="step2_pdf"
				/>,&#x2019; </xsl:when>
				<xsl:otherwise> &#x2018;<xsl:apply-templates mode="step2_pdf"/>&#x2019;
				</xsl:otherwise>
			</xsl:choose>
		</fo:inline>
	</xsl:template>
	<xsl:template match="*[@render = 'doublequote']" mode="step2_pdf">
		<xsl:param name="add-comma" select="false()" as="xs:boolean"/>
		<fo:inline>
			<xsl:choose>
				<xsl:when test="$add-comma eq true()">&#x201c;<xsl:apply-templates mode="step2_pdf"
				/>,&#x201d; </xsl:when>
				<xsl:otherwise> &#x201c;<xsl:apply-templates mode="step2_pdf"/>&#x201d;
				</xsl:otherwise>
			</xsl:choose>
		</fo:inline>
	</xsl:template>
	<xsl:template match="*[@render = 'singlequote']" mode="step2_pdf">
		<xsl:param name="add-comma" select="false()" as="xs:boolean"/>
		<fo:inline>
			<xsl:choose>
				<xsl:when test="$add-comma eq true()">&#x2018;<xsl:apply-templates mode="step2_pdf"
				/>,&#x2019; </xsl:when>
				<xsl:otherwise> &#x2018;<xsl:apply-templates mode="step2_pdf"/>&#x2019;
				</xsl:otherwise>
			</xsl:choose>
		</fo:inline>
	</xsl:template>
	<xsl:template match="ead:blockquote/ead:p" mode="step2_pdf">
		<fo:block font-size="inherit" margin-left="5mm" margin-right="5mm">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:block>
	</xsl:template>
	<xsl:template match="ead:emph[@render='bold'] | ead:title[@render='bold']" mode="step2_pdf">
		<fo:inline font-weight="bold" font-size="inherit">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="ead:emph[@render='italic'] | ead:title[@render='italic']" mode="step2_pdf">
		<fo:inline font-style="italic" font-size="inherit">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="ead:emph[@render='underline'] | ead:title[@render='underline']" mode="step2_pdf">
		<fo:inline text-decoration="underline">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:emph[@render='sub'] | ead:title[@render='sub']">
		<fo:inline vertical-align="sub" font-size="inherit">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:emph[@render='super'] | ead:title[@render='super']">
		<fo:inline vertical-align="super" font-size="6pt" font-weight="bold">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:emph[@render='boldunderline'] | ead:title[@render='boldunderline']">
		<fo:inline font-weight="bold" text-decoration="underline" font-size="inherit">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:emph[@render='bolditalic'] | ead:title[@render='bolditalic']">
		<fo:inline font-weight="bold" font-style="italic" font-size="inherit">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:emph[@render='boldsmcaps'] | ead:title[@render='boldsmcaps']">
		<fo:inline font-weight="bold" font-variant="small-caps" font-size="inherit">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:emph[@render='smcaps'] | ead:title[@render='smcaps']">
		<fo:inline font-variant="small-caps">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:inline>
	</xsl:template>
	
	<!--This template rule formats a chronlist element.-->
	<xsl:template mode="step2_pdf" match="ead:chronlist">
		<fo:table table-layout="fixed" width="100%" xsl:use-attribute-sets="chronList">
			<fo:table-column column-width="30%"/>
			<fo:table-column column-width="70%"/>
			<fo:table-body>
				<xsl:apply-templates select="ead:head, ead:listhead" mode="step2_pdf"/>
				<xsl:apply-templates select="ead:chronitem" mode="step2_pdf"/>
			</fo:table-body>
		</fo:table>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:chronlist/ead:head">
		<fo:table-row>
			<fo:table-cell number-columns-spanned="2">
				<fo:block font-weight="bold">
					<xsl:apply-templates mode="step2_pdf"/>
				</fo:block>
			</fo:table-cell>
		</fo:table-row>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:chronlist/ead:listhead">
		<fo:table-row>
			<fo:table-cell>
				<fo:block font-weight="bold">
					<xsl:apply-templates select="ead:head01" mode="step2_pdf"/>
				</fo:block>
			</fo:table-cell>
			<fo:table-cell>
				<fo:block font-weight="bold">
					<xsl:apply-templates select="ead:head02" mode="step2_pdf"/>
				</fo:block>
			</fo:table-cell>
		</fo:table-row>
	</xsl:template>
	
	<!--MDC:  Keep this as is for now (but it could be shortened).  Still, it should work fine.-->
	<xsl:template mode="step2_pdf" match="ead:chronitem">
		<!--Determine if there are event groups.-->
		<xsl:choose>
			<xsl:when test="ead:eventgrp">
				<!--Put the date and first event on the first line.-->
				<fo:table-row>
					<fo:table-cell display-align="before" padding-bottom="5pt">
						<fo:block font-style="italic" font-size="inherit">
							<xsl:apply-templates select="ead:date" mode="step2_pdf"/>
						</fo:block>
					</fo:table-cell>
					<fo:table-cell display-align="before" padding-bottom="5pt">
						<fo:block font-size="inherit">
							<xsl:apply-templates select="ead:eventgrp/ead:event[position()=1]"
								mode="step2_pdf"/>
						</fo:block>
					</fo:table-cell>
				</fo:table-row>
				<!--Put each successive event on another line.-->
				<xsl:for-each select="ead:eventgrp/ead:event[not(position()=1)]">
					<fo:table-row>
						<fo:table-cell padding-bottom="5pt">
							<fo:block> </fo:block>
						</fo:table-cell>
						<fo:table-cell display-align="before" padding-bottom="5pt">
							<fo:block>
								<xsl:apply-templates select="." mode="step2_pdf"/>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</xsl:for-each>
			</xsl:when>
			<!--Put the date and event on a single line.-->
			<xsl:otherwise>
				<fo:table-row>
					<fo:table-cell display-align="before" padding-bottom="5pt">
						<fo:block font-style="italic" font-size="inherit">
							<xsl:apply-templates select="ead:date" mode="step2_pdf"/>
						</fo:block>
					</fo:table-cell>
					<fo:table-cell display-align="before" padding-bottom="5pt">
						<fo:block font-size="inherit">
							<xsl:apply-templates select="ead:event" mode="step2_pdf"/>
						</fo:block>
					</fo:table-cell>
				</fo:table-row>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>	
	<xsl:template mode="step2_pdf" match="ead:list">
		<xsl:choose>
			<xsl:when test="ead:head">
				<fo:block>
					<xsl:value-of select="ead:head"/>
					<xsl:text>:</xsl:text>
				</fo:block>
				<!-- nested list - keep provisional between starts smaller -->
				<xsl:choose>
					<xsl:when test="@type='deflist'">
						<fo:list-block display-align="before" 
							provisional-distance-between-starts="5mm"
							provisional-label-separation="1.5mm">
							<xsl:apply-templates select="ead:defitem" mode="step2_pdf"/>
						</fo:list-block>
					</xsl:when>
					<xsl:otherwise>
						<fo:list-block display-align="before" 
							provisional-distance-between-starts="5mm"
							provisional-label-separation="1.5mm">
							<xsl:apply-templates select="ead:item" mode="step2_pdf"/>
						</fo:list-block>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			
			<xsl:otherwise>
				<fo:list-block xsl:use-attribute-sets="list2">
					<xsl:apply-templates mode="step2_pdf"/>
				</fo:list-block>
				
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template mode="step2_pdf" match="ead:item">
		<fo:list-item>
			<fo:list-item-label end-indent="label-end()">
				<fo:block>
					<xsl:choose>
						<xsl:when test="../@type='ordered' and ../@numeration = 'arabic'">
							<xsl:number format="1"/>
							<xsl:text>)</xsl:text>
						</xsl:when>
						<xsl:when test="../@type='ordered' and ../@numeration = 'upperalpha'">
							<xsl:number format="A"/>
							<xsl:text>)</xsl:text>
						</xsl:when>
						<xsl:when test="../@type='ordered' and ../@numeration = 'loweralpha'">
							<xsl:number format="a"/>
							<xsl:text>)</xsl:text>
						</xsl:when>
						<xsl:when test="../@type='ordered' and ../@numeration = 'upperroman'">
							<xsl:number format="I"/>
							<xsl:text>.</xsl:text>
						</xsl:when>
						<xsl:when test="../@type='ordered' and ../@numeration = 'lowerroman'">
							<xsl:number format="i"/>
							<xsl:text>.</xsl:text>
						</xsl:when>
						<xsl:when test="../@type='simple' or ../@type='deflist'"/>
						<xsl:otherwise>&#x2022;</xsl:otherwise>
					</xsl:choose>
				</fo:block>
			</fo:list-item-label>
			<fo:list-item-body start-indent="body-start()">
				<fo:block>
					<xsl:apply-templates mode="step2_pdf"/>
				</fo:block>
			</fo:list-item-body>
		</fo:list-item>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:defitem/ead:item">
		<xsl:apply-templates mode="step2_pdf"/>
	</xsl:template>
	
	<!-- Formats a simple table. -->
	<xsl:template mode="step2_pdf" match="ead:table">
		<xsl:apply-templates mode="step2_pdf"/>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:tgroup">
		<fo:table>
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:table>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:colspec">
		<!--width specified in EAD files are too small-->
		<fo:table-column/>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:thead">
		<fo:table-header>
			<xsl:apply-templates mode="thead"/>
		</fo:table-header>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:tbody">
		<fo:table-body>
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:table-body>
	</xsl:template>
	<xsl:template match="ead:row" mode="thead">
		<fo:table-row xsl:use-attribute-sets="th">
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:table-row>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:row">
		<fo:table-row>
			<xsl:apply-templates mode="step2_pdf"/>
		</fo:table-row>
	</xsl:template>
	<xsl:template mode="step2_pdf" match="ead:entry">
		<fo:table-cell xsl:use-attribute-sets="tdBorder">
			<fo:block>
				<xsl:apply-templates mode="step2_pdf"/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>
		
	<!-- head template to translate note headers in the DSC-->
	<xsl:template mode="step2_pdf" match="ead:head[ancestor::ead:dsc]">
		<xsl:param name="level" tunnel="yes"/>
		<xsl:choose>
			
			<!-- MDC:  include the following if want to include general, index, biblio note head. -->
			<xsl:when test="$level='dsc-level' and parent::ead:odd 
				and not(lower-case(text()) = 'general')
				and not(lower-case(text()) = 'general note')
				and not(self::* = parent::ead:odd/preceding-sibling::ead:odd/ead:head)">
				<fo:block id="{../@id}" keep-with-next.within-page="always">
					<!-- font-weight="bold" -->
					<xsl:value-of select="."/>
				</fo:block>
			</xsl:when>
			<xsl:when test="$level='dsc-level' and parent::ead:index
				and not(self::* = parent::ead:index/preceding-sibling::ead:odd/ead:head)">
				<fo:block id="{../@id}" xsl:use-attribute-sets="h5">
					<xsl:value-of select="."/>
				</fo:block>
			</xsl:when>
			<xsl:when test="$level='dsc-level' and parent::ead:bibliography
				and not(self::* = parent::ead:bibliography/preceding-sibling::ead:odd/ead:head)">
				<fo:block id="{../@id}" keep-with-next.within-page="always">
					<xsl:value-of select="."/>
				</fo:block>
			</xsl:when>
			<xsl:when test="$level='dsc-level' and parent::ead:list">
				<fo:block keep-with-next.within-page="always">
					<xsl:value-of select="."/>
				</fo:block>
			</xsl:when>
			<!-- Suppress remaining ead:heads in the DSC -->
			<!-- most notes do not display head at dsc level -->
			<xsl:when test="$level='dsc-level'"/>
		</xsl:choose>
	</xsl:template>
	
	
	<xsl:function name="local:tagName">
		<!-- element node as parameter -->
		<xsl:param name="elementNode"/>
		<!-- Name of element -->
		<xsl:variable name="tag" select="name($elementNode)"/>
		
		<!-- Find element name -->
		<xsl:choose>
			<!-- did/origination: label is role ('donor'), then orig label (creator or subject), then default Names -->
			<xsl:when test="$elementNode/@role[normalize-space()]">
				<xsl:value-of select="replace($elementNode/@role,' \(.*','')"/>
			</xsl:when>
			<xsl:when test="$elementNode/*/@role[normalize-space()]">
				<xsl:value-of select="replace($elementNode/*/@role,' \(.*','')"/>
			</xsl:when>
			<xsl:when test="$elementNode/parent::ead:origination/@label[normalize-space()]">
				<xsl:value-of select="$elementNode/parent::ead:origination/@label"/>
			</xsl:when>
			<xsl:when test="$elementNode/parent::ead:origination">Creator</xsl:when>
			
			<!-- other & note headers - Use these preferred label/head terms  -->
			<!--<xsl:when test="$tag = 'unitid' and matches(lower-case($elementNode/@type),'ark')">Record Link</xsl:when>-->
			
			<xsl:when test="$tag = 'bioghist' 
				and matches($elementNode/ead:head,'^(Biographical/Historical note| Biographical/Historical)$')">Biographical Note</xsl:when>
			<xsl:when test="$tag = 'accessrestrict' 
				and matches($elementNode/ead:head,'^(Conditions Governing Access note|Conditions Governing Access)$')">Restrictions</xsl:when>
			<xsl:when test="$tag = 'userestrict' 
				and matches($elementNode/ead:head,'^(Conditions Governing Use note | Conditions Governing Use)$')">Ownership &amp; Literary Rights</xsl:when>
			<xsl:when test="$tag = 'custodhist' 
				and matches($elementNode/ead:head,'^(Custodial History note|Custodial History)$')">Provenance</xsl:when>
			<xsl:when test="$tag = 'altformavail' 
				and matches($elementNode/ead:head,'^(Existence and Location of Copies note|Existence and Location of Copies)$')">Available Formats</xsl:when>
			<xsl:when test="$tag = 'originalsloc' 
				and matches($elementNode/ead:head,'^(Existence and Location of Originals note|Existence and Location of Originals)$')">Location of Originals</xsl:when>
			<xsl:when test="$tag = 'acqinfo' 
				and matches($elementNode/ead:head,'^(Immediate Source of Acquisition note|Immediate Source of Acquisition)$')">Acquisition Information</xsl:when>
			
			<xsl:when test="$tag = 'odd' 
				and matches($elementNode/ead:head,'^(Date/Time and Place of an Event Note)$')">Event</xsl:when>
			
			<!-- drop the ' note' addition from AT migrated finding aids -->
			<xsl:when test="matches($elementNode/ead:head,' note$')">
				<xsl:value-of select="replace($elementNode/ead:head,' note$','')"/>
			</xsl:when>
			
			<!-- did elements have @label not head-->
			<xsl:when test="$tag = 'physloc' and matches($elementNode/@label,'^Location$')">Location</xsl:when>
			<xsl:when test="$tag = 'materialspec' and matches($elementNode/@label,'^Material Specific Details note$')">Technical details</xsl:when>
			<xsl:when test="$tag = 'materialspec' and matches($elementNode/@label,'^Material Specific Details$')">Technical details</xsl:when>
			
			
			<!-- Note that ASpace 2.1.2 doesn't export the @label or head for these elements. 
				Until that is fixed, supply defaults here for Collection Overview -->
			<xsl:when test="$tag = 'repository'">Repository</xsl:when>
			<xsl:when test="$tag = 'abstract'">Summary</xsl:when>
			<xsl:when test="$tag = 'unittitle'">Title</xsl:when>
			<xsl:when test="$tag = 'unitdate'">Date</xsl:when>
			<xsl:when test="$tag = 'unitid'">Identifier</xsl:when>
			<xsl:when test="$tag = 'physdesc'">Extent</xsl:when>
			<xsl:when test="$tag = 'extent'">Extent</xsl:when>
			<xsl:when test="$tag = 'physfacet'">Physical Details</xsl:when>
			<xsl:when test="$tag = 'dimensions'">Dimensions</xsl:when>
			<xsl:when test="$tag = 'materialspec'">Technical</xsl:when>
			<xsl:when test="$tag = 'physloc'">Location</xsl:when>
			<xsl:when test="$tag = 'langmaterial'">Language</xsl:when>
			<xsl:when test="$tag = 'container'">Container</xsl:when>
			<xsl:when test="$tag = 'sponsor'">Sponsor</xsl:when>
			
			<xsl:when test="$tag = 'legalstatus'">Legal Status</xsl:when>
			
			<!--<xsl:when test="$tag = 'dao' and matches(lower-case($elementNode/@role),'image')">Image</xsl:when>
			<xsl:when test="$tag = 'dao' and matches(lower-case($elementNode/@role),'audio')">Audio</xsl:when>
			<xsl:when test="$tag = 'dao' and matches(lower-case($elementNode/@role),'video')">Video</xsl:when>
			<xsl:when test="$tag = 'dao' and matches(lower-case($elementNode/@role),'text')">Text</xsl:when>-->
			<!-- do i need to add daogrp here. what is all this 'tag' business? -->
			<xsl:when test="$tag = 'dao'">Digital Content</xsl:when>
			
			
			<!-- notes -->
			<xsl:when test="$tag = 'userestrict' and not($elementNode/ead:head)">Rights</xsl:when>
			<xsl:when test="$tag = 'accessrestrict' and not($elementNode/ead:head)">Restrictions</xsl:when>
			<xsl:when test="$tag = 'prefercite' and not($elementNode/ead:head)">Citation</xsl:when>
			<xsl:when test="$tag = 'acqinfo' and not($elementNode/ead:head)">Provenance</xsl:when>
			
			<!-- access -->
			<xsl:when test="$tag = 'persname'">Names</xsl:when>
			<xsl:when test="$tag = 'corpname'">Names</xsl:when>
			<xsl:when test="$tag = 'famname'">Names</xsl:when>
			<xsl:when test="$tag = 'name'">Names</xsl:when>
			<xsl:when test="$tag = 'subject' and contains($elementNode,'^^695')">Culture</xsl:when>
			<xsl:when test="$tag = 'subject' and $elementNode/@altrender='culture'">Culture</xsl:when>
			<xsl:when test="$tag = 'subject' and $elementNode/@altrender='cultural_context'">Culture</xsl:when>
			<xsl:when test="$tag = 'subject'">Topic</xsl:when>
			<xsl:when test="$tag = 'title'">Topic</xsl:when>
			<xsl:when test="$tag = 'genreform'">Genre/Form</xsl:when>
			<xsl:when test="$tag = 'function'">Function</xsl:when>
			<xsl:when test="$tag = 'geogname'">Place</xsl:when>
			<xsl:when test="$tag = 'occupation'">Occupation</xsl:when>
			
			<!-- anything else gets its own header -->
			<xsl:when test="$elementNode/ead:head or $elementNode/@label">
				<xsl:value-of select="$elementNode/ead:head | $elementNode/@label"/>
			</xsl:when>
			
			<!-- or if none, then Note -->
			<xsl:otherwise>Note</xsl:otherwise>
			
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="local:capitalize-first-word" as="xs:string?">
		<xsl:param name="arg" as="xs:string?"/>
		<xsl:sequence select="concat(upper-case(substring($arg,1,1)),
			substring($arg,2))"/>
	</xsl:function>
	

	<!-- A local function to check for element ids and generate an id if no id exists -->
	<xsl:function name="local:buildID">
		<xsl:param name="element"/>
		<xsl:choose>
			<xsl:when test="$element/@id">
				<xsl:value-of select="$element/@id"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="generate-id($element)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>

</xsl:stylesheet>