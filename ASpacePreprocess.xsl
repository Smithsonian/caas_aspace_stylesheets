<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:caas="http://local-caas-functions"
    version="3.0">
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <!-- update how languages are handled...
        ditto for controlled lists -->
     
    <!-- add a step to remove useless language notes, i.e. notes that contain just the translated version of the language name -->
    
    <xsl:param name="remove_ref_IDs" select="false()" as="xs:boolean"/>
    <xsl:param name="remove_controlAccess" select="false()" as="xs:boolean"/>
    <xsl:param name="remove_existing_ARKs" select="false()" as="xs:boolean"/>
    
    <xsl:param name="unpublish_resource" select="true()" as="xs:boolean"/>
    
    <xsl:template match="ead:ead[$unpublish_resource]">
        <xsl:copy>
            <xsl:attribute name="audience" select="'internal'"/>
            <xsl:apply-templates select="@* except @audience"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="ead:titleproper/ead:num"/>
    
    <xsl:template match="@id[starts-with(., 'aspace_')] | @parent[starts-with(., 'aspace_')]">
        <xsl:attribute name="{local-name()}">
            <xsl:value-of select="substring-after(., 'aspace_')"/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- remove the @id attribute altogether if we set the remove_ref_IDs parameter to true -->
    <xsl:template match="ead:c[$remove_ref_IDs]/@id | 
        ead:*[starts-with(local-name(), 'c0|c1')][$remove_ref_IDs]/@id" priority="5"/>
    
    
    <xsl:template match="ead:controlaccess[$remove_controlAccess]"/>
    
    <xsl:template match="ead:unitid[@type eq 'ark'][$remove_existing_ARKs]"/>
    
    
    
    <!-- carryovers from old process -->
    
    
    <xsl:function name="caas:iso-date-2-display-form" as="xs:string*">
        <xsl:param name="date" as="xs:string"/>
        <xsl:variable name="months"
            select="
            ('January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December')"/>
        <xsl:analyze-string select="$date" flags="x" regex="(\d{{4}})(\d{{2}})?(\d{{2}})?">
            <xsl:matching-substring>
                <!-- year -->
                <xsl:value-of select="regex-group(1)"/>
                <!-- month (can't add an if,then,else '' statement here without getting an extra space at the end of the result-->
                <xsl:if test="regex-group(2)">
                    <xsl:value-of select="subsequence($months, number(regex-group(2)), 1)"/>
                </xsl:if>
                <!-- day -->
                <xsl:if test="regex-group(3)">
                    <xsl:number value="regex-group(3)" format="1"/>
                </xsl:if>
                <!-- still need to handle time... but if that's there, then I can just use xs:dateTime !!!! -->
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>
    
    
    <xsl:template match="ead:unitdate[@type ne 'bulk'] | ead:unitdate[not(@type)]" priority="2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="not(@normal) or matches(replace(., '/|-', ''), '[\D]')">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="first-date" select="if (contains(@normal, '/')) then replace(substring-before(@normal, '/'), '\D', '') else replace(@normal, '\D', '')"/>
                    <xsl:variable name="second-date" select="replace(substring-after(@normal, '/'), '\D', '')"/>
                    <!-- just adding the next line until i write a date conversion function-->
                    <xsl:value-of select="caas:iso-date-2-display-form($first-date)"/>
                    <xsl:if test="$second-date ne '' and ($first-date ne $second-date)">
                        <xsl:text>&#8211;</xsl:text>
                        <xsl:value-of select="caas:iso-date-2-display-form($second-date)"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="ead:unitdate[@type = 'bulk']" priority="2">
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <!-- need to convert these to human readable form if more granular than just a 4-digit year-->
                <xsl:when test="not(@normal) or matches(replace(., '/|-|bulk', ''), '[\D]')">
                    <xsl:apply-templates/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>Bulk, </xsl:text>
                    <xsl:variable name="first-date" select="if (contains(@normal, '/')) then replace(substring-before(@normal, '/'), '\D', '') else replace(@normal, '\D', '')"/>
                    <xsl:variable name="second-date" select="replace(substring-after(@normal, '/'), '\D', '')"/>
                    <xsl:value-of select="caas:iso-date-2-display-form($first-date)"/>
                    <xsl:if test="$second-date ne '' and ($first-date ne $second-date)">
                        <xsl:text>&#8211;</xsl:text>
                        <xsl:value-of select="caas:iso-date-2-display-form($second-date)"/>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="ead:container/@label">
        <xsl:attribute name="label">
            <xsl:value-of select="replace(translate(., '[]', '()'), 'Mixed Materials', 'mixed_materials', 'i') => lower-case()"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="ead:extent">
        <xsl:copy>
            <!-- update with a map of mapped values... e.g., there will be other spaces that need replacing, but not all -->
            <xsl:value-of select="replace(., 'linear feet', 'linear_feet', 'i') => lower-case()"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>