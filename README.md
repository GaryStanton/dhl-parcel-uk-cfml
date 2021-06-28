# DHL Parcel UK CFML

DHL Parcel UK CFML provides a wrapper for the DHL Parcel UK Web Services.
At present, the module only includes access to the DHL sftp service for scans and proof of delivery.
Further updates may include access to other DHL Parcel UK APIs.

## Installation
```js
box install dhl-parcel-uk-cfml
```

## Examples
Check out the `/examples` folder for an example implementation.

## Usage
The DHL Parcel UK CFML wrapper currently consists of a single models, to manage connection to the DHL SFTP server to download and process event files.
The wrapper may be used standalone, or as a ColdBox module.


### Standalone
```cfc
	DHLUKTracking = new models.trackingFTP(
			sftpUsername 	= 'XXXXXXXX'
		,	sftpKeyFile 	= 'path/to/keyfile.ppk'
	);

```

### ColdBox
```cfc
DHLUKTracking 	= getInstance("trackingFTP@DHLParcelUKCFML");
```
alternatively inject it directly into your handler
```cfc
property name="DHLUKTracking" inject="trackingFTP@DHLParcelUKCFML";
```

When using with ColdBox, you'll want to insert your API authentication details into your module settings:

```cfc
DHLUKCFML = {
		sftpUsername 	= getSystemSetting("DHLUK_SFTPUSERNAME", "")
	,	sftpKeyfile 	= getSystemSetting("DHLUK_SFTPKEYFILE_PATH", "")
}
```

### Retrieve tracking event data
Tracking event files are uploaded to the DHL SFTP server every 20 minutes or so. The events component can be used to list, download and process these files.  

```cfc
fileList = DHLUKEvents.getFileList();
```

```cfc
fileContents = DHLEvents.processRemoteFiles(
		dateRange 			= '2021-01-01,2021-01-31'
	,	removeFromServer 	= false
);
```


## Author
Written by Gary Stanton.  
https://garystanton.co.uk
