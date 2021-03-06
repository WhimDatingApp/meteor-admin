Template.registerHelper('AdminTables', AdminTables);

UI.registerHelper 'AdminConfig', ->
	AdminConfig if typeof AdminConfig != 'undefined'

UI.registerHelper 'admin_collections', ->
	collections = {}
	if typeof AdminConfig != 'undefined'  and typeof AdminConfig.collections == 'object'
		collections = AdminConfig.collections
	collections.AdminUsers =
		collectionObject: Meteor.users
		icon: 'user'

	_.map collections, (obj, key) ->
# 		obj = _.extend obj, {name:key, routeName: adminCollectionRoute(key)}
		obj = _.extend obj, {name:key}
		obj = _.defaults obj, {label: key,icon:'plus',color:'blue'}

UI.registerHelper 'admin_collection_name', ->
	Session.get 'admin_collection_name'

UI.registerHelper 'admin_current_id', ->
	Session.get 'admin_id'

UI.registerHelper 'admin_current_doc', ->
	Session.get 'admin_doc'

UI.registerHelper 'admin_is_users_collection', ->
	Session.get('admin_collection_name') == 'AdminUsers'

UI.registerHelper 'admin_sidebar_items', ->
	AdminDashboard.sidebarItems

UI.registerHelper 'admin_collection_items', ->
	items = []
	_.each AdminDashboard.collectionItems, (fn) =>
		item = fn @name, '/admin/' + @name
		if item?.title and item?.url
			items.push item
	items

UI.registerHelper 'admin_omit_fields', ->
	if typeof AdminConfig.autoForm != 'undefined' and typeof AdminConfig.autoForm.omitFields == 'object'
		global = AdminConfig.autoForm.omitFields
	if not Session.equals('admin_collection_name','AdminUsers') and typeof AdminConfig != 'undefined' and typeof AdminConfig.collections[Session.get 'admin_collection_name'].omitFields == 'object'
		collection = AdminConfig.collections[Session.get 'admin_collection_name'].omitFields
	if typeof global == 'object' and typeof collection == 'object'
		_.union global, collection
	else if typeof global == 'object'
		global
	else if typeof collection == 'object'
		collection

UI.registerHelper 'AdminSchemas', ->
	AdminDashboard.schemas

UI.registerHelper 'adminGetSkin', ->
	if typeof AdminConfig.dashboard != 'undefined' and typeof AdminConfig.dashboard.skin == 'string'
		AdminConfig.dashboard.skin
	else
		'blue'

UI.registerHelper 'adminIsUserInRole', (_id,role)->
	Roles.userIsInRole _id, role

UI.registerHelper 'adminGetUsers', ->
	Meteor.users

UI.registerHelper 'adminUserSchemaExists', ->
	typeof Meteor.users._c2 == 'object'

UI.registerHelper 'adminCollectionLabel', (collection)->
	AdminDashboard.collectionLabel(collection) if collection?

UI.registerHelper 'adminCollectionCount', (collection)->
	if collection == 'AdminUsers'
		Meteor.users.find().fetch().length
	else
		AdminCollectionsCount.findOne({collection: collection})?.count

UI.registerHelper 'adminTemplate', (collection,mode)->
	# console.log "adminTemplate.this: ", this
	if collection.toLowerCase() != 'adminusers' && typeof AdminConfig.collections[collection].templates != 'undefined'
		tmplConfig = AdminConfig.collections[collection].templates[mode]
		# if tmplConfig.navFilter
			# console.log "adminTemplate.navFilter: true"
			#tmplConfig.filterTable = 
		tmplConfig

UI.registerHelper 'adminGetCollection', (collection)->
	AdminConfig.collections[collection]

UI.registerHelper 'adminWidgets', ->
	if typeof AdminConfig.dashboard != 'undefined' and typeof AdminConfig.dashboard.widgets != 'undefined'
		AdminConfig.dashboard.widgets
		
UI.registerHelper 'adminUserEmail', (user) ->
	if user && user.emails && user.emails[0] && user.emails[0].address
		user.emails[0].address
	else if user && user.services && user.services.facebook && user.services.facebook.email
		user.services.facebook.email
	else if user && user.services && user.services.google && user.services.google.email
		user.services.google.email
