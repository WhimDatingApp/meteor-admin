@AdminTables = {}

adminTablesDom = '<"box"<"box-header"<"box-toolbar"<"pull-left"<l>><"pull-right"p>>><"box-body"t>>'
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
			columns: _.union columns, adminEditDelButtons
			extraFields: collection.extraFields
			searchFields: collection.searchFields
			dom: adminTablesDom
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