<cfcomponent>

<!--- 
This function converts XML variables into Coldfusion Structures. It also
returns the attributes for each XML node.
https://www.anujgakhar.com/2007/11/05/coldfusion-xml-to-struct/
--->
	<cffunction name="ConvertXmlToStruct" access="public" returntype="struct" output="false"
					hint="Parse raw XML response body into ColdFusion structs and arrays and return it.">
		<cfargument name="xmlNode" type="string" required="true" />
		<cfargument name="str" type="struct" required="true" />
		<!---Setup local variables for recurse: --->
		<cfset var i = 0 />
		<cfset var axml = arguments.xmlNode />
		<cfset var astr = arguments.str />
		<cfset var n = "" />
		<cfset var tmpContainer = "" />
		
		<cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
		<cfset axml = axml[1] />
		<!--- For each children of context node: --->
		<cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
			<!--- Read XML node name without namespace: --->
			<cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
			<!--- If key with that name exists within output struct ... --->
			<cfif structKeyExists(astr, n)>
				<!--- ... and is not an array... --->
				<cfif not isArray(astr[n])>
					<!--- ... get this item into temp variable, ... --->
					<cfset tmpContainer = astr[n] />
					<!--- ... setup array for this item beacuse we have multiple items with same name, ... --->
					<cfset astr[n] = arrayNew(1) />
					<!--- ... and reassing temp item as a first element of new array: --->
					<cfset astr[n][1] = tmpContainer />
				<cfelse>
					<!--- Item is already an array: --->
					
				</cfif>
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
						<!--- recurse call: get complex item: --->
						<cfset astr[n][arrayLen(astr[n])+1] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
					<cfelse>
						<!--- else: assign node value as last element of array: --->
						<cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
				</cfif>
			<cfelse>
				<!---
					This is not a struct. This may be first tag with some name.
					This may also be one and only tag with this name.
				--->
				<!---
						If context child node has child nodes (which means it will be complex type): --->
				<cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
					<!--- recurse call: get complex item: --->
					<cfset astr[n] = ConvertXmlToStruct(axml.XmlChildren[i], structNew()) />
				<cfelse>
					<!--- else: assign node value as last element of array: --->
					<!--- if there are any attributes on this element--->
					<cfif IsStruct(aXml.XmlChildren[i].XmlAttributes) AND StructCount(aXml.XmlChildren[i].XmlAttributes) GT 0>
						<!--- assign the text --->
						<cfset astr[n] = axml.XmlChildren[i].XmlText />
							<!--- check if there are no attributes with xmlns: , we dont want namespaces to be in the response--->
						 <cfset attrib_list = StructKeylist(axml.XmlChildren[i].XmlAttributes) />
						 <cfloop from="1" to="#listLen(attrib_list)#" index="attrib">
							 <cfif ListgetAt(attrib_list,attrib) CONTAINS "xmlns:">
								 <!--- remove any namespace attributes--->
								<cfset Structdelete(axml.XmlChildren[i].XmlAttributes, listgetAt(attrib_list,attrib))>
							 </cfif>
						 </cfloop>
						 <!--- if there are any atributes left, append them to the response--->
						 <cfif StructCount(axml.XmlChildren[i].XmlAttributes) GT 0>
							 <cfset astr[n&'_attributes'] = axml.XmlChildren[i].XmlAttributes />
						</cfif>
					<cfelse>
						 <cfset astr[n] = axml.XmlChildren[i].XmlText />
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- return struct: --->
		<cfreturn astr />
	</cffunction>


<!---
 Converts fixed width string to a ColdFusion query.
 Modified by Raymond Camden for missing var, and support newlines better.
 
 @param columnNames     A list of column names. (Required)
 @param widths      	A corresponding list of widths. (Required)
 @param data      		The data to parse. (Required)
 @param customRegex     A regular expression to be used to parse the line. (Optional)
 @return 				Returns a query. 
 @author Umer Farooq (umer@octadyne.com) 
 @version 1, December 20, 2007 
--->
<cffunction name="fixedWidthToQuery" hint="I turn fixed width data to query">
    <cfargument name="columnNames" required="Yes" type="string">
    <cfargument name="widths" required="Yes" type="string">
    <cfargument name="data" required="Yes" type="string">
    <cfargument name="customRegex" required="No" type="string">
    <cfset var tempQuery = QueryNew(arguments.columnNames)>
    <cfset var regEx = "">
    <cfset var findResults = "">
    <cfset var i = "">
    <cfset var line = "">
    <cfset var x = "">
    
    <!--- build our regex --->
    <cfif NOT isDefined("arguments.customRegEx")>
        <cfloop list="#arguments.widths#" index="i">
            <cfset regex = regex & "(.{" & i & "})">
        </cfloop>
    <cfelse>
        <cfset regEx = arguments.customRegex>
    </cfif>
    
    <!--- fix newlines for different os --->
    <cfset arguments.data = replace(arguments.data,chr(10),chr(13),"all")>
    <cfset arguments.data = replace(arguments.data,chr(13)&chr(13),chr(13),"all")>
    
    <!--- loop the data --->
    <cfloop list="#arguments.data#" delimiters="#chr(13)#" index="line">
        <!--- run our regex --->
        <cfset findResults = refind(regEx, line, 1, true)>
        <!--- find our that our match records equals number of columns plus one. --->
        <cfif arrayLen(findResults.pos) eq listLen(arguments.columnNames)+1>
            <cfset QueryAddRow(tempQuery)>
            <!--- loop the find resuls array from postion 2... 
                  and get the column name x-1 as our regex results are number of columsn plus 1
                  and load that data into the query  --->
            <cfloop from="2" to="#arrayLen(findResults.pos)#" index="x">
                <cfset QuerySetCell(tempQuery, listGetAt(arguments.columnNames, x-1), trim(mid(line, findResults.pos[x], findResults.len[x])))> 
            </cfloop>
        </cfif>
    </cfloop>
    <cfreturn tempQuery>
</cffunction>



	<cfscript>
		/**
		 * Rename query columns. 
		 * Function by Julian Halliwell: https://blog.simplicityweb.co.uk/125/renaming-cfml-query-columns
		 **/
		query function queryRenameColumns( required query query, required array columnNames, required array newColumnNames ){
			// throw an error if the number of old and new names don't match
			if( arguments.columnNames.Len() != arguments.newColumnNames.Len() )
				Throw( message: "Column name mismatch", detail: "The number of column names to change doesn't match the number of new names" );
			// convert the query to JSON
			var queryJson = SerializeJSON( arguments.query );
			// get the current set of columns as an array so we can work on it
			var columns = GetMetaData( arguments.query ).Map( function( item ){
				return item.name;
			});
			// find and rename the specified columns
			var newColumns = columns.Map( function( item ){
				var foundPosition = columnNames.FindNoCase( item );
				return foundPosition? newColumnNames[ foundPosition ]: item;
			});
			// convert the original and changed column arrays to text
			var columnsJson = SerializeJSON( columns );
			var newColumnsJson = SerializeJSON( newColumns );
			// do a simple string replace (no RegExp required)
			var queryJsonColumnRenamed = queryJson.Replace( 'COLUMNS":' & columnsJson, 'COLUMNS":' & newColumnsJson );
			// convert the JSON back to a query object
			return DeserializeJSON( queryJsonColumnRenamed, false );
		}
	</cfscript>

</cfcomponent>