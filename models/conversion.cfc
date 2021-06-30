<cfcomponent>
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

</cfcomponent>