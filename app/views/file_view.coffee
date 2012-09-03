Files = require 'models/files'

module.exports = class FileView extends Backbone.View
  template: require './templates/file'
  tagName: "div"
  className: "file-container"
  directory: null
  allowClose: no

  # Since we're embedding views into views,
  # we need to make links unique
  events: ->
    events = {}
    # events["click span.edit"] = "edit"
    events["contextmenu"] = "contextualMenu"
    events["click a#cid_#{@model.cid}"] = "open"

    # Renaming files
    # events["blur input"] = "rename"
    events["keydown input"] = "rename"

    events

  initialize: (attr, options) ->
    if options
      @allowClose = options.allowClose if options.allowClose

    @model.on 'all', @render, this

  render: ->
    @$el.html @template(file: @model, directory: @directory, allowClose: @allowClose)
    @$el.attr('data-cid', @model.cid) # For the sortability

    # Popover
    @$("[rel=popover]").popover toggle:"manual"

    if @directory
      @directory.each (file) =>
        file_view = new FileView(model: file)
        @$('.subdirectory').first().append file_view.render().el

    if @model.get 'isRenaming'
      @$('input').focus()

    this

  markAsActive: -> @$el.addClass('active')
  unmarkAsActive: -> @$el.removeClass('active')

  # Should only call itself when the view is being shown
  # on the "Open Files" list
  removeFromList: ->
    return unless @allowClose
    
    @remove()

    Backbone.Mediator.pub "filebrowser:close_file", @model

  contextualMenu: (e) ->
    e.preventDefault() # Prevent the real context menu from appearing
    e.stopPropagation() # Otherwise the right click selects the text, ugly

    app.contextualFileMenu.show @model, {x: e.pageX, y: e.pageY}

  rename: (e) ->
    if e.keyCode is 13 # Return
      console.log @$('input').val()
      @model.rename @$('input').val()
      @$('input').attr('disabled', 'disabled')

  open: (e) ->
    e?.preventDefault()

    return if @model.get 'isRenaming'

    if @model.isDirectory()
      # Is it open?
      if @directory
        # Close it
        app.logger.log "Closing directory #{@model.get('name')}"
        @directory.off 'all'
        @directory = null
        @render()
      else
        app.logger.log "Opening directory #{@model.get('name')}"
        @directory = new Files null, project: @model.project, path: @model.fullPath()
        @directory.on 'reset', @render, this
        @directory.fetch()
    else
      app.logger.log "Opening file #{@model.get('name')}"
      app.code_editor.setFile @model
      @model.fetchContent()

      # This adds the file to the open file list
      Backbone.Mediator.pub "filebrowser:open_file", @model

