/**
* This module wraps the DPD API
**/
component {

	// Module Properties
    this.modelNamespace			= 'dhl-parcel-uk-cfml';
    this.cfmapping				= 'dhl-parcel-uk-cfml';
    this.parseParentSettings 	= true;

	/**
	 * Configure
	 */
	function configure(){

		// Skip information vars if the box.json file has been removed
		if( fileExists( modulePath & '/box.json' ) ){
			// Read in our box.json file for so we don't duplicate the information above
			var moduleInfo = deserializeJSON( fileRead( modulePath & '/box.json' ) );

			this.title 				= moduleInfo.name;
			this.author 			= moduleInfo.author;
			this.webURL 			= moduleInfo.repository.URL;
			this.description 		= moduleInfo.shortDescription;
			this.version			= moduleInfo.version;

		}

		// Settings
		settings = {
				'username' : ''
			,	'password' : ''
			,	'environment' : 'sandbox'
			,	'sftpUsername' : ''
			,	'sftpKeyfile' : ''
		};
	}

	function onLoad(){
		binder.map( "tracking@dhl-parcel-uk-cfml" )
			.to( "#moduleMapping#.models.tracking" )
			.asSingleton()
			.initWith(
					username 	= settings.username
				,	password 	= settings.password
				,	environment = settings.environment
			);

		binder.map( "events@dhl-parcel-uk-cfml" )
			.to( "#moduleMapping#.models.events" )
			.asSingleton()
			.initWith(
					sftpUsername 	= settings.sftpUsername
				,	sftpKeyfile 	= settings.sftpKeyfile
			);
	}

}