@AdminTables = {}

adminTablesDom = '<"box"<"box-header"<"box-toolbar"<"pull-left"<l>><"pull-right"p>>><"box-body"t><"box-header"<"box-toolbar"<"pull-right"p>>>>'
adminEditDelButtons = [
	{
		data: '_id'
		title: 'Edit'
		createdCell: (node, cellData, rowData) ->
			$(node).html(Blaze.toHTMLWithData Template.adminEditBtn, {_id: cellData}, node)
		width: '40px'
		orderable: false
	}
	{
		data: '_id'
		title: 'Delete'
		createdCell: (node, cellData, rowData) ->
			$(node).html(Blaze.toHTMLWithData Template.adminDeleteBtn, {_id: cellData}, node)
		width: '40px'
		orderable: false
	}
]

AdminTables.AdminUsers = new Tabular.Table
	name: 'AdminUsers'
	collection: Meteor.users
	columns: _.union [
		{
			data: '_id'
			title: 'Admin'
			# TODO: use `tmpl`
			createdCell: (node, cellData, rowData) ->
				$(node).html(Blaze.toHTMLWithData Template.adminUsersIsAdmin, {_id: cellData}, node)
			width: '40px'
		}
		{
			data: 'emails'
			title: 'Email'
			render: (value) ->
				value[0].address
		}
		{
			data: 'emails'
			title: 'Mail'
			# TODO: use `tmpl`
			createdCell: (node, cellData, rowData) ->
				$(node).html(Blaze.toHTMLWithData Template.adminUsersMailBtn, {emails: cellData}, node)
			width: '40px'
		}
		{ data: 'createdAt', title: 'Joined' }
	], adminEditDelButtons
	dom: adminTablesDom

adminTablePubName = (collection) ->
	"admin_tabular_#{collection}"

adminCreateTables = (collections) ->
	_.each AdminConfig?.collections, (collection, name) ->
		columns = _.map collection.tableColumns, (column) ->
			if column.format
				if column.format == "date"
					createdCell = (node, cellData, rowData) ->
						$(node).html(moment(cellData).format("MM/DD/YYYY"))
				else if column.format == "options"
					coll = adminCollectionObject(name)
					# console.log "select table collection: ", coll
					# sch = coll.simpleSchema()
					options = coll.simpleSchema()._schema[column.name]?.autoform?.options
					# console.log "select options: ", coll.simpleSchema()._schema[column.name]?.autoform?.options
					if options
						createdCell = (node, cellData, rowData) ->
							d = cellData
							dtype = typeof d
							for k,v of options
								if(dtype == "number")
									k = parseInt(k)
								if k == d
									if column.template
										$(node).html(Blaze.toHTMLWithData Template[column.template], {value: cellData, formatted: v, doc: rowData, collection: name, field: column.name}, node)
									else
										$(node).html(v)
									break
				# createdCell = (node, cellData, rowData) ->
					# 	$(node).html(moment(cellData).format("MM/DD/YYYY"))
			else if column.template
				createdCell = (node, cellData, rowData) ->
					$(node).html(Blaze.toHTMLWithData Template[column.template], {value: cellData, doc: rowData, collection: name, field: column.name}, node)
			data: column.name
			title: column.label
			createdCell: createdCell
			render: column.render

		if columns.length == 0
			columns = defaultColumns

		# console.log "adminCreateTables children?: ", collection.children and adminTablePubName(name)

		AdminTables[name] = new Tabular.Table
			name: name
			collection: adminCollectionObject(name)
			pub: collection.children and adminTablePubName(name)
			sub: collection.sub
			# columns: _.union columns, adminEditDelButtons
			columns: columns
			extraFields: collection.extraFields
			searchFields: collection.searchFields
			dom: adminTablesDom
			# pageLength: ->
			# 	if Meteor.isClient 
			# 		return Session.get "Tabular.pageLength" 
			# 	else
			# 		5
			# stateSave: true
			# stateSaveCallback: (settings, data) ->
			# 	update = false
			# 	tables = Session.get "tableState"
			# 	if not tables?
			# 		tables = {}
			# 	if not tables?[settings.sTableId]?
			# 		update = true
			# 	else
			# 		table = tables[settings.sTableId]
			# 		if table.length != data.length or table.start != data.start or not _.isEqual(table.order, data.order)
			# 			update = true

			# 	if update?
			# 		console.log "table state updating: ", tables
			# 		tables[settings.sTableId] = data
			# 		Session.set "tableState", tables
			# 		console.log "table state save: ", tables

			# 	return false

			# stateLoadCallback: (settings) ->
			# 	console.log "table state GET"
			# 	# Session.get "tableState"
				# return false

			allow: (userId) ->
				return Roles.userIsInRole(userId, 'admin')

adminPublishTables = (collections) ->
	_.each collections, (collection, name) ->
		if not collection.children then return undefined
		Meteor.publishComposite adminTablePubName(name), (tableName, ids, fields) ->
			check tableName, String
			check ids, Array
			check fields, Match.Optional Object

			@unblock()

			if not Roles.userIsInRole this.userId, ['admin']
				return undefined

			find: ->
				@unblock()
				adminCollectionObject(name).find {_id: {$in: ids}}, {fields: fields}
			children: collection.children

Meteor.startup ->
	adminCreateTables AdminConfig?.collections
	adminPublishTables AdminConfig?.collections if Meteor.isServer