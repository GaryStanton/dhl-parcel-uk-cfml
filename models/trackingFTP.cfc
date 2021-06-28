/**
 * Name: DHL Parcel UK Tracking Event FTP Manager
 * Author: Gary Stanton (@SimianE)
 * Description: Handles the use of DHL Parcel UK 'tracking data' files stored on the DHL SFTP server. 
 * You will need to contact the DHL Customer Integrations team to have them set up access for your account.
 * A private RSA2048 keyfile must be used in order to connect to the DHL server, and you will need to provide the public sftpKeyfile to DHL.
 */
component singleton accessors="true" {

	property name="sftpServer"      type="string" default="80.193.248.145";
	property name="sftpUsername"    type="string";
	property name="sftpKeyfile"     type="string";
	property name="filePath" 		type="string" default="#GetDirectoryFromPath(GetCurrentTemplatePath())#../store/";
	property name="connectionName"  type="string" default="DHLConnection_#CreateUUID()#";
	property name="connectionOpen"  type="boolean" default="false";
	property name="podCols" 		type="string" default="Data_Type,Data_Version,Filler,Customer_Reference,Alternative_Reference,Delivery_Date,Delivery_Time,Delivery_Signature,Delivery_Failure_Code,Delivery_Failure_Description,Service_Code,Service_Description,Shipment_Number,Delivery_Type_Code,Delivery_Type_Description";
	property name="podColWidths"  	type="string" default="10,10,14,20,20,8,6,30,4,30,4,30,40,4,40";
	property name="scanCols" 		type="string" default="Data_Type,Data_Version,Filler,Customer_Reference,Alternative_Reference,Parcel_Number,Scan_Date,Scan_Time,Location_Code,Location,Scan_Type_Code,Scan_Type,Shipment_Number";
	property name="scanColWidths"  	type="string" default="10,10,14,20,20,4,8,6,4,30,4,25,40";


	/**
	 * Constructor
	 * 
	 * @sftpServer 		The location of the DHL SFTP server. Defaults to 80.193.248.145
	 * @sftpUsername    Your SFTP sftpUsername, provided by DHL UK
	 * @sftpKeyfile     The location of your private key file used for authentication. Should be a .ppk file hosted on the server.
	 * @filePath    	The filesystem location to use when processing files. Defaults to /store.
	 */
	public trackingFTP function init(
			string sftpServer
		,   required string sftpUsername
		,   required string sftpKeyfile
		,   string filePath
	){  
		if (structKeyExists(Arguments, 'sftpServer')) {
			setSftpServer(Arguments.sftpServer);
		}

		setSftpUsername(Arguments.sftpUsername);

		// Check sftpKeyfile exists
		if (!fileExists(Arguments.sftpKeyfile)) {
			throw('Keyfile does not exist on the server at: #Arguments.sftpKeyFile#');
		}
		else {
			setSftpKeyfile(Arguments.sftpKeyfile);
		}

		// Create file store
		if (!directoryExists(getFilePath())) {
			DirectoryCreate(getFilePath());
		}

		return this;
	}


	private function openConnection() {
		// Open FTP connection
		cfftp(
				action = "open"
			,   connection = getConnectionName()
			,   username = getSftpUsername()
			,   server = getSftpServer()
			,   key = getsftpKeyFile()
			,   secure = true
			,   stoponerror = true
		);

		setConnectionOpen(cfftp.succeeded);

		return cfftp;
	}


	private function closeConnection() {
		cfftp(
			action = "close"
		,   connection = getConnectionName()
		,   stoponerror = true
		);

		setConnectionOpen(cfftp.succeeded);

		return cfftp;
	}


	private function getFileListCommand() {
		cfftp(
			action = "listdir"
		,   connection = getConnectionName()
		,   directory="outgoing/"
		,   name = "Local.DHLFiles"
		,   stoponerror = true
		);

		// Sort files
		Local.DHLFiles = queryExecute("
			SELECT * FROM Local.DHLFiles
			WHERE isdirectory = 'false'
			ORDER BY LastModified ASC
		", {} , {dbtype="query"});

		return Local.DHLFiles;
	}


	private function retrieveFileCommand(
			required string fileName
		,	boolean removeFromServer = false
	) {

		cfftp(
			action = "getFile"
		,   connection = getConnectionName()
		,   remoteFile = 'outgoing/' & Arguments.fileName
		,	localFile = getFilePath() & Arguments.fileName
		,   stoponerror = true
		,	failIfExists = false
		);

		if (Arguments.removeFromServer) {
			deleteFileCommand(Arguments.fileName);
		}

		return cfftp;
	}


	private function deleteFileCommand(
			required string fileName
	) {
		cfftp(
			action = "remove"
		,   connection = getConnectionName()
		,   item = 'outgoing/' & Arguments.fileName
		,   stoponerror = true
		);

		return cfftp;
	}

	/**
	 * Returns a query object of files on the SFTP server
	 */
	public function getFileList() {
		openConnection();
		Local.fileList = getFileListCommand();
		closeConnection();

		return Local.fileList;
	}


	/**
	 * Delete a file from the FTP server
	 */
	public function deleteFile(
		required string FileName
	) {
		openConnection();
		Local.result = deleteFileCommand(Arguments.FileName);
		closeConnection();

		return Local.result;
	}



	/**
	 * Filter a file list query object by name and/or date
	 *
	 * @fileNames 			Optionally provide a specific filename or list of filenames
	 * @dateRange			Optionally provide a comma separated (inclusive) date range (yyyy-mm-dd,yyyy-mm-dd) to filter files. Where a single date is passed, all files from that date will be included.
	 *
	 * @return     			Query object containing tracking event data
	 */
	public function filterFileList(
			query fileList
		,	string fileNames
		,	string dateRange
		,	numeric maxFiles = 0
	) {
		
		var fileList = StructKeyExists(Arguments, 'fileList') ? Arguments.fileList : getFileList();

		// If we're looking at a local file list, we'll have 'dateLastModified' instead of 'lastModified'
		Local.modifiedColumnName = StructKeyExists(fileList, 'dateLastModified') ? 'dateLastModified' : 'lastModified';

		// Filter query
		Local.SQL = "
			SELECT * 
			FROM fileList
			WHERE 1 = 1
		";

		Local.Params = {};

		if (structKeyExists(Arguments, 'fileNames')) {
			Local.SQL &= "
				AND 	name IN (:filenames)
			";

			Local.Params.filenames = {value = Arguments.fileNames, list = true};
		}

		if (structKeyExists(Arguments, 'dateRange')) {
			Local.SQL &= "
				AND 	#Local.modifiedColumnName# >= :DateFrom
			";

			Local.Params.DateFrom = {value = DateFormat(ListFirst(Arguments.dateRange), 'yyyy-mm-dd')};
		}

		if (structKeyExists(Arguments, 'dateRange') && listLen(Arguments.DateRange) == 2) {
			Local.SQL &= "
				AND 	#Local.modifiedColumnName# < :DateTo
			";

			Local.Params.DateTo = {value = DateAdd('d', 1, DateFormat(ListLast(Arguments.dateRange), 'yyyy-mm-dd'))};
		}

		Local.fileList = queryExecute(Local.SQL, Local.params , {dbtype="query", maxrows=Arguments.MaxFiles > 0 ? Arguments.MaxFiles : 9999999});

		return Local.fileList;
	}



	/**
	 * Retrieve files from the DHL UK SFTP server and return a query object containing their data
	 *
	 * @fileNames 			Optionally provide a specific filename or list of filenames to process
	 * @dateRange			Optionally provide a comma separated (inclusive) date range (yyyy-mm-dd,yyyy-mm-dd) to filter files to process. Where a single date is passed, all files from that date will be included.
	 * @removeFromServer  	When true, processed files are removed from the remote server
	 *
	 * @return     			Query object containing tracking event data
	 */
	public function processRemoteFiles(
			string fileNames
		,	string dateRange
		,	boolean removeFromServer = false
		,	numeric maxFiles = 0
	) {

		openConnection();

		Local.fileList = filterFileList(
			fileList 			= getFileListCommand()
		,	ArgumentCollection 	= Arguments
		);		

		// Array to store local filenames
		Local.localFiles = [];

		// Loop through the files and process
		for (Local.thisFile in Local.fileList) {
			Local.retrieveFile = retrieveFileCommand(Local.thisFile.name, Arguments.removeFromServer);

			if (Local.retrieveFile.succeeded) {
				Local.localFiles.append(Local.thisFile.name);
			}
		}

		closeConnection();

		// Process local files
		if (Local.localFiles.len()) {
			Local.queryObject = processLocalFiles(arrayToList(Local.LocalFiles))

			return Local.queryObject;
		}
		else {
			return 'No matching files found.';
		}
	}


	public function processLocalFiles(
			string fileNames
		,	string dateRange
		,	numeric maxFiles = 0
	) {
		// Get file query object
		Local.fileList = filterFileList(
			fileList 			= directoryList(getFilePath(), false, 'query')
		,	ArgumentCollection 	= Arguments
		);

		// Create queries
		Local.queries.pods = queryNew(getPodCols());
		Local.queries.pods.addColumn('Filename');

		Local.queries.scans = queryNew(getScanCols());
		Local.queries.scans.addColumn('Filename');

		for (Local.thisFile in Local.fileList) {
			// Read data
			Local.rawData = fileRead(getFilePath() & Local.thisFile.name);
			// Strip header and footer
			Local.data = Replace(Local.rawData, ListFirst(Local.rawData, chr(10)), '');
			Local.data = Replace(Local.rawData, ListLast(Local.rawData, chr(10)), '')

			// Process data
			if (Left(Local.thisFile.name, 12) == 'customerpods') {
				processData(Local.thisFile.name, Local.data, getPodCols(), getPodColWidths(), Local.queries.pods);
			}
			else if (Left(Local.thisFile.name, 13) == 'customerscans') {
				processData(Local.thisFile.name, Local.data, getScanCols(), getScanColWidths(), Local.queries.scans);
			}
		}

		return Local.queries;
	}


	private function processData(filename, data, cols, colWidths, queryObject) {
		Local.conversion = new conversion();
		Local.data = Local.conversion.fixedWidthToQuery(Arguments.cols, Arguments.colWidths, Arguments.data);

		for (Local.thisRow in Local.data) {
			Arguments.queryObject.addRow(Local.thisRow);
			Arguments.queryObject.fileName[Arguments.queryObject.RecordCount] = Arguments.filename;
		}

		return Arguments.queryObject
	}
}